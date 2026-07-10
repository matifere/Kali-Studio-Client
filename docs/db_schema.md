# Esquema real de prod — Kali Studio (`tmfcnvtjzmtpqhzvfxos`)

> ⚠️ GENERADO AUTOMÁTICAMENTE por `scripts/dump_db_schema.sh`. No editar a mano.
> Snapshot del esquema **vivo** de prod. Es la FUENTE DE VERDAD por encima de
> `supabase/migrations/` (el historial de migraciones está divergente).
>
> Generado: 2026-07-10 13:10 -03

## Tablas y columnas

- `class_sessions.id` uuid NOT NULL default gen_random_uuid()
- `class_sessions.name` text NOT NULL
- `class_sessions.description` text
- `class_sessions.date` date NOT NULL
- `class_sessions.start_time` time without time zone NOT NULL
- `class_sessions.end_time` time without time zone NOT NULL
- `class_sessions.capacity` integer NOT NULL
- `class_sessions.status` session_status NOT NULL default 'scheduled'::session_status
- `class_sessions.cancellation_reason` text
- `class_sessions.instructor_name` text
- `class_sessions.created_at` timestamp with time zone NOT NULL default now()
- `class_sessions.updated_at` timestamp with time zone NOT NULL default now()
- `class_sessions.institution_id` uuid
- `class_sessions.group_id` uuid
- `institutions.id` uuid NOT NULL default gen_random_uuid()
- `institutions.name` text NOT NULL
- `institutions.slug` text NOT NULL
- `institutions.address` text
- `institutions.phone` text
- `institutions.is_active` boolean default true
- `institutions.created_at` timestamp with time zone default now()
- `institutions.logo_url` text
- `institutions.mp_token_secret_name` text
- `institutions.payment_alias` text
- `institutions.theme_id` text NOT NULL default 'default'::text
- `notifications.id` uuid NOT NULL default gen_random_uuid()
- `notifications.user_id` uuid NOT NULL
- `notifications.title` text NOT NULL
- `notifications.body` text NOT NULL
- `notifications.type` text NOT NULL default 'general'::text
- `notifications.is_read` boolean NOT NULL default false
- `notifications.created_at` timestamp with time zone NOT NULL default now()
- `payments.id` uuid NOT NULL default gen_random_uuid()
- `payments.user_id` uuid NOT NULL
- `payments.subscription_id` uuid
- `payments.amount` numeric(10,2) NOT NULL
- `payments.currency` text NOT NULL default 'ARS'::text
- `payments.method` payment_method
- `payments.status` payment_status NOT NULL default 'pending'::payment_status
- `payments.notes` text
- `payments.processed_by` uuid
- `payments.payment_date` timestamp with time zone
- `payments.created_at` timestamp with time zone NOT NULL default now()
- `payments.updated_at` timestamp with time zone NOT NULL default now()
- `payments.preference_id` text
- `payments.institution_id` uuid
- `plans.id` uuid NOT NULL default gen_random_uuid()
- `plans.name` text NOT NULL
- `plans.description` text
- `plans.price` numeric(10,2) NOT NULL
- `plans.currency` text NOT NULL default 'ARS'::text
- `plans.is_active` boolean NOT NULL default true
- `plans.created_at` timestamp with time zone NOT NULL default now()
- `plans.updated_at` timestamp with time zone NOT NULL default now()
- `plans.institution_id` uuid
- `plans.max_reservations_per_month` integer
- `profiles.id` uuid NOT NULL
- `profiles.full_name` text
- `profiles.phone` text
- `profiles.avatar_url` text
- `profiles.role` user_role NOT NULL default 'client'::user_role
- `profiles.is_active` boolean NOT NULL default true
- `profiles.created_at` timestamp with time zone NOT NULL default now()
- `profiles.updated_at` timestamp with time zone NOT NULL default now()
- `profiles.email` text
- `profiles.patologias` text[]
- `profiles.institution_id` uuid
- `push_subscriptions.id` uuid NOT NULL default gen_random_uuid()
- `push_subscriptions.user_id` uuid NOT NULL
- `push_subscriptions.endpoint` text NOT NULL
- `push_subscriptions.p256dh` text NOT NULL
- `push_subscriptions.auth_key` text NOT NULL
- `push_subscriptions.created_at` timestamp with time zone default now()
- `reservations.id` uuid NOT NULL default gen_random_uuid()
- `reservations.user_id` uuid NOT NULL
- `reservations.session_id` uuid NOT NULL
- `reservations.status` reservation_status NOT NULL default 'confirmed'::reservation_status
- `reservations.cancelled_at` timestamp with time zone
- `reservations.cancelled_by` uuid
- `reservations.notes` text
- `reservations.created_at` timestamp with time zone NOT NULL default now()
- `reservations.updated_at` timestamp with time zone NOT NULL default now()
- `saas_plans.id` uuid NOT NULL default gen_random_uuid()
- `saas_plans.name` text NOT NULL
- `saas_plans.description` text
- `saas_plans.price` numeric NOT NULL
- `saas_plans.currency` text NOT NULL default 'ARS'::text
- `saas_plans.is_active` boolean NOT NULL default true
- `saas_plans.created_at` timestamp with time zone NOT NULL default now()
- `saas_plans.updated_at` timestamp with time zone NOT NULL default now()
- `saas_plans.mp_plan_id` text
- `saas_plans.features` jsonb default '{}'::jsonb
- `subscriptions.id` uuid NOT NULL default gen_random_uuid()
- `subscriptions.user_id` uuid NOT NULL
- `subscriptions.plan_id` uuid NOT NULL
- `subscriptions.start_date` date NOT NULL
- `subscriptions.end_date` date NOT NULL
- `subscriptions.status` subscription_status NOT NULL default 'pending'::subscription_status
- `subscriptions.created_by` uuid
- `subscriptions.created_at` timestamp with time zone NOT NULL default now()
- `subscriptions.updated_at` timestamp with time zone NOT NULL default now()
- `subscriptions.payment_reminder_sent_at` timestamp with time zone
- `tenant_subscriptions.id` uuid NOT NULL default gen_random_uuid()
- `tenant_subscriptions.institution_id` uuid NOT NULL
- `tenant_subscriptions.saas_plan_id` uuid NOT NULL
- `tenant_subscriptions.status` text NOT NULL default 'pending'::text
- `tenant_subscriptions.mp_preapproval_id` text
- `tenant_subscriptions.current_period_start` timestamp with time zone
- `tenant_subscriptions.current_period_end` timestamp with time zone
- `tenant_subscriptions.created_at` timestamp with time zone NOT NULL default now()
- `tenant_subscriptions.updated_at` timestamp with time zone NOT NULL default now()
- `waitlist.id` uuid NOT NULL default gen_random_uuid()
- `waitlist.user_id` uuid NOT NULL
- `waitlist.session_id` uuid NOT NULL
- `waitlist.created_at` timestamp with time zone default now()
- `waitlist.status` text default 'waiting'::text

