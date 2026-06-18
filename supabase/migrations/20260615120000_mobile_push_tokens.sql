-- Tabla de tokens de push para móvil (FCM). El equivalente web vive en
-- push_subscriptions; esta es para Android/iOS vía Firebase Cloud Messaging.
--
-- Un usuario tiene a lo sumo un token por plataforma (UNIQUE user_id, platform):
-- al loguear o en onTokenRefresh se hace upsert sobre ese par. La Edge Function
-- send-push (service role) lee los tokens del destinatario para enviar el push.

create table if not exists public.mobile_push_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now(),
  unique (user_id, platform)
);

create index if not exists mobile_push_tokens_user_idx
  on public.mobile_push_tokens (user_id);

alter table public.mobile_push_tokens enable row level security;

-- El usuario solo ve y administra sus propios tokens. La función de envío usa
-- service role y se saltea RLS.
drop policy if exists mobile_push_tokens_select on public.mobile_push_tokens;
create policy mobile_push_tokens_select on public.mobile_push_tokens
  for select to authenticated using (user_id = auth.uid());

drop policy if exists mobile_push_tokens_insert on public.mobile_push_tokens;
create policy mobile_push_tokens_insert on public.mobile_push_tokens
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists mobile_push_tokens_update on public.mobile_push_tokens;
create policy mobile_push_tokens_update on public.mobile_push_tokens
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists mobile_push_tokens_delete on public.mobile_push_tokens;
create policy mobile_push_tokens_delete on public.mobile_push_tokens
  for delete to authenticated using (user_id = auth.uid());

grant select, insert, update, delete on public.mobile_push_tokens to authenticated;
