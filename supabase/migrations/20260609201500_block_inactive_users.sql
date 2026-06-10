-- Fix: un alumno puesto en "inactivo" (profiles.is_active=false) desde el panel
-- admin seguia pudiendo entrar y operar en la app de clientes.
--
-- Causa: la app de clientes nunca chequeaba is_active (solo desloguea si el perfil
-- es null), y la base tampoco lo enforce-aba: las RLS scoped por institucion usan
-- kali_institution_id() sin mirar is_active, y el RPC de reserva tampoco.
--
-- Solucion (100% a nivel DB, sin tocar la app):
--   1. kali_institution_id() devuelve NULL si el caller esta inactivo. Es el choke
--      point de 24 policies (class_sessions, plans, profiles, reservations,
--      schedule_templates, subscriptions) -> un inactivo pierde acceso a todo.
--   2. profiles_select: la rama "propio perfil" exige is_active. Asi obtenerPerfil()
--      devuelve null y la app ejecuta su signOut() existente ("Tu cuenta no esta
--      habilitada. Contacta al estudio."). El admin (activo) sigue viendo al alumno
--      via la rama de institucion.
--   3. book_session_if_available(): guard de is_active al inicio (defensa en
--      profundidad: bloquea la reserva por RPC aunque el usuario tenga token/plan).

-- 1. Choke point
create or replace function public.kali_institution_id()
returns uuid
language sql
stable security definer
set search_path to 'public'
as $fn$
  select institution_id from profiles where id = auth.uid() and is_active
$fn$;

-- 2. Auto-signout del inactivo
alter policy profiles_select on public.profiles
  using (((id = auth.uid() and is_active) or (institution_id = kali_institution_id())));

-- 3. Guard en el RPC de reserva
create or replace function public.book_session_if_available(p_session_id uuid, p_user_id uuid)
returns json
language plpgsql
security definer
as $fn$
DECLARE
  v_capacity     int;
  v_confirmed    int;
  v_session_date date;
  v_week_start   date;
  v_week_end     date;
  v_has_plan     int;
  v_max_per_week int;
  v_used_week    int;
BEGIN
  -- Bloquear usuarios inactivos
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_user_id AND is_active) THEN
    RETURN json_build_object('ok', false, 'error', 'inactive');
  END IF;

  SELECT capacity, date INTO v_capacity, v_session_date
  FROM class_sessions
  WHERE id = p_session_id AND status = 'scheduled';

  IF v_capacity IS NULL THEN
    RETURN json_build_object('ok', false, 'error', 'session_not_found');
  END IF;

  IF EXISTS (
    SELECT 1 FROM reservations
    WHERE session_id = p_session_id AND user_id = p_user_id AND status = 'confirmed'
  ) THEN
    RETURN json_build_object('ok', false, 'error', 'already_booked');
  END IF;

  SELECT COUNT(*) INTO v_confirmed
  FROM reservations
  WHERE session_id = p_session_id AND status = 'confirmed';

  IF v_confirmed >= v_capacity THEN
    RETURN json_build_object('ok', false, 'error', 'full');
  END IF;

  SELECT COUNT(*) INTO v_has_plan
  FROM subscriptions
  WHERE user_id = p_user_id
    AND status = 'active'
    AND CURRENT_DATE BETWEEN start_date AND end_date;

  IF v_has_plan = 0 THEN
    RETURN json_build_object('ok', false, 'error', 'no_plan');
  END IF;

  SELECT p.max_reservations_per_week INTO v_max_per_week
  FROM subscriptions s
  JOIN plans p ON p.id = s.plan_id
  WHERE s.user_id = p_user_id
    AND s.status = 'active'
    AND CURRENT_DATE BETWEEN s.start_date AND s.end_date
  ORDER BY s.created_at DESC
  LIMIT 1;

  IF v_max_per_week IS NOT NULL THEN
    v_week_start := date_trunc('week', v_session_date)::date;
    v_week_end   := v_week_start + 6;

    SELECT COUNT(*) INTO v_used_week
    FROM reservations r
    JOIN class_sessions cs ON cs.id = r.session_id
    WHERE r.user_id = p_user_id
      AND r.status = 'confirmed'
      AND cs.date BETWEEN v_week_start AND v_week_end;

    IF v_used_week >= v_max_per_week THEN
      RETURN json_build_object('ok', false, 'error', 'weekly_limit_exceeded');
    END IF;
  END IF;

  INSERT INTO reservations (user_id, session_id, status)
  VALUES (p_user_id, p_session_id, 'confirmed')
  ON CONFLICT (user_id, session_id)
  DO UPDATE SET status = 'confirmed', cancelled_at = null, cancelled_by = null;

  RETURN json_build_object('ok', true);
END;
$fn$;