## Enums

- `day_of_week` = 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
- `payment_method` = 'mercadopago', 'stripe', 'manual'
- `payment_status` = 'pending', 'completed', 'failed', 'refunded'
- `reservation_status` = 'confirmed', 'cancelled', 'attended', 'no_show'
- `session_status` = 'scheduled', 'cancelled', 'paused', 'completed'
- `subscription_status` = 'active', 'expired', 'cancelled', 'pending'
- `user_role` = 'admin', 'client', 'sudo'

## Políticas RLS

- `class_sessions` / **class_sessions_delete** (DELETE) USING ((institution_id = kali_institution_id()) AND kali_is_admin())
- `class_sessions` / **class_sessions_insert** (INSERT) WITH CHECK ((institution_id = kali_institution_id()) AND kali_is_admin())
- `class_sessions` / **class_sessions_select** (SELECT) USING (institution_id = kali_institution_id())
- `class_sessions` / **class_sessions_update** (UPDATE) USING ((institution_id = kali_institution_id()) AND kali_is_admin()) WITH CHECK ((institution_id = kali_institution_id()) AND kali_is_admin())
- `institutions` / **Editar mi institucion** (UPDATE) USING (id = ( SELECT profiles.institution_id
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'sudo'::user_role))
 LIMIT 1))
- `institutions` / **Permitir lectura publica de instituciones activas** (SELECT) USING (is_active = true)
- `institutions` / **Ver mi institucion** (SELECT) USING (id = ( SELECT profiles.institution_id
   FROM profiles
  WHERE (profiles.id = auth.uid())
 LIMIT 1))
- `institutions` / **institutions_update_sudo** (UPDATE) USING (id = ( SELECT profiles.institution_id
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'sudo'::user_role))
 LIMIT 1))
