-- ============================================================================
-- APLICAR A MANO EN PRODUCCION (SQL Editor del proyecto Kali Studio).
--
-- Por que a mano y no `db push`: el historial de migraciones esta divergente.
-- Este script es idempotente y autocontenido: deja el estado final correcto sin
-- importar que haya aplicado prod, y NO toca la tabla de historial.
--
-- Manda un recordatorio por mail ~1 hora antes de cada clase a las reservas
-- confirmadas. Usa pg_cron (job cada 10 min) + pg_net (POST a la Edge Function
-- send-class-reminder). Reusa el WAITLIST_WEBHOOK_SECRET del waitlist.
--
-- ANTES de correr:
--   1. Deploy de la funcion:  supabase functions deploy send-class-reminder --no-verify-jwt
--      (los secrets SENDGRID_API_KEY/EMAIL_FROM/EMAIL_FROM_NAME/WAITLIST_WEBHOOK_SECRET
--       ya estan seteados por la funcion send-waitlist-email; se comparten.)
-- ============================================================================

-- ===== 0. Extensiones =====
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- ===== 1. Marca de "ya avise" en la reserva =====
alter table public.reservations
  add column if not exists reminder_sent_at timestamptz;

-- ===== 2. Config: URL de la funcion en prod (el secreto ya existe del waitlist) =====
create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

insert into private.email_config (key, value) values
  ('reminder_fn_url', 'https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/send-class-reminder')
on conflict (key) do update set value = excluded.value;

-- ===== 3. Job: recordatorios de clases que arrancan en la proxima hora =====
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
    return;
  end if;

  for v_r in
    select r.id,
           p.email                                as email,
           p.full_name                            as name,
           coalesce(cs.name, st.name, 'tu clase') as class_name,
           cs.date                                as date,
           cs.start_time                          as start_time
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

-- ===== 4. Programar cada 10 minutos (idempotente) =====
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

-- ===== 5. Verificacion rapida =====
-- select * from private.email_config;
-- select jobname, schedule, active from cron.job where jobname = 'send_class_reminders';
-- select * from cron.job_run_details order by start_time desc limit 5;
-- Probar a mano (manda los que correspondan ahora mismo):  select public.send_class_reminders();
