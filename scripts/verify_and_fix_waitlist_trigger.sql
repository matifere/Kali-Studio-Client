-- ============================================================
--  VERIFICACIÓN Y CORRECCIÓN DEL TRIGGER DE LISTA DE ESPERA
--  Ejecutar en: Supabase SQL Editor
-- ============================================================


-- ══════════════════════════════════════════════════════════════
--  PASO 1 — Verificar si el trigger existe y qué hace
-- ══════════════════════════════════════════════════════════════

-- 1a. ¿Existe algún trigger sobre la tabla reservations?
SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'reservations'
  AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 1b. Ver el código completo de la función del trigger (si existe)
SELECT
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname ILIKE '%waitlist%';


-- ══════════════════════════════════════════════════════════════
--  PASO 2 — Simulación del flujo (DRY RUN)
--  Encontrá una sesión con gente en waitlist y simulá la lógica
-- ══════════════════════════════════════════════════════════════

-- 2a. Sesiones que tienen gente en waitlist ahora mismo
SELECT
  w.session_id,
  cs.date,
  cs.start_time,
  COUNT(w.id)    AS personas_en_espera,
  cs.capacity,
  COUNT(r.id)    AS reservas_confirmadas,
  cs.capacity - COUNT(r.id) AS lugares_libres
FROM waitlist w
JOIN class_sessions cs ON cs.id = w.session_id
LEFT JOIN reservations r ON r.session_id = w.session_id AND r.status = 'confirmed'
WHERE w.status = 'waiting'
GROUP BY w.session_id, cs.date, cs.start_time, cs.capacity
ORDER BY cs.date;

-- 2b. Para cada persona en waitlist: ¿puede ser promovida?
--     Muestra: tiene plan activo, cuántas clases usó esa semana, cuál es su límite
WITH waitlist_candidates AS (
  SELECT
    w.id           AS waitlist_id,
    w.user_id,
    w.session_id,
    w.created_at,
    cs.date        AS session_date,
    date_trunc('week', cs.date)::date                    AS week_start,
    (date_trunc('week', cs.date) + interval '6 days')::date AS week_end
  FROM waitlist w
  JOIN class_sessions cs ON cs.id = w.session_id
  WHERE w.status = 'waiting'
),
plan_info AS (
  SELECT
    wc.waitlist_id,
    wc.user_id,
    wc.session_id,
    wc.session_date,
    wc.week_start,
    wc.week_end,
    wc.created_at,
    EXISTS(
      SELECT 1 FROM subscriptions s
      WHERE s.user_id = wc.user_id
        AND s.status = 'active'
        AND s.start_date <= wc.session_date
        AND s.end_date   >= wc.session_date
    ) AS tiene_plan_activo,
    (
      SELECT p.max_reservations_per_week
      FROM subscriptions s
      JOIN plans p ON p.id = s.plan_id
      WHERE s.user_id = wc.user_id
        AND s.status = 'active'
        AND s.start_date <= wc.session_date
        AND s.end_date   >= wc.session_date
      LIMIT 1
    ) AS limite_semanal,
    (
      SELECT COUNT(*)
      FROM reservations r
      JOIN class_sessions cs2 ON cs2.id = r.session_id
      WHERE r.user_id  = wc.user_id
        AND r.status   = 'confirmed'
        AND cs2.date  >= wc.week_start
        AND cs2.date  <= wc.week_end
    ) AS clases_usadas_esa_semana
  FROM waitlist_candidates wc
)
SELECT
  waitlist_id,
  user_id,
  session_id,
  session_date,
  week_start,
  week_end,
  tiene_plan_activo,
  clases_usadas_esa_semana,
  limite_semanal,
  CASE
    WHEN NOT tiene_plan_activo              THEN 'NO — sin plan activo'
    WHEN limite_semanal IS NULL             THEN 'SÍ — plan sin límite'
    WHEN clases_usadas_esa_semana < limite_semanal THEN 'SÍ — bajo el límite'
    ELSE                                         'NO — límite semanal alcanzado'
  END AS puede_ser_promovida
