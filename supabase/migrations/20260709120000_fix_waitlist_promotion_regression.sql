-- Repara el flujo de lista de espera.
--
-- Causa raiz: el hotfix 20260701130000 (sacar reservations.institution_id) hizo
-- `create or replace` de promote_waitlist_on_cancellation() partiendo de una
-- version vieja de la funcion, y en el camino perdio tres cosas:
--
--   1. el `exit` al final del loop. La capacidad se chequea UNA sola vez, antes
--      de iterar; sin `exit`, una cancelacion (que libera UN lugar) promovia a
--      TODOS los que estaban esperando -> clase sobrevendida.
--   2. el `exception when others` que envolvia el cuerpo. Sin el, cualquier
--      error dentro del trigger hace rollback del UPDATE original: el alumno
--      que quiso cancelar no puede cancelar.
--   3. el `net.http_post` a la Edge Function send-waitlist-email -> el mail de
--      "conseguiste un lugar" no se manda nunca.
--
-- El POST no lleva Authorization: send-waitlist-email esta desplegada con
-- verify_jwt=false, asi que el gateway la rutea igual y la funcion se autentica
-- con el shared secret (x-webhook-secret). Verificado contra prod.
--
-- Tambien vuelve a poner type='waitlist' en la notificacion: la UI mapea ese
-- valor a un icono propio (lib/screens/notifications_screen.dart), y el hotfix
-- lo habia dejado en 'booking', que cae al icono generico.

create extension if not exists pg_net;

create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

-- Placeholders: completar con UPDATE en cada entorno.
insert into private.email_config (key, value) values
  ('waitlist_fn_url', 'https://CAMBIAR.functions.supabase.co/functions/v1/send-waitlist-email'),
  ('waitlist_webhook_secret', 'CAMBIAR')
on conflict (key) do nothing;

create or replace function public.promote_waitlist_on_cancellation()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_tz constant text := 'America/Argentina/Buenos_Aires';
  v_today       date;
  v_session     class_sessions%rowtype;
  v_class_name  text;
  v_confirmed   int;
  v_month_start date;
  v_waiter      record;
  v_limit       int;
  v_used        int;
  v_email       text;
  v_name        text;
  v_fn_url      text;
  v_secret      text;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then
    return new;
  end if;

  -- Fecha local Argentina, no current_date (UTC): entre las 21:00 y las 00:00
  -- hora local, current_date ya es "manana" y las clases de hoy quedaban fuera.
  v_today := (now() at time zone v_tz)::date;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < v_today then
    return new;
  end if;

  select count(*) into v_confirmed
  from reservations
  where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then
    return new;
  end if;

  v_class_name  := coalesce(v_session.name, 'la clase');
  v_month_start := date_trunc('month', v_session.date)::date;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    -- plan activo que cubra la fecha de la clase
    select p.max_reservations_per_month into v_limit
    from subscriptions s
    join plans p on p.id = s.plan_id
    where s.user_id = v_waiter.user_id and s.status = 'active'
      and s.start_date <= v_session.date and s.end_date >= v_session.date
    order by s.end_date desc
    limit 1;
    if not found then continue; end if;

    if v_limit is not null then
      select count(*) into v_used
      from reservations r
      join class_sessions cs on cs.id = r.session_id
      where r.user_id = v_waiter.user_id and r.status = 'confirmed'
        and cs.date >= v_month_start
        and cs.date <  v_month_start + interval '1 month';
      if v_used >= v_limit then continue; end if;
    end if;

    -- ya tenia reserva confirmada en esta sesion: limpiar la fila huerfana
    -- y seguir buscando al proximo elegible
    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- reservations NO tiene institution_id en prod: no incluir esa columna.
    -- El on conflict revive la fila cancelada si existia (UNIQUE user_id, session_id).
    insert into reservations (user_id, session_id, status)
    values (v_waiter.user_id, new.session_id, 'confirmed')
    on conflict (user_id, session_id) do update
      set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (
      v_waiter.user_id,
      '¡Conseguiste un lugar!',
      'Se liberó un lugar en ' || v_class_name || ' del '
        || to_char(v_session.date, 'DD/MM')
        || ' y ya tenés la reserva confirmada.',
      'waitlist'
    );

    -- Mail best-effort: si falla, la promocion ya quedo hecha igual.
    begin
      select email, full_name into v_email, v_name
      from profiles where id = v_waiter.user_id;

      select value into v_fn_url from private.email_config where key = 'waitlist_fn_url';
      select value into v_secret from private.email_config where key = 'waitlist_webhook_secret';

      if coalesce(v_email, '') <> ''
         and v_fn_url is not null
         and v_fn_url not like 'https://CAMBIAR%'
      then
        perform net.http_post(
          url     := v_fn_url,
          headers := jsonb_build_object(
            'Content-Type',     'application/json',
            'x-webhook-secret', coalesce(v_secret, '')
          ),
          body    := jsonb_build_object(
            'email',      v_email,
            'name',       coalesce(v_name, ''),
            'class_name', v_class_name,
            'date',       to_char(v_session.date, 'DD/MM/YYYY'),
            'time',       to_char(v_session.start_time, 'HH24:MI')
          )
        );
      end if;
    exception when others then
      raise warning 'send-waitlist-email no enviado: %', sqlerrm;
    end;

    -- Una cancelacion libera UN lugar: promover a uno solo y cortar.
    exit;
  end loop;

  return new;
exception when others then
  -- la promocion nunca debe impedir la cancelacion original
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$fn$;

-- El trigger trg_promote_waitlist ya existe; solo cambia la funcion.
