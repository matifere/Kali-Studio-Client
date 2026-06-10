-- ============================================================
-- Remediacion de autorizacion (todo a nivel DB).
-- Las RLS scoped por institucion no distinguian client vs admin:
-- cualquier socio podia crear/borrar clases, planes, perfiles, etc.
-- El RPC de reserva no validaba identidad ni institucion (IDOR + cross-tenant).
-- Fix: helper kali_is_admin(), gate de escritura por rol, restriccion de
-- lectura de PII, guard anti-escalada en profiles, y hardening del RPC.
-- ============================================================

-- Helper: el caller es admin/sudo y esta activo
create or replace function public.kali_is_admin()
returns boolean language sql stable security definer set search_path to 'public' as $$
  select exists(select 1 from profiles where id = auth.uid() and is_active and role in ('admin','sudo'))
$$;

-- ===== class_sessions: escritura solo admin (lectura sigue por institucion) =====
alter policy class_sessions_insert on public.class_sessions with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy class_sessions_update on public.class_sessions using (institution_id = kali_institution_id() and kali_is_admin()) with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy class_sessions_delete on public.class_sessions using (institution_id = kali_institution_id() and kali_is_admin());

-- ===== plans: escritura solo admin (lectura sigue: el cliente ve los planes ofrecidos) =====
alter policy plans_insert on public.plans with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy plans_update on public.plans using (institution_id = kali_institution_id() and kali_is_admin()) with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy plans_delete on public.plans using (institution_id = kali_institution_id() and kali_is_admin());

-- ===== schedule_templates: escritura solo admin (lectura sigue: embed en class_sessions) =====
alter policy schedule_templates_insert on public.schedule_templates with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy schedule_templates_update on public.schedule_templates using (institution_id = kali_institution_id() and kali_is_admin()) with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy schedule_templates_delete on public.schedule_templates using (institution_id = kali_institution_id() and kali_is_admin());

-- ===== subscriptions: escritura solo admin; lectura propia o admin =====
alter policy subscriptions_select on public.subscriptions using ((user_id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin()));
alter policy subscriptions_insert on public.subscriptions with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy subscriptions_update on public.subscriptions using (institution_id = kali_institution_id() and kali_is_admin()) with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy subscriptions_delete on public.subscriptions using (institution_id = kali_institution_id() and kali_is_admin());

-- ===== profiles =====
-- lectura: el propio (activo) o, si sos admin, toda tu institucion
alter policy profiles_select on public.profiles using ((id = auth.uid() and is_active) or (institution_id = kali_institution_id() and kali_is_admin()));
-- insert: el propio (signup) o admin agregando alumno
alter policy profiles_insert on public.profiles with check ((id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin()));
-- update: el propio o admin en su institucion
alter policy profiles_update on public.profiles using ((id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin())) with check ((id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin()));
-- delete: solo admin
alter policy profiles_delete on public.profiles using (institution_id = kali_institution_id() and kali_is_admin());

-- guard anti-escalada: un no-admin editando su propio perfil no puede cambiar
-- role / is_active, ni mover su institucion una vez asignada (permite el set inicial del signup)
create or replace function public.profiles_guard_self()
returns trigger language plpgsql security definer set search_path to public, auth as $$
begin
  if auth.uid() is not null and new.id = auth.uid() and not public.kali_is_admin() then
    if tg_op = 'UPDATE' then
      new.role := old.role;
      new.is_active := old.is_active;
      if old.institution_id is not null then new.institution_id := old.institution_id; end if;
    elsif tg_op = 'INSERT' then
      new.role := 'client';
      new.is_active := true;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_guard_self on public.profiles;
create trigger profiles_guard_self before insert or update on public.profiles
for each row execute function public.profiles_guard_self();

-- ===== reservations: escritura propia o admin (no tocar la de otros) =====
-- insert directo: solo admin (el cliente reserva por el RPC, que corre como definer)
alter policy reservations_insert on public.reservations with check (institution_id = kali_institution_id() and kali_is_admin());
alter policy reservations_update on public.reservations using ((user_id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin())) with check ((user_id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin()));
alter policy reservations_delete on public.reservations using ((user_id = auth.uid()) or (institution_id = kali_institution_id() and kali_is_admin()));

-- ===== RPC de reserva: identidad + institucion + setea institution_id =====
create or replace function public.book_session_if_available(p_session_id uuid, p_user_id uuid)
returns json language plpgsql security definer as $fn$
declare
  v_caller       uuid := auth.uid();
  v_session_inst uuid;
  v_capacity     int;
  v_confirmed    int;
  v_session_date date;
  v_week_start   date;
  v_week_end     date;
  v_has_plan     int;
  v_max_per_week int;
  v_used_week    int;
begin
  select capacity, date, institution_id into v_capacity, v_session_date, v_session_inst
  from class_sessions where id = p_session_id and status = 'scheduled';
  if v_capacity is null then return json_build_object('ok', false, 'error', 'session_not_found'); end if;

  -- la sesion debe ser de la institucion del caller (no cross-tenant)
  if v_session_inst is distinct from kali_institution_id() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- reservas para uno mismo, o un admin/sudo reservando para un alumno (no IDOR)
  if p_user_id <> v_caller and not kali_is_admin() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- el usuario destino debe pertenecer a la misma institucion
  if not exists (select 1 from profiles where id = p_user_id and institution_id = v_session_inst) then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- destino activo
  if not exists (select 1 from profiles where id = p_user_id and is_active) then
    return json_build_object('ok', false, 'error', 'inactive');
  end if;

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then
    return json_build_object('ok', false, 'error', 'already_booked');
  end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  select count(*) into v_has_plan from subscriptions
  where user_id = p_user_id and status = 'active' and CURRENT_DATE between start_date and end_date;
  if v_has_plan = 0 then return json_build_object('ok', false, 'error', 'no_plan'); end if;

  select p.max_reservations_per_week into v_max_per_week
  from subscriptions s join plans p on p.id = s.plan_id
  where s.user_id = p_user_id and s.status = 'active' and CURRENT_DATE between s.start_date and s.end_date
  order by s.created_at desc limit 1;

  if v_max_per_week is not null then
    v_week_start := date_trunc('week', v_session_date)::date;
    v_week_end   := v_week_start + 6;
    select count(*) into v_used_week from reservations r
    join class_sessions cs on cs.id = r.session_id
    where r.user_id = p_user_id and r.status = 'confirmed' and cs.date between v_week_start and v_week_end;
    if v_used_week >= v_max_per_week then return json_build_object('ok', false, 'error', 'weekly_limit_exceeded'); end if;
  end if;

  insert into reservations (user_id, session_id, status, institution_id)
  values (p_user_id, p_session_id, 'confirmed', v_session_inst)
  on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

  return json_build_object('ok', true);
end;
$fn$;