- `institutions` / **studios_read** (SELECT) USING true
- `institutions` / **studios_read_anon** (SELECT) USING true
- `notifications` / **notifications_select** (SELECT) USING (user_id = auth.uid())
- `notifications` / **notifications_update** (UPDATE) USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())
- `payments` / **Admins can insert payments** (INSERT) WITH CHECK (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'sudo'::user_role))))
- `payments` / **staff_delete_institution_payments** (DELETE) USING (EXISTS ( SELECT 1
   FROM (profiles staff
     JOIN profiles student ON ((student.id = payments.user_id)))
  WHERE ((staff.id = auth.uid()) AND (staff.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (staff.institution_id = student.institution_id))))
- `payments` / **staff_read_institution_payments** (SELECT) USING (EXISTS ( SELECT 1
   FROM (profiles staff
     JOIN profiles student ON ((student.id = payments.user_id)))
  WHERE ((staff.id = auth.uid()) AND (staff.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (staff.institution_id = student.institution_id))))
- `payments` / **staff_update_institution_payments** (UPDATE) USING (EXISTS ( SELECT 1
   FROM (profiles staff
     JOIN profiles student ON ((student.id = payments.user_id)))
  WHERE ((staff.id = auth.uid()) AND (staff.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (staff.institution_id = student.institution_id)))) WITH CHECK (EXISTS ( SELECT 1
   FROM (profiles staff
     JOIN profiles student ON ((student.id = payments.user_id)))
  WHERE ((staff.id = auth.uid()) AND (staff.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (staff.institution_id = student.institution_id))))
- `plans` / **plans_delete** (DELETE) USING ((institution_id = kali_institution_id()) AND kali_is_admin())
- `plans` / **plans_insert** (INSERT) WITH CHECK ((institution_id = kali_institution_id()) AND kali_is_admin())
- `plans` / **plans_select** (SELECT) USING (institution_id = kali_institution_id())
- `plans` / **plans_update** (UPDATE) USING ((institution_id = kali_institution_id()) AND kali_is_admin()) WITH CHECK ((institution_id = kali_institution_id()) AND kali_is_admin())
- `profiles` / **profiles_delete** (DELETE) USING ((institution_id = kali_institution_id()) AND kali_is_admin())
- `profiles` / **profiles_insert** (INSERT) WITH CHECK ((id = auth.uid()) OR ((institution_id = kali_institution_id()) AND kali_is_admin()))
- `profiles` / **profiles_select** (SELECT) USING (((id = auth.uid()) AND is_active) OR ((institution_id = kali_institution_id()) AND kali_is_admin()))
- `profiles` / **profiles_update** (UPDATE) USING ((id = auth.uid()) OR ((institution_id = kali_institution_id()) AND kali_is_admin())) WITH CHECK ((id = auth.uid()) OR ((institution_id = kali_institution_id()) AND kali_is_admin()))
- `push_subscriptions` / **Users manage own subscriptions** (ALL) USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id)
- `push_subscriptions` / **push_own** (ALL) USING (auth.uid() = user_id)
- `reservations` / **Admins can update reservations in their institution** (UPDATE) USING (EXISTS ( SELECT 1
   FROM (profiles p
     JOIN class_sessions cs ON ((cs.institution_id = p.institution_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (cs.id = reservations.session_id))))
- `reservations` / **Admins can view all reservations in their institution** (SELECT) USING (EXISTS ( SELECT 1
   FROM (profiles p
     JOIN class_sessions cs ON ((cs.institution_id = p.institution_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['sudo'::user_role, 'admin'::user_role])) AND (cs.id = reservations.session_id))))
- `reservations` / **reservations_delete** (DELETE) USING ((user_id = auth.uid()) OR ((EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id())))) AND kali_is_admin()))
- `reservations` / **reservations_insert** (INSERT) WITH CHECK (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id()))))) OR ((EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id())))) AND kali_is_admin()))
- `reservations` / **reservations_select** (SELECT) USING ((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id())))))
- `reservations` / **reservations_update** (UPDATE) USING ((user_id = auth.uid()) OR ((EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id())))) AND kali_is_admin())) WITH CHECK ((user_id = auth.uid()) OR ((EXISTS ( SELECT 1
   FROM class_sessions cs
  WHERE ((cs.id = reservations.session_id) AND (cs.institution_id = kali_institution_id())))) AND kali_is_admin()))
