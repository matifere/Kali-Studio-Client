-- Dispara un push móvil (FCM) cada vez que se inserta una notificación in-app.
-- Así el push y la notificación en vivo (Realtime) quedan sincronizados: el
-- mismo INSERT que alimenta el badge manda el push.
--
-- El envío lo hace la Edge Function send-push, llamada con pg_net. La función
-- está protegida por un secreto compartido guardado en Vault (no en el cuerpo
-- del trigger) que se manda en el header x-webhook-secret.

create or replace function public.send_push_on_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, vault
as $$
declare
  v_secret text;
  v_url    text := 'https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/send-push';
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'push_webhook_secret'
  limit 1;

  if v_secret is null then
    return new; -- sin secreto configurado, no rompemos el INSERT
  end if;

  perform net.http_post(
    url     := v_url,
    body    := jsonb_build_object(
      'user_id', new.user_id,
      'title',   new.title,
      'body',    new.body,
      'data',    jsonb_build_object('type', new.type, 'notification_id', new.id)
    ),
    headers := jsonb_build_object(
      'Content-Type',    'application/json',
      'x-webhook-secret', v_secret
    )
  );

  return new;
exception when others then
  -- el push nunca debe impedir que se cree la notificación in-app
  raise warning 'send_push_on_notification: %', sqlerrm;
  return new;
end;
$$;

drop trigger if exists trg_send_push on public.notifications;
create trigger trg_send_push
  after insert on public.notifications
  for each row
  execute function public.send_push_on_notification();
