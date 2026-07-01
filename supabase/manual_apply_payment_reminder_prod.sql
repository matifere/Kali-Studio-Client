-- ============================================================================
-- APLICAR A MANO EN PRODUCCION (SQL Editor del proyecto Kali Studio).
--
-- Por que a mano y no `db push`: el historial de migraciones esta divergente.
-- Este script es idempotente y autocontenido: deja el estado final correcto sin
-- importar que haya aplicado prod, y NO toca la tabla de historial.
--
-- Reemplaza el recordatorio de clases (borrado) por un aviso de vencimiento de
-- plan: manda un mail a cada suscripcion activa cuyo end_date cae a 7 dias.
-- Usa pg_cron (job diario) + pg_net (POST a la Edge Function
-- send-payment-reminder). Reusa el WAITLIST_WEBHOOK_SECRET del waitlist.
--
-- ANTES de correr:
--   1. Deploy de la funcion:  supabase functions deploy send-payment-reminder --no-verify-jwt
--      (los secrets SENDGRID_API_KEY/EMAIL_FROM/EMAIL_FROM_NAME/WAITLIST_WEBHOOK_SECRET
--       ya estan seteados por send-waitlist-email; se comparten.)
--   2. (Opcional) Borrar la Edge Function vieja:  supabase functions delete send-class-reminder
-- ============================================================================

-- ===== 0. Extensiones =====
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- ===== 1. Borrar el recordatorio de clases =====
do $$
begin
  perform cron.unschedule('send_class_reminders');
exception when others then
  null;
end $$;

drop function if exists public.send_class_reminders();
alter table public.reservations drop column if exists reminder_sent_at;

create schema if not exists private;
create table if not exists private.email_config (
  key   text primary key,
  value text not null
);
delete from private.email_config where key = 'reminder_fn_url';

-- ===== 2. Marca de "ya avise" en la suscripcion =====
alter table public.subscriptions
  add column if not exists payment_reminder_sent_at timestamptz;

-- ===== 3. Config: URL de la funcion en prod (el secreto ya existe del waitlist) =====
insert into private.email_config (key, value) values
  ('payment_reminder_fn_url', 'https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/send-payment-reminder')
on conflict (key) do update set value = excluded.value;

-- ===== 4. Job: avisa planes que vencen en 7 dias =====
create or replace function public.send_payment_reminders()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz       constant text := 'America/Argentina/Buenos_Aires';
  v_today    date;
  v_fn_url   text;
  v_secret   text;
  v_r        record;
begin
  select value into v_fn_url from private.email_config where key = 'payment_reminder_fn_url';
  select value into v_secret from private.email_config where key = 'waitlist_webhook_secret';

  if v_fn_url is null or v_fn_url like 'https://CAMBIAR%' then
    return;
  end if;

  v_today := (now() at time zone v_tz)::date;

  for v_r in
    select s.id,
           p.email                      as email,
           p.full_name                  as name,
           coalesce(pl.name, 'tu plan') as plan_name,
           s.end_date                   as end_date
    from subscriptions s
    join profiles p on p.id = s.user_id
    left join plans pl on pl.id = s.plan_id
    where s.status = 'active'
      and s.payment_reminder_sent_at is null
      and s.end_date = v_today + 7
    for update of s skip locked
  loop
    update subscriptions set payment_reminder_sent_at = now() where id = v_r.id;

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
          'email',     v_r.email,
          'name',      coalesce(v_r.name, ''),
          'plan_name', v_r.plan_name,
          'end_date',  to_char(v_r.end_date, 'DD/MM/YYYY')
        )
      );
    exception when others then
      raise warning 'send-payment-reminder no enviado (suscripcion %): %', v_r.id, sqlerrm;
    end;
  end loop;
exception when others then
  raise warning 'send_payment_reminders: %', sqlerrm;
end;
$$;

-- ===== 5. Programar una vez por dia (12:00 UTC ~ 09:00 Argentina), idempotente =====
do $$
begin
  perform cron.unschedule('send_payment_reminders');
exception when others then
  null;
end $$;

select cron.schedule(
  'send_payment_reminders',
  '0 12 * * *',
  $cron$ select public.send_payment_reminders(); $cron$
);

-- ===== 6. Verificacion rapida =====
-- select * from private.email_config;
-- select jobname, schedule, active from cron.job where jobname = 'send_payment_reminders';
-- select * from cron.job_run_details order by start_time desc limit 5;
-- Probar a mano (manda los que correspondan hoy):  select public.send_payment_reminders();