- `saas_plans` / **Planes SaaS visibles para usuarios autenticados** (SELECT) USING true
- `subscriptions` / **subscriptions_delete** (DELETE) USING ((EXISTS ( SELECT 1
   FROM plans p
  WHERE ((p.id = subscriptions.plan_id) AND (p.institution_id = kali_institution_id())))) AND kali_is_admin())
- `subscriptions` / **subscriptions_insert** (INSERT) WITH CHECK ((EXISTS ( SELECT 1
   FROM plans p
  WHERE ((p.id = subscriptions.plan_id) AND (p.institution_id = kali_institution_id())))) AND kali_is_admin())
- `subscriptions` / **subscriptions_select** (SELECT) USING ((user_id = auth.uid()) OR ((EXISTS ( SELECT 1
   FROM plans p
  WHERE ((p.id = subscriptions.plan_id) AND (p.institution_id = kali_institution_id())))) AND kali_is_admin()))
- `subscriptions` / **subscriptions_update** (UPDATE) USING ((EXISTS ( SELECT 1
   FROM plans p
  WHERE ((p.id = subscriptions.plan_id) AND (p.institution_id = kali_institution_id())))) AND kali_is_admin()) WITH CHECK ((EXISTS ( SELECT 1
   FROM plans p
  WHERE ((p.id = subscriptions.plan_id) AND (p.institution_id = kali_institution_id())))) AND kali_is_admin())
- `tenant_subscriptions` / **Usuarios ven solo la suscripción de su institución** (SELECT) USING (institution_id IN ( SELECT profiles.institution_id
   FROM profiles
  WHERE (profiles.id = auth.uid())))
- `waitlist` / **users manage own waitlist** (ALL) USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())
- `waitlist` / **waitlist_own** (ALL) USING (auth.uid() = user_id)

## Triggers

- `class_sessions` → trg_class_sessions_updated_at
- `payments` → trg_payments_updated_at
- `plans` → trg_plans_updated_at
- `profiles` → profiles_fill_email
- `profiles` → profiles_guard_self
- `profiles` → trg_profiles_updated_at
- `profiles` → trg_sync_profiles_to_app_metadata
- `profiles` → trg_validate_profile_institution
- `reservations` → notify-waitlist
- `reservations` → trg_promote_waitlist
- `reservations` → trg_reservations_updated_at
- `subscriptions` → trg_subscriptions_updated_at

## Funciones / RPCs

### book_session_if_available
```sql
CREATE OR REPLACE FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$

```

### bypass_saas_subscription
```sql
CREATE OR REPLACE FUNCTION public.bypass_saas_subscription(p_plan_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_institution_id uuid;
BEGIN
  v_institution_id := public.kali_institution_id();
  
  INSERT INTO public.tenant_subscriptions (
    institution_id,
    saas_plan_id,
    status,
    current_period_start,
    current_period_end
  ) VALUES (
    v_institution_id,
    p_plan_id,
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + interval '1 month'
  )
  ON CONFLICT ON CONSTRAINT unique_institution_subscription
  DO UPDATE SET
    saas_plan_id = EXCLUDED.saas_plan_id,
    status = 'active',
    current_period_start = EXCLUDED.current_period_start,
    current_period_end = EXCLUDED.current_period_end,
    mp_preapproval_id = NULL;
END;
$function$

```

### cancel_day_as_holiday
```sql
CREATE OR REPLACE FUNCTION public.cancel_day_as_holiday(p_date date, p_reason text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_caller       uuid := auth.uid();
  v_inst         uuid := kali_institution_id();
  v_sessions     int  := 0;
  v_reservations int  := 0;
  r              record;
begin
  if not kali_is_admin() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;
  if v_inst is null then
    return json_build_object('ok', false, 'error', 'no_institution');
  end if;

  -- 1. Cancelar las sesiones agendadas del día (de la institución del admin).
  update class_sessions
     set status = 'cancelled'
   where date = p_date
     and institution_id = v_inst
     and status = 'scheduled';
  get diagnostics v_sessions = row_count;

  if v_sessions = 0 then
    return json_build_object('ok', true, 'sessions', 0, 'reservations', 0);
  end if;

  -- 2. Cancelar reservas confirmadas (devuelve el crédito) y 3. notificar a cada alumno.
  --    Las sesiones ya están 'cancelled', así que la promoción de lista de espera no dispara.
  for r in
    select res.id as res_id, res.user_id, cs.name as class_name, cs.date as class_date
      from reservations res
      join class_sessions cs on cs.id = res.session_id
     where cs.date = p_date
       and cs.institution_id = v_inst
       and res.status = 'confirmed'
  loop
    update reservations
       set status = 'cancelled', cancelled_at = now(), cancelled_by = v_caller
     where id = r.res_id;
    v_reservations := v_reservations + 1;

    insert into notifications (user_id, title, body, type)
    values (
      r.user_id,
      'Clase cancelada por feriado',
      'Se canceló ' || coalesce(nullif(r.class_name, ''), 'tu clase')
        || ' del ' || to_char(r.class_date, 'DD/MM')
        || case when nullif(p_reason, '') is not null then ' (' || p_reason || ')' else '' end
        || '. Se te devolvió el crédito, podés reservar otra clase.',
      'holiday'
    );
  end loop;

  -- 4. Limpiar lista de espera de las sesiones canceladas.
  delete from waitlist w
   using class_sessions cs
   where w.session_id = cs.id
     and cs.date = p_date
     and cs.institution_id = v_inst;

  return json_build_object('ok', true, 'sessions', v_sessions, 'reservations', v_reservations);
end;
$function$

```

