-- ============================================================================
-- APLICAR A MANO EN PRODUCCION (SQL Editor del proyecto Kali Studio).
--
-- Por que a mano y no `db push`: el historial de migraciones esta divergente
-- (prod tiene migraciones que no estan en el repo, y al reves). Este script es
-- idempotente y autocontenido: deja el estado final correcto sin importar que
-- haya aplicado prod, y NO toca la tabla de historial de migraciones.
--
-- Ya hecho por CLI (no incluido aca): secrets de la funcion y deploy de
-- send-waitlist-email. Este script cubre la parte de base de datos + la config
-- real (URL + webhook secret), sin placeholders.
-- ============================================================================

-- ===== 0. Tabla notifications (por si no existe en prod) =====
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  body       text not null,
  type       text not null default 'general',
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select to authenticated using (user_id = auth.uid());

drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, update on public.notifications to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then
  null;
end $$;

-- ===== 1. pg_net + config privada CON LOS VALORES REALES =====
create extension if not exists pg_net;

create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

-- OJO: el webhook secret NO se versiona. Reemplazar el placeholder de abajo por
-- el MISMO valor que el secret WAITLIST_WEBHOOK_SECRET de la Edge Function antes
-- de correr este script. (El valor real ya esta aplicado en produccion.)
insert into private.email_config (key, value) values
  ('waitlist_fn_url', 'https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/send-waitlist-email'),
  ('waitlist_webhook_secret', '<PEGAR_WAITLIST_WEBHOOK_SECRET>')
on conflict (key) do update set value = excluded.value;

-- ===== 2. Funcion de promocion (version con envio de mail) =====
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

    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

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
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$$;

-- ===== 3. Trigger (recrear para asegurar que apunta a la funcion correcta) =====
drop trigger if exists trg_promote_from_waitlist on public.reservations;
drop trigger if exists trg_promote_waitlist on public.reservations;
create trigger trg_promote_waitlist
  after update of status on public.reservations
  for each row
  when (new.status = 'cancelled' and old.status <> 'cancelled')
  execute function public.promote_waitlist_on_cancellation();

-- ===== 4. Verificacion rapida =====
-- select * from private.email_config;
-- select tgname from pg_trigger where tgrelid = 'public.reservations'::regclass and not tgisinternal;
