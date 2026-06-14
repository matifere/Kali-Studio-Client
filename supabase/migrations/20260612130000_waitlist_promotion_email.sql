-- Manda un mail cuando la lista de espera promueve a alguien a una reserva.
--
-- La promocion ocurre en promote_waitlist_on_cancellation() (trigger sobre
-- reservations). Ya creaba la notificacion in-app; ahora ademas dispara un mail
-- via la Edge Function send-waitlist-email, llamada con pg_net (async, no bloquea
-- la cancelacion). Si el mail falla, la promocion ya quedo hecha igual.
--
-- Requisitos previos (una sola vez, por entorno):
--   1. Deploy de la funcion:  supabase functions deploy send-waitlist-email --no-verify-jwt
--   2. Secrets de la funcion:  SENDGRID_API_KEY, EMAIL_FROM=Servicios@argity.com,
--                              EMAIL_FROM_NAME=Argity, WAITLIST_WEBHOOK_SECRET=<secreto>
--   3. Cargar la config de abajo (private.email_config) con la URL de la funcion
--      en ESTE entorno y el MISMO WAITLIST_WEBHOOK_SECRET.

-- ===== pg_net para hacer el POST HTTP desde el trigger =====
-- Expone net.http_post(); en Supabase suele venir pre-cargada. Idempotente.
create extension if not exists pg_net;

-- ===== Config privada (no expuesta por la API: schema fuera de public) =====
create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

-- Placeholders: completar con UPDATE en cada entorno (ver al final del archivo).
insert into private.email_config (key, value) values
  ('waitlist_fn_url', 'https://CAMBIAR.functions.supabase.co/functions/v1/send-waitlist-email'),
  ('waitlist_webhook_secret', 'CAMBIAR')
on conflict (key) do nothing;

-- ===== Trigger de promocion: misma logica + envio de mail =====
create or replace function public.promote_waitlist_on_cancellation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session    class_sessions%rowtype;
  v_class_name text;
  v_confirmed  int;
  v_week_start date;
  v_week_end   date;
  v_waiter     record;
  v_limit      int;
  v_used       int;
  v_email      text;
  v_name       text;
  v_fn_url     text;
  v_secret     text;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then
    return new;
  end if;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < current_date then
    return new;
  end if;

  select count(*) into v_confirmed
  from reservations where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then
    return new;
  end if;

  select coalesce(v_session.name, st.name, 'la clase') into v_class_name
  from (select 1) as one
  left join schedule_templates st on st.id = v_session.template_id;

  v_week_start := date_trunc('week', v_session.date)::date;
  v_week_end   := v_week_start + 6;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    -- plan activo que cubra la fecha de la clase
    select p.max_reservations_per_week into v_limit
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
        and cs.date between v_week_start and v_week_end;
      if v_used >= v_limit then continue; end if;
    end if;

    -- ya tiene reserva confirmada en esta sesión: limpiar la fila huérfana y seguir
    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- revive la fila cancelada si existía (UNIQUE user_id, session_id)
    insert into reservations (user_id, session_id, status, institution_id)
    values (v_waiter.user_id, new.session_id, 'confirmed', v_session.institution_id)
    on conflict (user_id, session_id) do update
      set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (
      v_waiter.user_id,
      '¡Conseguiste un lugar!',
      'Se liberó un lugar en ' || v_class_name || ' del '
        || to_char(v_session.date, 'DD/MM')
        || '. Ya estás inscripto automáticamente.',
      'waitlist'
    );

    -- ===== Mail (best-effort: nunca debe romper la promocion) =====
    begin
      select email, full_name into v_email, v_name
      from profiles where id = v_waiter.user_id;

      select value into v_fn_url  from private.email_config where key = 'waitlist_fn_url';
      select value into v_secret  from private.email_config where key = 'waitlist_webhook_secret';

      if v_email is not null and v_email <> ''
         and v_fn_url is not null and v_fn_url not like 'https://CAMBIAR%' then
        perform net.http_post(
          url     := v_fn_url,
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
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

    exit;
  end loop;

  return new;
exception when others then
  -- la promoción nunca debe impedir la cancelación original
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$$;

-- El trigger trg_promote_waitlist ya existe (migracion anterior); solo cambio la
-- funcion, asi que no hace falta recrearlo.
