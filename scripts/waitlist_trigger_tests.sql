-- ============================================================
--  TESTS DE INTEGRACIÓN — trigger promote_from_waitlist
--  Ejecutar en: Supabase SQL Editor (service role)
--
--  Cada test usa BEGIN...EXCEPTION...END para aislarse:
--  si el test PASA → limpia sus datos manualmente.
--  si el test FALLA → el implicit savepoint revierte todo.
--  El ROLLBACK final borra cualquier dato compartido.
-- ============================================================

BEGIN;

DO $$
DECLARE
  v_inst_id UUID := 'de680a5f-b6d9-4659-88c8-12b93347d627';

  -- Usuarios reales de la BD (se obtienen al inicio)
  v_user_a UUID;   -- quien cancela
  v_user_b UUID;   -- 1er candidato en waitlist
  v_user_c UUID;   -- 2do candidato en waitlist

  -- Recursos compartidos entre tests
  v_tmpl_id           UUID := gen_random_uuid();
  v_plan_limited_id   UUID := gen_random_uuid(); -- 2 clases/semana
  v_plan_unlimited_id UUID := gen_random_uuid(); -- sin límite semanal

  -- Variables por test
  v_session_id UUID;
  v_res_a_id   UUID;
  v_class_date DATE := CURRENT_DATE + 7; -- clase la próxima semana

  -- Semana de la clase (lunes a domingo)
  v_week_start DATE;
  v_week_end   DATE;

  -- Contadores
  v_passed INT := 0;
  v_failed INT := 0;