### cancel_range_as_holiday
```sql
CREATE OR REPLACE FUNCTION public.cancel_range_as_holiday(p_start_date date, p_end_date date, p_reason text DEFAULT NULL::text, p_refund_credits boolean DEFAULT true)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_caller       uuid := auth.uid();
  v_inst         uuid := kali_institution_id();
  v_sessions     int  := 0;
  v_reservations int  := 0;
  r              record;
begin
  if not kali_is_admin() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;
  if v_inst is null then
    return json_build_object('ok', false, 'error', 'no_institution');
  end if;
  if p_end_date < p_start_date then
    return json_build_object('ok', false, 'error', 'invalid_range');
  end if;

  -- 1. Cancelar las sesiones agendadas del rango (de la institución del admin).
  update class_sessions
     set status = 'cancelled'
   where date between p_start_date and p_end_date
     and institution_id = v_inst
     and status = 'scheduled';
  get diagnostics v_sessions = row_count;

  if v_sessions = 0 then
    return json_build_object('ok', true, 'sessions', 0, 'reservations', 0);
  end if;

  -- 2. Procesar reservas confirmadas y 3. notificar a cada alumno.
  --    Las sesiones ya están 'cancelled', así que la promoción de lista de espera no dispara.
  for r in
    select res.id as res_id, res.user_id, cs.name as class_name, cs.date as class_date
      from reservations res
      join class_sessions cs on cs.id = res.session_id
     where cs.date between p_start_date and p_end_date
       and cs.institution_id = v_inst
       and res.status = 'confirmed'
  loop
    if p_refund_credits then
      -- Devolver el crédito: se cancela la reserva y se libera el cupo.
      update reservations
         set status = 'cancelled', cancelled_at = now(), cancelled_by = v_caller
       where id = r.res_id;
    else
      -- La clase se pierde: la reserva queda como ausente y NO libera cupo.
      update reservations
         set status = 'no_show', cancelled_at = now(), cancelled_by = v_caller
       where id = r.res_id;
    end if;
    v_reservations := v_reservations + 1;

    insert into notifications (user_id, title, body, type)
    values (
      r.user_id,
      'Clase cancelada por feriado',
      'Se canceló ' || coalesce(nullif(r.class_name, ''), 'tu clase')
        || ' del ' || to_char(r.class_date, 'DD/MM')
        || case when nullif(p_reason, '') is not null then ' (' || p_reason || ')' else '' end
        || case
             when p_refund_credits
               then '. Se te devolvió el crédito, podés reservar otra clase.'
               else '. Esta clase se computa como usada (no se devuelve el crédito).'
           end,
      'holiday'
    );
  end loop;

  -- 4. Limpiar lista de espera de las sesiones canceladas.
  delete from waitlist w
   using class_sessions cs
   where w.session_id = cs.id
     and cs.date between p_start_date and p_end_date
     and cs.institution_id = v_inst;

  return json_build_object('ok', true, 'sessions', v_sessions, 'reservations', v_reservations);
end;
$function$

```