FROM plan_info
ORDER BY session_id, created_at;


-- ══════════════════════════════════════════════════════════════
--  PASO 3 — Crear (o reemplazar) el trigger correcto
--  Ejecutá esto si el trigger no existe o tiene lógica incorrecta.
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.promote_waitlist_on_cancellation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session_date   DATE;
  v_week_start     DATE;
  v_week_end       DATE;
  v_next_uid       UUID;
  v_next_wid       UUID;
  v_has_plan       BOOLEAN;
  v_weekly_limit   INT;
  v_weekly_used    INT;
BEGIN
  -- Solo actuar cuando el status cambia a 'cancelled'
  IF NEW.status <> 'cancelled' OR OLD.status = 'cancelled' THEN
    RETURN NEW;
  END IF;

  -- Obtener la fecha de la sesión cancelada
  SELECT cs.date INTO v_session_date
  FROM class_sessions cs
  WHERE cs.id = NEW.session_id;

  IF v_session_date IS NULL THEN
    RETURN NEW;
  END IF;

  -- Semana de lunes a domingo que contiene la sesión
  v_week_start := date_trunc('week', v_session_date)::date;
  v_week_end   := v_week_start + 6;

  -- Iterar la waitlist en orden de inscripción (FIFO)
  FOR v_next_wid, v_next_uid IN
    SELECT w.id, w.user_id
    FROM waitlist w
    WHERE w.session_id = NEW.session_id
      AND w.status = 'waiting'
    ORDER BY w.created_at ASC
  LOOP
    -- ¿Tiene plan activo válido para la fecha de la sesión?
    SELECT EXISTS(
      SELECT 1 FROM subscriptions s
      WHERE s.user_id    = v_next_uid
        AND s.status     = 'active'
        AND s.start_date <= v_session_date
        AND s.end_date   >= v_session_date
    ) INTO v_has_plan;

    IF NOT v_has_plan THEN
      CONTINUE;  -- Sin plan: pasar al siguiente en la lista
    END IF;

    -- Límite semanal de su plan
    SELECT p.max_reservations_per_week INTO v_weekly_limit
    FROM subscriptions s
    JOIN plans p ON p.id = s.plan_id
    WHERE s.user_id    = v_next_uid
      AND s.status     = 'active'
      AND s.start_date <= v_session_date
      AND s.end_date   >= v_session_date
    ORDER BY s.end_date DESC
    LIMIT 1;

    -- Clases confirmadas esa semana (excluyendo la sesión que se liberó)
    SELECT COUNT(*) INTO v_weekly_used
    FROM reservations r
    JOIN class_sessions cs ON cs.id = r.session_id
    WHERE r.user_id  = v_next_uid
      AND r.status   = 'confirmed'
      AND cs.date   >= v_week_start
      AND cs.date   <= v_week_end;

    -- ¿Está bajo el límite (o el plan no tiene límite)?
    IF v_weekly_limit IS NULL OR v_weekly_used < v_weekly_limit THEN

      -- Crear la reserva confirmada
      INSERT INTO reservations (user_id, session_id, status, created_at)
      VALUES (v_next_uid, NEW.session_id, 'confirmed', now());

      -- Eliminar de la waitlist
      DELETE FROM waitlist WHERE id = v_next_wid;

      -- Notificar al usuario dentro de la app
      INSERT INTO notifications (user_id, type, title, body, is_read, created_at)
      VALUES (
        v_next_uid,
        'waitlist',
        'Lugar disponible',
        'Se liberó un lugar y te inscribimos automáticamente en la clase.',
        false,
        now()
      );

      EXIT;  -- Promover solo al primero que califica
    END IF;
    -- Si está al límite: probar con el siguiente de la lista
  END LOOP;

  RETURN NEW;
END;
$$;

-- Registrar el trigger (reemplaza si ya existía)
DROP TRIGGER IF EXISTS trg_promote_waitlist ON public.reservations;

