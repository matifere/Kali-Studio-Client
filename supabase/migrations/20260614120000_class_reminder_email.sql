-- Recordatorio por mail ~1 hora antes de cada clase.
--
-- A diferencia de la promocion de lista de espera (que es un trigger sobre un
-- evento), el recordatorio no tiene evento que lo dispare a esa hora: necesita un
-- JOB PROGRAMADO. pg_cron corre send_class_reminders() cada 10 min; la funcion
-- busca reservas confirmadas cuya clase arranca en la proxima hora y todavia no
-- fueron avisadas, manda el mail via la Edge Function send-class-reminder
-- (pg_net, async) y marca reservations.reminder_sent_at para no duplicar.
--
-- Zona horaria: las clases se guardan como date + start_time en hora local de
-- Argentina, asi que se convierte con `at time zone 'America/Argentina/Buenos_Aires'`
-- antes de comparar con now() (UTC).
--
-- Requisitos previos (una sola vez, por entorno):
--   1. Deploy de la funcion:  supabase functions deploy send-class-reminder --no-verify-jwt
--   2. Secrets de la funcion:  SENDGRID_API_KEY, EMAIL_FROM, EMAIL_FROM_NAME,
--                              WAITLIST_WEBHOOK_SECRET  (reusa el mismo secreto del waitlist)
--   3. Cargar private.email_config.reminder_fn_url con la URL de la funcion en ESTE entorno.

-- ===== Extensiones =====
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- ===== Marca de "ya avise" en la reserva =====
alter table public.reservations
  add column if not exists reminder_sent_at timestamptz;

-- ===== Config: URL de la funcion (el secreto se reusa del waitlist) =====
create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

-- Placeholder: completar con UPDATE en cada entorno.
insert into private.email_config (key, value) values
  ('reminder_fn_url', 'https://CAMBIAR.functions.supabase.co/functions/v1/send-class-reminder')
on conflict (key) do nothing;

-- ===== Job: manda recordatorios de clases que arrancan en la proxima hora =====
create or replace function public.send_class_reminders()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz       constant text := 'America/Argentina/Buenos_Aires';
  v_fn_url   text;
  v_secret   text;
  v_r        record;
begin
  select value into v_fn_url from private.email_config where key = 'reminder_fn_url';
  select value into v_secret from private.email_config where key = 'waitlist_webhook_secret';

  if v_fn_url is null or v_fn_url like 'https://CAMBIAR%' then
    return; -- sin URL configurada no hay nada que hacer
  end if;

  for v_r in
    select r.id,
           p.email                              as email,
           p.full_name                          as name,
           coalesce(cs.name, st.name, 'tu clase') as class_name,
           cs.date                              as date,
           cs.start_time                        as start_time
    from reservations r
    join class_sessions cs on cs.id = r.session_id
    left join schedule_templates st on st.id = cs.template_id
    join profiles p on p.id = r.user_id
    where r.status = 'confirmed'
      and r.reminder_sent_at is null
      and cs.status = 'scheduled'
      and ((cs.date + cs.start_time) at time zone v_tz)
            between now() and now() + interval '1 hour'
    for update of r skip locked
  loop
    -- Marcar primero: evita reintentos infinitos si el envio falla.
    update reservations set reminder_sent_at = now() where id = v_r.id;

    if v_r.email is null or v_r.email = '' then
      continue;
    end if;

    begin
      perform net.http_post(
        url     := v_fn_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-webhook-secret', coalesce(v_secret, '')
        ),
        body    := jsonb_build_object(
          'email',      v_r.email,
          'name',       coalesce(v_r.name, ''),
          'class_name', v_r.class_name,
          'date',       to_char(v_r.date, 'DD/MM/YYYY'),
          'time',       to_char(v_r.start_time, 'HH24:MI')
        )
      );
    exception when others then
      raise warning 'send-class-reminder no enviado (reserva %): %', v_r.id, sqlerrm;
    end;
  end loop;
exception when others then
  raise warning 'send_class_reminders: %', sqlerrm;
end;
$$;

-- ===== Programar cada 10 minutos =====
-- Desprograma una version previa si existe (idempotente) y reprograma.
do $$
begin
  perform cron.unschedule('send_class_reminders');
exception when others then
  null;
end $$;

select cron.schedule(
  'send_class_reminders',
  '*/10 * * * *',
  $cron$ select public.send_class_reminders(); $cron$
);