### create_institution
```sql
CREATE OR REPLACE FUNCTION public.create_institution(inst_name text, inst_slug text, payment_alias text, phone text, address text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  new_inst_id uuid;
BEGIN
  -- Insertar la nueva institución y obtener su ID
  INSERT INTO institutions (name, slug, payment_alias, phone, address) 
  VALUES (inst_name, inst_slug, payment_alias, phone, address) 
  RETURNING id INTO new_inst_id;
  
  -- Actualizar el perfil del usuario con la nueva institución y rol sudo
  UPDATE profiles 
  SET institution_id = new_inst_id, role = 'sudo' 
  WHERE id = auth.uid();
  
  RETURN new_inst_id;
END;
$function$

```

### create_institution
```sql
CREATE OR REPLACE FUNCTION public.create_institution(inst_name text, inst_slug text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  new_inst_id uuid;
BEGIN
  -- Insertar la nueva institución y obtener su ID
  INSERT INTO institutions (name, slug) 
  VALUES (inst_name, inst_slug) 
  RETURNING id INTO new_inst_id;
  
  -- Actualizar el perfil del usuario con la nueva institución y rol sudo
  UPDATE profiles 
  SET institution_id = new_inst_id, role = 'sudo' 
  WHERE id = auth.uid();
  
  RETURN new_inst_id;
END;
$function$

```

### create_pending_payment
```sql
CREATE OR REPLACE FUNCTION public.create_pending_payment(p_plan_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id uuid;
    v_profile record;
    v_plan record;
    v_inst record;
    v_subscription_id uuid;
    v_payment_id uuid;
    v_start_date date := current_date;
    v_end_date date := current_date + interval '30 days';
BEGIN
    -- 1. Get the authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No autorizado';
    END IF;

    -- 2. Get user profile
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    -- 3. Get plan
    SELECT * INTO v_plan FROM public.plans WHERE id = p_plan_id AND is_active = true;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El plan no está disponible';
    END IF;

    IF v_profile.institution_id IS NOT NULL AND v_plan.institution_id IS NOT NULL THEN
        IF v_profile.institution_id != v_plan.institution_id THEN
            RAISE EXCEPTION 'El plan no pertenece a tu estudio';
        END IF;
    END IF;

    -- 4. Get institution alias
    SELECT * INTO v_inst FROM public.institutions WHERE id = COALESCE(v_plan.institution_id, v_profile.institution_id);
    IF v_inst.payment_alias IS NULL OR v_inst.payment_alias = '' THEN
        RAISE EXCEPTION 'Tu estudio no configuró un método de pago. Consultá con tu instructor.';
    END IF;

    -- 5. Check if already exists a pending sub
    SELECT id INTO v_subscription_id 
    FROM public.subscriptions 
    WHERE user_id = v_user_id AND plan_id = p_plan_id AND status = 'pending'
    ORDER BY created_at DESC LIMIT 1;

    IF v_subscription_id IS NOT NULL THEN
        UPDATE public.subscriptions 
        SET start_date = v_start_date, end_date = v_end_date 
        WHERE id = v_subscription_id;

        SELECT id INTO v_payment_id 
        FROM public.payments 
        WHERE subscription_id = v_subscription_id AND status = 'pending'
        ORDER BY created_at DESC LIMIT 1;

        IF v_payment_id IS NOT NULL THEN
            UPDATE public.payments 
            SET amount = v_plan.price, currency = COALESCE(v_plan.currency, 'ARS') 
            WHERE id = v_payment_id;
        END IF;
    END IF;

    -- 6. Insert sub and payment if not exist
    IF v_subscription_id IS NULL THEN
        INSERT INTO public.subscriptions (user_id, plan_id, status, start_date, end_date)
        VALUES (v_user_id, p_plan_id, 'pending', v_start_date, v_end_date)
        RETURNING id INTO v_subscription_id;
    END IF;

    IF v_payment_id IS NULL THEN
        INSERT INTO public.payments (user_id, subscription_id, amount, currency, status, institution_id)
        VALUES (v_user_id, v_subscription_id, v_plan.price, COALESCE(v_plan.currency, 'ARS'), 'pending', v_inst.id)
        RETURNING id INTO v_payment_id;
    END IF;

    RETURN json_build_object('alias', v_inst.payment_alias);
END;
$function$

```

### fill_profile_email
```sql
CREATE OR REPLACE FUNCTION public.fill_profile_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  if new.email is null or new.email = '' then
    select email into new.email from auth.users where id = new.id;
  end if;
  return new;
end;
$function$

```

