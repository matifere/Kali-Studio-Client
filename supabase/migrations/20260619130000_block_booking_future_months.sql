-- Bloquea reservar clases de un mes calendario futuro.
--
-- Los planes duran 30 días, así que validar solo la cobertura del plan (fix
-- anterior) igual permitía reservar clases del mes siguiente que caían dentro
-- de la ventana de 30 días. El estudio quiere que un alumno solo pueda reservar
-- clases del mes calendario en curso (nada por adelantado de otro mes).
--
-- date_trunc('month', ...) compara mes Y año, así que el cruce dic/ene es correcto.

create or replace function public.book_session_if_available(p_session_id uuid, p_user_id uuid)
returns json language plpgsql security definer as $fn$
declare
  v_caller         uuid := auth.uid();
  v_session_inst   uuid;
  v_capacity       int;
  v_confirmed      int;
  v_session_date   date;
  v_month_start    date;
  v_month_end      date;
  v_has_plan       int;
  v_max_per_month  int;
  v_used_month     int;
begin
  select capacity, date, institution_id into v_capacity, v_session_date, v_session_inst
  from class_sessions where id = p_session_id and status = 'scheduled';
  if v_capacity is null then return json_build_object('ok', false, 'error', 'session_not_found'); end if;

  if v_session_inst is distinct from kali_institution_id() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_user_id <> v_caller and not kali_is_admin() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  if not exists (select 1 from profiles where id = p_user_id and institution_id = v_session_inst) then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  if not exists (select 1 from profiles where id = p_user_id and is_active) then
    return json_build_object('ok', false, 'error', 'inactive');
  end if;

  -- No reservar por adelantado de un mes calendario futuro.
  if date_trunc('month', v_session_date) > date_trunc('month', current_date) then
    return json_build_object('ok', false, 'error', 'future_month');
  end if;

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then
    return json_build_object('ok', false, 'error', 'already_booked');
  end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  -- Plan activo en la fecha de la clase (no en current_date).
  select count(*) into v_has_plan from subscriptions
  where user_id = p_user_id and status = 'active' and v_session_date between start_date and end_date;
  if v_has_plan = 0 then return json_build_object('ok', false, 'error', 'no_plan'); end if;

  select p.max_reservations_per_month into v_max_per_month
  from subscriptions s join plans p on p.id = s.plan_id
  where s.user_id = p_user_id and s.status = 'active' and v_session_date between s.start_date and s.end_date
  order by s.created_at desc limit 1;

  if v_max_per_month is not null then
    v_month_start := date_trunc('month', v_session_date)::date;
    v_month_end   := (date_trunc('month', v_session_date) + interval '1 month' - interval '1 day')::date;
    select count(*) into v_used_month from reservations r
    join class_sessions cs on cs.id = r.session_id
    where r.user_id = p_user_id and r.status = 'confirmed' and cs.date between v_month_start and v_month_end;
    if v_used_month >= v_max_per_month then return json_build_object('ok', false, 'error', 'monthly_limit_exceeded'); end if;
  end if;

  insert into reservations (user_id, session_id, status, institution_id)
  values (p_user_id, p_session_id, 'confirmed', v_session_inst)
  on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

  return json_build_object('ok', true);
end;
$fn$;
