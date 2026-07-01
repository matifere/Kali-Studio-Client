-- Reemplaza el recordatorio de clases por mail por un aviso de vencimiento de plan.
--
-- ANTES (borrado aca):
--   - send_class_reminders(): mandaba "tu clase es en 1 hora" a cada reserva.
--   - cron 'send_class_reminders' cada 10 min.
--   - reservations.reminder_sent_at: marca de "ya avise".
--   - Edge Function send-class-reminder (se elimina del repo).
--
-- AHORA:
--   - send_payment_reminders(): busca suscripciones activas cuyo end_date cae a
--     7 dias (hora Argentina) y todavia no fueron avisadas, manda el mail via la
--     Edge Function send-payment-reminder (pg_net, async) y marca
--     subscriptions.payment_reminder_sent_at para no duplicar.
--   - cron 'send_payment_reminders' una vez por dia.
--
-- Requisitos previos (una sola vez, por entorno):
--   1. Deploy de la funcion:  supabase functions deploy send-payment-reminder --no-verify-jwt
--   2. Secrets: reusa SENDGRID_API_KEY, EMAIL_FROM, EMAIL_FROM_NAME, WAITLIST_WEBHOOK_SECRET.
--   3. Cargar private.email_config.payment_reminder_fn_url con la URL en ESTE entorno.

-- ===== Extensiones =====
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
delete from private.email_config where key = 'reminder_fn_url';

-- ===== 2. Marca de "ya avise" en la suscripcion =====
alter table public.subscriptions
  add column if not exists payment_reminder_sent_at timestamptz;

-- ===== 3. Config: URL de la funcion (el secreto se reusa del waitlist) =====
create schema if not exists private;

create table if not exists private.email_config (
  key   text primary key,
  value text not null
);

-- Placeholder: completar con UPDATE en cada entorno.
insert into private.email_config (key, value) values
  ('payment_reminder_fn_url', 'https://CAMBIAR.functions.supabase.co/functions/v1/send-payment-reminder')
on conflict (key) do nothing;

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
    return; -- sin URL configurada no hay nada que hacer
  end if;

  v_today := (now() at time zone v_tz)::date;

  for v_r in
    select s.id,
           p.email                     as email,
           p.full_name                 as name,
           coalesce(pl.name, 'tu plan') as plan_name,
           s.end_date                  as end_date
    from subscriptions s
    join profiles p on p.id = s.user_id
    left join plans pl on pl.id = s.plan_id
    where s.status = 'active'
      and s.payment_reminder_sent_at is null
      and s.end_date = v_today + 7
    for update of s skip locked
  loop
    -- Marcar primero: evita reintentos infinitos si el envio falla.
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

-- ===== 5. Programar una vez por dia (12:00 UTC ~ 09:00 Argentina) =====
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