### get_available_spots
```sql
CREATE OR REPLACE FUNCTION public.get_available_spots(p_session_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_capacity        INTEGER;
    v_confirmed_count INTEGER;
BEGIN
    SELECT capacity INTO v_capacity 
    FROM class_sessions 
    WHERE id = p_session_id;

    SELECT COUNT(*) INTO v_confirmed_count 
    FROM reservations 
    WHERE session_id = p_session_id 
    AND status = 'confirmed';

    RETURN v_capacity - v_confirmed_count;
END;
$function$

```

### get_dates_with_available_sessions
```sql
CREATE OR REPLACE FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(date text)
 LANGUAGE sql
 STABLE
AS $function$
  SELECT DISTINCT cs.date::TEXT
  FROM class_sessions cs
  WHERE cs.date BETWEEN p_from AND p_to
    AND cs.status = 'scheduled'
    AND (p_institution_id IS NULL OR cs.institution_id = p_institution_id);
$function$

```

### get_institution_mp_token
```sql
CREATE OR REPLACE FUNCTION public.get_institution_mp_token(p_institution_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_secret_name text;
  v_token text;
BEGIN
  -- Solo service_role puede ejecutar esta función
  IF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT mp_token_secret_name
    INTO v_secret_name
    FROM institutions
   WHERE id = p_institution_id;

  IF v_secret_name IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT decrypted_secret
    INTO v_token
    FROM vault.decrypted_secrets
   WHERE name = v_secret_name;

  RETURN v_token;
END;
$function$

```

### get_session_confirmed_counts
```sql
CREATE OR REPLACE FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[])
 RETURNS TABLE(session_id uuid, confirmed_count integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT session_id, COUNT(*)::INT
  FROM reservations
  WHERE session_id = ANY(p_session_ids)
    AND status = 'confirmed'
  GROUP BY session_id;
$function$

```

### handle_new_user
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, institution_id, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.email, ''),
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'client'::user_role),
    NULLIF(new.raw_user_meta_data->>'institution_id', '')::uuid,
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name      = EXCLUDED.full_name,
    email          = EXCLUDED.email,
    role           = EXCLUDED.role,
    institution_id = EXCLUDED.institution_id;
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user error: %', SQLERRM;
  RETURN new;
END;
$function$

```

### kali_institution_id
```sql
CREATE OR REPLACE FUNCTION public.kali_institution_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT coalesce(
    CASE 
      WHEN (auth.jwt() -> 'app_metadata' ->> 'role') IS NOT NULL THEN
        CASE 
          WHEN coalesce((auth.jwt() -> 'app_metadata' ->> 'is_active')::boolean, true) = true THEN
            (auth.jwt() -> 'app_metadata' ->> 'institution_id')::uuid
          ELSE NULL
        END
      ELSE NULL
    END,
    (select institution_id from profiles where id = auth.uid() and is_active)
  )
$function$

```

### kali_is_admin
```sql
CREATE OR REPLACE FUNCTION public.kali_is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT coalesce(
    CASE 
      WHEN (auth.jwt() -> 'app_metadata' ->> 'role') IS NOT NULL THEN
        coalesce((auth.jwt() -> 'app_metadata' ->> 'is_active')::boolean, true) = true 
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'sudo')
      ELSE NULL
    END,
    exists(select 1 from profiles where id = auth.uid() and is_active and role in ('admin','sudo'))
  )
$function$

```

### kali_role
```sql
CREATE OR REPLACE FUNCTION public.kali_role()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT role::text FROM profiles WHERE id = auth.uid()
$function$

```

### profiles_guard_self
```sql
CREATE OR REPLACE FUNCTION public.profiles_guard_self()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  meta_role text;
begin
  if auth.uid() is not null and new.id = auth.uid() and not public.kali_is_admin() then
    if tg_op = 'UPDATE' then
      new.role := old.role;
      new.is_active := old.is_active;
      if old.institution_id is not null then new.institution_id := old.institution_id; end if;
    elsif tg_op = 'INSERT' then
      -- Honrar el rol del metadata del signup (consistente con handle_new_user),
      -- en lugar de forzar siempre 'client'. Permite el auto-registro de un dueño (sudo).
      select raw_user_meta_data->>'role' into meta_role
        from auth.users where id = new.id;
      new.role := coalesce(meta_role::user_role, 'client'::user_role);
      new.is_active := true;
    end if;
  end if;
  return new;
end;
$function$

