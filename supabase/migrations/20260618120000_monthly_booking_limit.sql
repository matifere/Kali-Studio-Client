-- Cambia el límite de reservas de semanal a mensual.
--
-- Antes: max_reservations_per_week en plans → se contaba por semana (Lun-Dom).
-- Ahora: max_reservations_per_month          → se cuenta por mes calendario.
-- Migración de datos: los planes existentes quedan con N_semana × 4 clases/mes.

-- ===== 1. Alterar la tabla plans =====
alter table public.plans
  add column if not exists max_reservations_per_month int;

update public.plans
set max_reservations_per_month = max_reservations_per_week * 4
where max_reservations_per_week is not null;

alter table public.plans
  drop column if exists max_reservations_per_week;

-- ===== 2. RPC book_session_if_available: semana → mes =====
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

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then
    return json_build_object('ok', false, 'error', 'already_booked');
  end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  select count(*) into v_has_plan from subscriptions
  where user_id = p_user_id and status = 'active' and current_date between start_date and end_date;
  if v_has_plan = 0 then return json_build_object('ok', false, 'error', 'no_plan'); end if;

  select p.max_reservations_per_month into v_max_per_month
  from subscriptions s join plans p on p.id = s.plan_id
  where s.user_id = p_user_id and s.status = 'active' and current_date between s.start_date and s.end_date
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

-- ===== 3. Trigger promote_waitlist_on_cancellation: semana → mes =====
create or replace function public.promote_waitlist_on_cancellation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session      class_sessions%rowtype;
  v_class_name   text;
  v_confirmed    int;
  v_month_start  date;
  v_month_end    date;
  v_waiter       record;
  v_limit        int;
  v_used         int;
  v_email        text;
  v_name         text;
  v_fn_url       text;
  v_secret       text;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then
    return new;
  end if;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < current_date then
    return new;
  end if;

  select count(*) into v_confirmed
  from reservations where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then
    return new;
  end if;

  select coalesce(v_session.name, st.name, 'la clase') into v_class_name
  from (select 1) as one
  left join schedule_templates st on st.id = v_session.template_id;

  v_month_start := date_trunc('month', v_session.date)::date;
  v_month_end   := (date_trunc('month', v_session.date) + interval '1 month' - interval '1 day')::date;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    select p.max_reservations_per_month into v_limit
    from subscriptions s
    join plans p on p.id = s.plan_id
    where s.user_id = v_waiter.user_id and s.status = 'active'
      and s.start_date <= v_session.date and s.end_date >= v_session.date
    order by s.end_date desc
    limit 1;
    if not found then continue; end if;

    if v_limit is not null then
      select count(*) into v_used
      from reservations r
      join class_sessions cs on cs.id = r.session_id
      where r.user_id = v_waiter.user_id and r.status = 'confirmed'
        and cs.date between v_month_start and v_month_end;
      if v_used >= v_limit then continue; end if;
    end if;

    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    insert into reservations (user_id, session_id, status, institution_id)
    values (v_waiter.user_id, new.session_id, 'confirmed', v_session.institution_id)
    on conflict (user_id, session_id) do update
      set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (
      v_waiter.user_id,
      '¡Conseguiste un lugar!',
      'Se liberó un lugar en ' || v_class_name || ' del '
        || to_char(v_session.date, 'DD/MM')
        || '. Ya estás inscripto automáticamente.',
      'waitlist'
    );

    begin
      select email, full_name into v_email, v_name
      from profiles where id = v_waiter.user_id;

      select value into v_fn_url  from private.email_config where key = 'waitlist_fn_url';
      select value into v_secret  from private.email_config where key = 'waitlist_webhook_secret';

      if v_email is not null and v_email <> ''
         and v_fn_url is not null and v_fn_url not like 'https://CAMBIAR%' then
        perform net.http_post(
          url     := v_fn_url,
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-webhook-secret', coalesce(v_secret, '')
          ),
          body    := jsonb_build_object(
            'email',      v_email,
            'name',       coalesce(v_name, ''),
            'class_name', v_class_name,
            'date',       to_char(v_session.date, 'DD/MM/YYYY'),
            'time',       to_char(v_session.start_time, 'HH24:MI')
          )
        );
      end if;
    exception when others then
      raise warning 'send-waitlist-email no enviado: %', sqlerrm;
    end;

    exit;
  end loop;

  return new;
exception when others then
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$$;