CREATE TRIGGER trg_promote_waitlist
  AFTER UPDATE OF status ON public.reservations
  FOR EACH ROW
  EXECUTE FUNCTION public.promote_waitlist_on_cancellation();


-- ══════════════════════════════════════════════════════════════
--  PASO 4 — Test de integración en una transacción con ROLLBACK
--  Simula el flujo completo y muestra el resultado sin guardar nada.
--  Para correr esto necesitás conocer un session_id y dos user_id reales.
-- ══════════════════════════════════════════════════════════════

/*
  Reemplazá los valores de abajo con datos reales de tu BD:

  v_session_id  → una sesión futura con al menos 1 reserva confirmada
  v_user_cancel → el user_id que tiene la reserva y va a cancelar
  v_user_wait   → el user_id que está en la waitlist para esa sesión
*/

DO $$
DECLARE
  v_session_id  UUID := 'PEGAR-SESSION-ID-AQUI';
  v_user_cancel UUID := 'PEGAR-USER-ID-QUE-CANCELA';
  v_user_wait   UUID := 'PEGAR-USER-ID-EN-WAITLIST';

  v_reservation_id UUID;
  v_result TEXT;
BEGIN
  RAISE NOTICE '=== INICIO DEL TEST DE LISTA DE ESPERA ===';

  -- Estado inicial
  RAISE NOTICE 'Reservas confirmadas antes: %', (
    SELECT COUNT(*) FROM reservations WHERE session_id = v_session_id AND status = 'confirmed'
  );
  RAISE NOTICE 'Personas en waitlist antes: %', (
    SELECT COUNT(*) FROM waitlist WHERE session_id = v_session_id AND status = 'waiting'
  );

  -- Obtener la reservation del usuario que cancela
  SELECT id INTO v_reservation_id
  FROM reservations
  WHERE session_id = v_session_id
    AND user_id = v_user_cancel
    AND status = 'confirmed'
  LIMIT 1;

  IF v_reservation_id IS NULL THEN
    RAISE EXCEPTION 'No se encontró reserva confirmada para ese usuario y sesión.';
  END IF;

  RAISE NOTICE 'Cancelando reserva ID: %', v_reservation_id;

  -- Cancelar la reserva (esto debería disparar el trigger)
  UPDATE reservations
  SET status = 'cancelled', cancelled_at = now()
  WHERE id = v_reservation_id;

  -- Estado post-trigger
  RAISE NOTICE '--- Estado post-cancelación ---';
  RAISE NOTICE 'Reservas confirmadas después: %', (
    SELECT COUNT(*) FROM reservations WHERE session_id = v_session_id AND status = 'confirmed'
  );
  RAISE NOTICE 'Personas en waitlist después: %', (
    SELECT COUNT(*) FROM waitlist WHERE session_id = v_session_id AND status = 'waiting'
  );

  -- ¿Se promovió el usuario de la waitlist?
  IF EXISTS (
    SELECT 1 FROM reservations
    WHERE session_id = v_session_id
      AND user_id = v_user_wait
      AND status = 'confirmed'
  ) THEN
    RAISE NOTICE 'RESULTADO: ✓ El usuario de waitlist fue promovido exitosamente.';
  ELSE
    RAISE NOTICE 'RESULTADO: ✗ El usuario de waitlist NO fue promovido. Revisá el trigger.';
  END IF;

  -- ¿Se creó la notificación?
  IF EXISTS (
    SELECT 1 FROM notifications
    WHERE user_id = v_user_wait
      AND type = 'waitlist'
      AND created_at >= now() - interval '5 seconds'
  ) THEN
    RAISE NOTICE 'NOTIFICACIÓN: ✓ Creada correctamente.';
  ELSE
    RAISE NOTICE 'NOTIFICACIÓN: ✗ No se creó (la tabla notifications puede no tener la columna esperada).';
  END IF;

  -- Revertir todo para no afectar datos reales
  ROLLBACK;
  RAISE NOTICE '=== TEST COMPLETADO — Todos los cambios revertidos (ROLLBACK) ===';
END $$;
