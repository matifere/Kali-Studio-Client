-- Fix: profiles.email quedaba NULL para clientes registrados desde la app Flutter.
--
-- Causa: el registro del cliente crea la fila de profiles con un upsert que NO
-- envia email (lib/supabase/supabase_auth_service.dart -> _upsertProfile). El
-- trigger handle_new_user() sobre auth.users si setea email, pero la fila la
-- termina creando el upsert de la app (no el trigger), dejando email en NULL.
-- En el panel admin eso se ve como "correo@pendiente.com".
--
-- Solucion (a nivel DB, independiente de la app):
--   1. Backfill de los emails faltantes desde auth.users.
--   2. Trigger de red de seguridad en public.profiles que rellena email desde
--      auth.users cada vez que entra NULL/vacio (INSERT o UPDATE). Nunca pisa un
--      email existente.

-- 1. Backfill
update public.profiles p
set email = u.email, updated_at = now()
from auth.users u
where u.id = p.id
  and (p.email is null or p.email = '')
  and u.email is not null;

-- 2. Funcion + trigger de red de seguridad
create or replace function public.fill_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.email is null or new.email = '' then
    select email into new.email from auth.users where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_fill_email on public.profiles;

create trigger profiles_fill_email
before insert or update on public.profiles
for each row execute function public.fill_profile_email();
