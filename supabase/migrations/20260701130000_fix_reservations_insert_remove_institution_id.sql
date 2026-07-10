-- Incidente: reservar estaba caido para TODOS (web y mobile).
--
-- Causa raiz: en prod la tabla public.reservations NO tiene columna
-- institution_id (el tenant se deriva por join a class_sessions.session_id;
-- asi lo hacen las policies RLS reales de prod: reservations_insert/select/...
-- usan `exists (select 1 from class_sessions cs where cs.id = session_id and
-- cs.institution_id = kali_institution_id())`). Sin embargo, el RPC
-- book_session_if_available y el trigger promote_waitlist_on_cancellation
-- hacian `insert into reservations (..., institution_id)`, columna que no
-- existe -> ERROR 42703 en cada reserva y en cada promocion de lista de espera.
-- (Las migraciones que asumian reservations.institution_id nunca se aplicaron
-- a prod; el historial esta divergente y se aplica a mano.)
--
-- Fix: recrear ambas funciones sacando institution_id del insert. El scoping
-- por tenant lo sigue garantizando el chequeo del propio RPC
-- (v_session_inst is distinct from kali_institution_id()) y la RLS por join.

create or replace function public.book_session_if_available(p_session_id uuid, p_user_id uuid)
returns json language plpgsql security definer as $fn$
declare
  v_tz             constant text := 'America/Argentina/Buenos_Aires';
  v_today          date := (now() at time zone 'America/Argentina/Buenos_Aires')::date;
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

  -- No reservar por adelantado de un mes calendario futuro (fecha local Argentina,
  -- no current_date que es UTC). date_trunc compara mes Y anio.
  if date_trunc('month', v_session_date) > date_trunc('month', v_today) then
    return json_build_object('ok', false, 'error', 'future_month');
  end if;

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then
    return json_build_object('ok', false, 'error', 'already_booked');
  end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  -- Plan activo en la fecha de la clase (no en el "hoy").
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

  -- reservations NO tiene institution_id en prod: no incluir esa columna.
  insert into reservations (user_id, session_id, status)
  values (p_user_id, p_session_id, 'confirmed')
  on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

  return json_build_object('ok', true);
end;
$fn$;

create or replace function public.promote_waitlist_on_cancellation()
returns trigger language plpgsql security definer set search_path to 'public' as $fn$
declare
  v_session    class_sessions%rowtype;
  v_class_name text;
  v_confirmed  int;
  v_month_start date;
  v_waiter     record;
  v_limit      int;
  v_used       int;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then return new; end if;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < current_date then return new; end if;

  select count(*) into v_confirmed from reservations where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then return new; end if;

  v_class_name := v_session.name;
  v_month_start := date_trunc('month', v_session.date)::date;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    select p.max_reservations_per_month into v_limit
    from subscriptions s join plans p on p.id = s.plan_id
    where s.user_id = v_waiter.user_id and s.status = 'active'
      and s.start_date <= v_session.date and s.end_date >= v_session.date
    order by s.end_date desc limit 1;

    if not found then continue; end if;

    if v_limit is not null then
      select count(*) into v_used
      from reservations r join class_sessions cs on cs.id = r.session_id
      where r.user_id = v_waiter.user_id and r.status = 'confirmed'
        and cs.date >= v_month_start and cs.date < v_month_start + interval '1 month';
      if v_used >= v_limit then continue; end if;
    end if;

    if exists (select 1 from reservations where user_id = v_waiter.user_id and session_id = new.session_id and status = 'confirmed') then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- reservations NO tiene institution_id en prod: no incluir esa columna.
    insert into reservations (user_id, session_id, status)
    values (v_waiter.user_id, new.session_id, 'confirmed')
    on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (v_waiter.user_id, '¡Conseguiste un lugar!', 'Se liberó un lugar en ' || v_class_name || ' del ' || to_char(v_session.date, 'DD/MM') || ' y ya tenés la reserva confirmada.', 'booking');
  end loop;

  return new;
end;
$fn$;