BEGIN
  -- ──────────────────────────────────────────────────────────
  --  Obtener 3 usuarios reales de la BD
  -- ──────────────────────────────────────────────────────────
  SELECT id INTO v_user_a
  FROM profiles WHERE institution_id = v_inst_id ORDER BY created_at ASC LIMIT 1 OFFSET 0;
  SELECT id INTO v_user_b
  FROM profiles WHERE institution_id = v_inst_id ORDER BY created_at ASC LIMIT 1 OFFSET 1;
  SELECT id INTO v_user_c
  FROM profiles WHERE institution_id = v_inst_id ORDER BY created_at ASC LIMIT 1 OFFSET 2;

  IF v_user_a IS NULL OR v_user_b IS NULL OR v_user_c IS NULL THEN
    RAISE EXCEPTION 'Se necesitan al menos 3 usuarios con institution_id = %. Actualmente hay menos.', v_inst_id;
  END IF;

  RAISE NOTICE '════════════════════════════════════════';
  RAISE NOTICE ' TESTS WAITLIST TRIGGER';
  RAISE NOTICE ' Users: A=%, B=%, C=%', v_user_a, v_user_b, v_user_c;
  RAISE NOTICE '════════════════════════════════════════';

  -- Semana que contiene v_class_date
  v_week_start := DATE_TRUNC('week', v_class_date)::DATE;
  v_week_end   := v_week_start + 6;

  -- ──────────────────────────────────────────────────────────
  --  Setup compartido: schedule_template y planes
  -- ──────────────────────────────────────────────────────────
  INSERT INTO schedule_templates (id, name, description, instructor_name, institution_id)
  VALUES (v_tmpl_id, 'TEST Reformer', 'Clase de prueba', 'Test Instructor', v_inst_id);

  INSERT INTO plans (id, name, description, price, currency, institution_id, max_reservations_per_week, is_active)
  VALUES
    (v_plan_limited_id,   'TEST Plan 2/semana', 'test', 0, 'ARS', v_inst_id, 2,    true),
    (v_plan_unlimited_id, 'TEST Plan ilimitado', 'test', 0, 'ARS', v_inst_id, NULL, true);


  -- ══════════════════════════════════════════════════════════
  --  TC-1: HAPPY PATH
  --  User B tiene plan activo con límite 2, usó 0 clases esa semana.
  --  User A cancela → trigger promueve a User B.
  --  Verifica: reserva confirmada, eliminado de waitlist, notificación.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
    VALUES (v_session_id, v_inst_id, v_tmpl_id, v_class_date, '10:00', '11:00', 1, 'scheduled');

    INSERT INTO reservations (user_id, session_id, status)
    VALUES (v_user_a, v_session_id, 'confirmed')
    RETURNING id INTO v_res_a_id;

    INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
    VALUES (v_user_b, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

    INSERT INTO waitlist (user_id, session_id, status, created_at)
    VALUES (v_user_b, v_session_id, 'waiting', NOW());

    -- Acción: User A cancela → trigger debe disparar
    UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

    -- Cleanup manual (test pasó hasta acá sin error)
    DELETE FROM notifications WHERE user_id = v_user_b AND type = 'waitlist';
    DELETE FROM reservations  WHERE session_id = v_session_id;
    DELETE FROM waitlist      WHERE session_id = v_session_id;
    DELETE FROM subscriptions WHERE user_id = v_user_b AND plan_id = v_plan_limited_id;
    DELETE FROM class_sessions WHERE id = v_session_id;

    -- Assertions (después del cleanup para que el rollback las deshaga si fallan)
    IF NOT (
      -- reserva confirmada para B
      EXISTS (SELECT 1 FROM reservations WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed')
      -- ya no está en waitlist
      AND NOT EXISTS (SELECT 1 FROM waitlist WHERE user_id = v_user_b AND session_id = v_session_id)
      -- notificación creada
      AND EXISTS (SELECT 1 FROM notifications WHERE user_id = v_user_b AND type = 'waitlist')
    ) THEN
      RAISE EXCEPTION 'assertion failed';
    END IF;

    v_passed := v_passed + 1;
    RAISE NOTICE 'PASS TC-1 Happy path: User B promovido, waitlist limpia, notificación creada';
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-1 Happy path: %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-2: FIFO — 1er candidato SIN plan, 2do CON plan
  --  User B no tiene suscripción activa → se salta.
  --  User C sí tiene plan activo → se promueve.
  --  Verifica: B sigue en waitlist, C tiene reserva confirmada.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
    VALUES (v_session_id, v_inst_id, v_tmpl_id, v_class_date, '10:00', '11:00', 1, 'scheduled');

    INSERT INTO reservations (user_id, session_id, status)
    VALUES (v_user_a, v_session_id, 'confirmed')
    RETURNING id INTO v_res_a_id;

    -- User B: sin suscripción activa (no se inserta)
    -- User C: con plan activo
    INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
    VALUES (v_user_c, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

    -- Waitlist: B primero, C segundo (B se anotó antes)
    INSERT INTO waitlist (user_id, session_id, status, created_at)
    VALUES
      (v_user_b, v_session_id, 'waiting', NOW() - interval '5 minutes'),
      (v_user_c, v_session_id, 'waiting', NOW());

    UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

    -- Cleanup
    DELETE FROM notifications WHERE user_id IN (v_user_b, v_user_c) AND type = 'waitlist';
    DELETE FROM reservations  WHERE session_id = v_session_id;
    DELETE FROM waitlist      WHERE session_id = v_session_id;
    DELETE FROM subscriptions WHERE user_id = v_user_c AND plan_id = v_plan_limited_id;
    DELETE FROM class_sessions WHERE id = v_session_id;

    IF NOT (
      EXISTS     (SELECT 1 FROM reservations WHERE user_id = v_user_c AND session_id = v_session_id AND status = 'confirmed')
      AND NOT EXISTS (SELECT 1 FROM reservations WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed')
      AND EXISTS     (SELECT 1 FROM waitlist WHERE user_id = v_user_b AND session_id = v_session_id)
    ) THEN
      RAISE EXCEPTION 'assertion failed';
    END IF;

    v_passed := v_passed + 1;
    RAISE NOTICE 'PASS TC-2 FIFO sin plan: User B (sin plan) salteado, User C promovido';
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-2 FIFO sin plan: %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-3: LÍMITE SEMANAL ALCANZADO — único candidato
  --  User B tiene plan de 2 clases/semana y ya tiene 2 confirmadas
  --  en la misma semana de la clase → no se promueve nadie.
  --  Verifica: B sigue en waitlist, sin nueva reserva.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    -- Dos sesiones extra para simular que B ya usó sus 2 cupos
    DECLARE
      v_extra_s1 UUID := gen_random_uuid();
      v_extra_s2 UUID := gen_random_uuid();
    BEGIN
      INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
      VALUES
        (v_session_id, v_inst_id, v_tmpl_id, v_class_date,        '10:00', '11:00', 1, 'scheduled'),
        (v_extra_s1,   v_inst_id, v_tmpl_id, v_week_start,         '08:00', '09:00', 5, 'scheduled'),
        (v_extra_s2,   v_inst_id, v_tmpl_id, v_week_start + 1,     '08:00', '09:00', 5, 'scheduled');

      INSERT INTO reservations (user_id, session_id, status)
      VALUES (v_user_a, v_session_id, 'confirmed')
      RETURNING id INTO v_res_a_id;

      -- User B ya tiene 2 reservas confirmadas esa semana (llegó al límite)
      INSERT INTO reservations (user_id, session_id, status)
      VALUES
        (v_user_b, v_extra_s1, 'confirmed'),
        (v_user_b, v_extra_s2, 'confirmed');

      INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
      VALUES (v_user_b, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

      INSERT INTO waitlist (user_id, session_id, status, created_at)
      VALUES (v_user_b, v_session_id, 'waiting', NOW());

      UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

      -- Cleanup
      DELETE FROM notifications WHERE user_id = v_user_b AND type = 'waitlist';
      DELETE FROM reservations  WHERE session_id IN (v_session_id, v_extra_s1, v_extra_s2) AND user_id = v_user_b;
      DELETE FROM reservations  WHERE id = v_res_a_id;
      DELETE FROM waitlist      WHERE session_id = v_session_id;
      DELETE FROM subscriptions WHERE user_id = v_user_b AND plan_id = v_plan_limited_id;
      DELETE FROM class_sessions WHERE id IN (v_session_id, v_extra_s1, v_extra_s2);

      IF NOT (
        NOT EXISTS (SELECT 1 FROM reservations WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed')
        AND EXISTS (SELECT 1 FROM waitlist WHERE user_id = v_user_b AND session_id = v_session_id)
      ) THEN
        RAISE EXCEPTION 'assertion failed';
      END IF;

      v_passed := v_passed + 1;
      RAISE NOTICE 'PASS TC-3 Límite alcanzado (único): User B no promovido, sigue en waitlist';
    END;
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-3 Límite alcanzado (único): %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-4: FIFO — 1er candidato al límite, 2do bajo el límite
  --  User B está al límite semanal → se salta.
  --  User C está bajo el límite → se promueve.
  --  Verifica: B sigue en waitlist, C tiene reserva confirmada.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    DECLARE
      v_extra_s1 UUID := gen_random_uuid();
      v_extra_s2 UUID := gen_random_uuid();
    BEGIN
      INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
      VALUES
        (v_session_id, v_inst_id, v_tmpl_id, v_class_date,    '10:00', '11:00', 1, 'scheduled'),
        (v_extra_s1,   v_inst_id, v_tmpl_id, v_week_start,     '08:00', '09:00', 5, 'scheduled'),
        (v_extra_s2,   v_inst_id, v_tmpl_id, v_week_start + 1, '08:00', '09:00', 5, 'scheduled');

      INSERT INTO reservations (user_id, session_id, status)
      VALUES (v_user_a, v_session_id, 'confirmed')
      RETURNING id INTO v_res_a_id;

      -- User B: al límite de 2 clases esa semana
      INSERT INTO reservations (user_id, session_id, status)
      VALUES
        (v_user_b, v_extra_s1, 'confirmed'),
        (v_user_b, v_extra_s2, 'confirmed');

      INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
      VALUES
        (v_user_b, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25),
        -- User C: 0 clases esa semana
        (v_user_c, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

      -- B primero, C segundo
      INSERT INTO waitlist (user_id, session_id, status, created_at)
      VALUES
        (v_user_b, v_session_id, 'waiting', NOW() - interval '10 minutes'),
        (v_user_c, v_session_id, 'waiting', NOW());

      UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

      -- Cleanup
      DELETE FROM notifications WHERE user_id IN (v_user_b, v_user_c) AND type = 'waitlist';
      DELETE FROM reservations  WHERE session_id IN (v_session_id, v_extra_s1, v_extra_s2) AND user_id IN (v_user_b, v_user_c);
      DELETE FROM reservations  WHERE id = v_res_a_id;
      DELETE FROM waitlist      WHERE session_id = v_session_id;
      DELETE FROM subscriptions WHERE user_id IN (v_user_b, v_user_c) AND plan_id = v_plan_limited_id;
      DELETE FROM class_sessions WHERE id IN (v_session_id, v_extra_s1, v_extra_s2);

      IF NOT (
        -- C promovido
        EXISTS (SELECT 1 FROM reservations WHERE user_id = v_user_c AND session_id = v_session_id AND status = 'confirmed')
        -- B sigue en waitlist
        AND EXISTS (SELECT 1 FROM waitlist WHERE user_id = v_user_b AND session_id = v_session_id)
        -- B no fue promovido
        AND NOT EXISTS (SELECT 1 FROM reservations WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed')
      ) THEN
        RAISE EXCEPTION 'assertion failed';
      END IF;

      v_passed := v_passed + 1;
      RAISE NOTICE 'PASS TC-4 FIFO con límite: User B (al límite) salteado, User C promovido';
    END;
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-4 FIFO con límite: %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-5: PLAN SIN LÍMITE SEMANAL (max_reservations_per_week IS NULL)
  --  User B ya tiene 10 clases esa semana pero su plan es ilimitado.
  --  Verifica: se promueve igual.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    DECLARE
      v_extra_ids UUID[] := ARRAY[
        gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
        gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
        gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), gen_random_uuid()
      ];
      v_extra_id UUID;
      v_day_offset INT := 0;
    BEGIN
      INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
      VALUES (v_session_id, v_inst_id, v_tmpl_id, v_class_date, '10:00', '11:00', 1, 'scheduled');

      -- Crear 10 sesiones extra en la misma semana
      FOREACH v_extra_id IN ARRAY v_extra_ids LOOP
        INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
        VALUES (v_extra_id, v_inst_id, v_tmpl_id,
                v_week_start + (v_day_offset % 7),
                '08:00', '09:00', 20, 'scheduled');
        INSERT INTO reservations (user_id, session_id, status)
        VALUES (v_user_b, v_extra_id, 'confirmed');
        v_day_offset := v_day_offset + 1;
      END LOOP;

      INSERT INTO reservations (user_id, session_id, status)
      VALUES (v_user_a, v_session_id, 'confirmed')
      RETURNING id INTO v_res_a_id;

      -- User B: plan ilimitado
      INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
      VALUES (v_user_b, v_plan_unlimited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

      INSERT INTO waitlist (user_id, session_id, status, created_at)
      VALUES (v_user_b, v_session_id, 'waiting', NOW());

      UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

      -- Cleanup
      DELETE FROM notifications WHERE user_id = v_user_b AND type = 'waitlist';
      DELETE FROM reservations  WHERE user_id = v_user_b AND session_id = ANY(v_extra_ids);
      DELETE FROM reservations  WHERE session_id = v_session_id;
      DELETE FROM waitlist      WHERE session_id = v_session_id;
      DELETE FROM subscriptions WHERE user_id = v_user_b AND plan_id = v_plan_unlimited_id;
      DELETE FROM class_sessions WHERE id = ANY(v_extra_ids);
      DELETE FROM class_sessions WHERE id = v_session_id;

      IF NOT EXISTS (
        SELECT 1 FROM reservations
        WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed'
      ) THEN
        RAISE EXCEPTION 'assertion failed';
      END IF;

      v_passed := v_passed + 1;
      RAISE NOTICE 'PASS TC-5 Plan ilimitado: User B promovido con 10 clases en la semana';
    END;
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-5 Plan ilimitado: %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-6: WAITLIST VACÍA
  --  Nadie en waitlist. User A cancela.
  --  Verifica: la cancelación se procesa sin error, nada más cambia.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
    VALUES (v_session_id, v_inst_id, v_tmpl_id, v_class_date, '10:00', '11:00', 1, 'scheduled');

    INSERT INTO reservations (user_id, session_id, status)
    VALUES (v_user_a, v_session_id, 'confirmed')
    RETURNING id INTO v_res_a_id;

    -- No hay nadie en waitlist para esta sesión

    UPDATE reservations SET status = 'cancelled', cancelled_at = NOW() WHERE id = v_res_a_id;

    -- Cleanup
    DELETE FROM reservations WHERE session_id = v_session_id;
    DELETE FROM class_sessions WHERE id = v_session_id;

    IF EXISTS (SELECT 1 FROM reservations WHERE session_id = v_session_id AND status = 'confirmed') THEN
      RAISE EXCEPTION 'assertion failed: se creó una reserva sin haber waitlist';
    END IF;

    v_passed := v_passed + 1;
    RAISE NOTICE 'PASS TC-6 Waitlist vacía: cancelación procesada sin error, sin reservas nuevas';
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-6 Waitlist vacía: %', SQLERRM;
  END;


  -- ══════════════════════════════════════════════════════════
  --  TC-7: TRIGGER NO ACTÚA EN RESERVA YA CANCELADA
  --  OLD.status ya era 'cancelled' → el guard del trigger la ignora.
  --  Verifica: User B (en waitlist) NO se promueve.
  -- ══════════════════════════════════════════════════════════
  BEGIN
    v_session_id := gen_random_uuid();

    INSERT INTO class_sessions (id, institution_id, template_id, date, start_time, end_time, capacity, status)
    VALUES (v_session_id, v_inst_id, v_tmpl_id, v_class_date, '10:00', '11:00', 2, 'scheduled');

    -- Reserva ya cancelada previamente (OLD.status = 'cancelled')
    INSERT INTO reservations (user_id, session_id, status, cancelled_at)
    VALUES (v_user_a, v_session_id, 'cancelled', NOW() - interval '1 hour')
    RETURNING id INTO v_res_a_id;

    INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date)
    VALUES (v_user_b, v_plan_limited_id, 'active', CURRENT_DATE - 5, CURRENT_DATE + 25);

    INSERT INTO waitlist (user_id, session_id, status, created_at)
    VALUES (v_user_b, v_session_id, 'waiting', NOW());

    -- Actualizar sólo cancelled_at (OLD.status ya era 'cancelled' → guard del trigger)
    UPDATE reservations
    SET cancelled_at = NOW()
    WHERE id = v_res_a_id;

    -- Cleanup
    DELETE FROM notifications WHERE user_id = v_user_b AND type = 'waitlist';
    DELETE FROM reservations  WHERE session_id = v_session_id;
    DELETE FROM waitlist      WHERE session_id = v_session_id;
    DELETE FROM subscriptions WHERE user_id = v_user_b AND plan_id = v_plan_limited_id;
    DELETE FROM class_sessions WHERE id = v_session_id;

    IF EXISTS (
      SELECT 1 FROM reservations
      WHERE user_id = v_user_b AND session_id = v_session_id AND status = 'confirmed'
    ) THEN
      RAISE EXCEPTION 'assertion failed: trigger actuó sobre reserva ya cancelada';
    END IF;

    v_passed := v_passed + 1;
    RAISE NOTICE 'PASS TC-7 Re-cancelación: trigger ignoró correctamente el UPDATE (OLD ya era cancelled)';
  EXCEPTION WHEN others THEN
    v_failed := v_failed + 1;
    RAISE NOTICE 'FAIL TC-7 Re-cancelación: %', SQLERRM;
  END;


  -- ──────────────────────────────────────────────────────────
  --  Resumen final
  -- ──────────────────────────────────────────────────────────
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════';
  RAISE NOTICE ' RESULTADOS FINALES';
  RAISE NOTICE ' ✓ Pasaron : %/7', v_passed;
  RAISE NOTICE ' ✗ Fallaron: %/7', v_failed;
  RAISE NOTICE '════════════════════════════════════════';

  IF v_failed > 0 THEN
    RAISE NOTICE 'Revisá los FAIL anteriores para ver qué falló.';
  ELSE
    RAISE NOTICE 'Todos los tests pasaron. El trigger funciona correctamente.';
  END IF;

END $$;

ROLLBACK;  -- Revierte TODO: datos de prueba, planes, template compartido