```

### promote_waitlist_on_cancellation
```sql
CREATE OR REPLACE FUNCTION public.promote_waitlist_on_cancellation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tz constant text := 'America/Argentina/Buenos_Aires';
  v_today       date;
  v_session     class_sessions%rowtype;
  v_class_name  text;
  v_confirmed   int;
  v_month_start date;
  v_waiter      record;
  v_limit       int;
  v_used        int;
  v_email       text;
  v_name        text;
  v_fn_url      text;
  v_secret      text;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then
    return new;
  end if;

  -- Fecha local Argentina, no current_date (UTC): entre las 21:00 y las 00:00
  -- hora local, current_date ya es "manana" y las clases de hoy quedaban fuera.
  v_today := (now() at time zone v_tz)::date;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < v_today then
    return new;
  end if;

  select count(*) into v_confirmed
  from reservations
  where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then
    return new;
  end if;

  v_class_name  := coalesce(v_session.name, 'la clase');
  v_month_start := date_trunc('month', v_session.date)::date;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    -- plan activo que cubra la fecha de la clase
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
        and cs.date >= v_month_start
        and cs.date <  v_month_start + interval '1 month';
      if v_used >= v_limit then continue; end if;
    end if;

    -- ya tenia reserva confirmada en esta sesion: limpiar la fila huerfana
    -- y seguir buscando al proximo elegible
    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- reservations NO tiene institution_id en prod: no incluir esa columna.
    -- El on conflict revive la fila cancelada si existia (UNIQUE user_id, session_id).
    insert into reservations (user_id, session_id, status)
    values (v_waiter.user_id, new.session_id, 'confirmed')
    on conflict (user_id, session_id) do update
      set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (
      v_waiter.user_id,
      '¡Conseguiste un lugar!',
      'Se liberó un lugar en ' || v_class_name || ' del '
        || to_char(v_session.date, 'DD/MM')
        || ' y ya tenés la reserva confirmada.',
      'waitlist'
    );

    -- Mail best-effort: si falla, la promocion ya quedo hecha igual.
    begin
      select email, full_name into v_email, v_name
      from profiles where id = v_waiter.user_id;

      select value into v_fn_url from private.email_config where key = 'waitlist_fn_url';
      select value into v_secret from private.email_config where key = 'waitlist_webhook_secret';

      if coalesce(v_email, '') <> ''
         and v_fn_url is not null
         and v_fn_url not like 'https://CAMBIAR%'
      then
        perform net.http_post(
          url     := v_fn_url,
          headers := jsonb_build_object(
            'Content-Type',     'application/json',
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

    -- Una cancelacion libera UN lugar: promover a uno solo y cortar.
    exit;
  end loop;

  return new;
exception when others then
  -- la promocion nunca debe impedir la cancelacion original
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$function$

```

### send_payment_reminders
```sql
CREATE OR REPLACE FUNCTION public.send_payment_reminders()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    return;
  end if;

  v_today := (now() at time zone v_tz)::date;

  for v_r in
    select s.id,
           p.email                      as email,
           p.full_name                  as name,
           coalesce(pl.name, 'tu plan') as plan_name,
           s.end_date                   as end_date
    from subscriptions s
    join profiles p on p.id = s.user_id
    left join plans pl on pl.id = s.plan_id
    where s.status = 'active'
      and s.payment_reminder_sent_at is null
      and s.end_date = v_today + 7
    for update of s skip locked
  loop
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
$function$

```

### sync_profiles_to_app_metadata
```sql
CREATE OR REPLACE FUNCTION public.sync_profiles_to_app_metadata()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Update auth.users with the role, institution_id, and is_active from profiles
  UPDATE auth.users
  SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || 
      jsonb_build_object(
        'role', NEW.role,
        'institution_id', NEW.institution_id,
        'is_active', NEW.is_active
      )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$function$

```

### update_updated_at
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$

```

### validate_profile_institution
```sql
CREATE OR REPLACE FUNCTION public.validate_profile_institution()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- El FK ya garantiza que el ID existe; acá verificamos que esté activa
  IF NEW.institution_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.institutions
      WHERE id = NEW.institution_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'institution_inactive';
    END IF;
  END IF;

  -- Una vez asignada, institution_id no puede cambiarse desde el cliente
  IF TG_OP = 'UPDATE' THEN
    IF NEW.institution_id IS DISTINCT FROM OLD.institution_id AND auth.role() = 'authenticated' THEN
      -- Solo permitimos el cambio si es a través del sistema (ej. función admin) o al inicializar
      IF OLD.institution_id IS NOT NULL THEN
        RAISE EXCEPTION 'cannot_change_institution';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$

```
