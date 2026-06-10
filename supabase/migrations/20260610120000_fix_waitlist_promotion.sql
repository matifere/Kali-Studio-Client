-- Arregla la promoción de lista de espera:
--
-- 1. La tabla notifications no existía, pero los triggers de promoción insertaban
--    en ella: con gente en lista de espera, cancelar una reserva explotaba y la
--    cancelación entera fallaba.
-- 2. Había DOS triggers de promoción sobre reservations (trg_promote_from_waitlist
--    y trg_promote_waitlist, de dos intentos distintos). Ambos corrían en cada
--    cancelación: con 2+ anotados, una sola cancelación promovía a dos personas
--    para un único lugar (sobreventa).
-- 3. Ninguno validaba que la sesión siguiera vigente (promovían a clases pasadas
--    o canceladas), ni el cupo real, ni seteaban institution_id, y el INSERT
--    chocaba con el UNIQUE(user_id, session_id) si el promovido había cancelado
--    antes en la misma sesión.

-- ===== 1. Tabla notifications =====
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  body       text not null,
  type       text not null default 'general',
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select to authenticated using (user_id = auth.uid());

-- Solo marcar como leídas las propias; el contenido lo escribe el trigger (definer).
drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, update on public.notifications to authenticated;

-- Realtime para el badge en vivo de la app
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then
  null;
end $$;

-- ===== 2. Un solo trigger de promoción, corregido =====
drop trigger if exists trg_promote_from_waitlist on public.reservations;
drop trigger if exists trg_promote_waitlist on public.reservations;
drop function if exists public.promote_from_waitlist();
drop function if exists public.promote_waitlist_on_cancellation();

create or replace function public.promote_waitlist_on_cancellation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session    class_sessions%rowtype;
  v_class_name text;
  v_confirmed  int;
  v_week_start date;
  v_week_end   date;
  v_waiter     record;
  v_limit      int;
  v_used       int;
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

  v_week_start := date_trunc('week', v_session.date)::date;
  v_week_end   := v_week_start + 6;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    -- plan activo que cubra la fecha de la clase
    select p.max_reservations_per_week into v_limit
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
        and cs.date between v_week_start and v_week_end;
      if v_used >= v_limit then continue; end if;
    end if;

    -- ya tiene reserva confirmada en esta sesión: limpiar la fila huérfana y seguir
    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- revive la fila cancelada si existía (UNIQUE user_id, session_id)
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

    exit;
  end loop;

  return new;
exception when others then
  -- la promoción nunca debe impedir la cancelación original
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$$;

create trigger trg_promote_waitlist
  after update of status on public.reservations
  for each row
  when (new.status = 'cancelled' and old.status <> 'cancelled')
  execute function public.promote_waitlist_on_cancellation();
