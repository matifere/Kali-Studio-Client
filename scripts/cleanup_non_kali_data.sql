-- ============================================================
--  LIMPIEZA: eliminar datos que NO pertenecen a Kali Studio
--  Ejecutar en: Supabase SQL Editor
-- ============================================================


-- ══════════════════════════════════════════════════════════════
--  PASO 1 — Obtener el UUID de Kali Studio
--  Ejecutá SOLO esta query primero y copiá el id de Kali Studio.
-- ══════════════════════════════════════════════════════════════

SELECT id, name, slug FROM institutions ORDER BY name;


-- ══════════════════════════════════════════════════════════════
--  PASO 2 — Pegá el UUID de Kali Studio en la línea de abajo
--  y ejecutá el DRY RUN para ver cuántos registros se borrarían.
-- ══════════════════════════════════════════════════════════════

-- ▼▼▼ REEMPLAZÁ el UUID en la línea de abajo con el id de Kali Studio ▼▼▼
WITH kali AS (
  SELECT 'de680a5f-b6d9-4659-88c8-12b93347d627'::uuid AS id
)

-- DRY RUN: cuenta qué se borraría (no borra nada)
SELECT 'institutions (otras)' AS tabla, COUNT(*) AS registros_a_borrar
  FROM institutions, kali
  WHERE institutions.id <> kali.id

UNION ALL

SELECT 'profiles (otros studios)', COUNT(*)
  FROM profiles, kali
  WHERE profiles.institution_id IS NOT NULL
    AND profiles.institution_id <> kali.id

UNION ALL

SELECT 'schedule_templates', COUNT(*)
  FROM schedule_templates, kali
  WHERE schedule_templates.institution_id <> kali.id

UNION ALL

SELECT 'class_sessions', COUNT(*)
  FROM class_sessions, kali
  WHERE class_sessions.institution_id <> kali.id

UNION ALL

SELECT 'reservations (via sessions)', COUNT(*)
  FROM reservations, kali
  WHERE reservations.session_id IN (
    SELECT id FROM class_sessions WHERE institution_id <> kali.id
  )

UNION ALL

SELECT 'waitlist (via sessions)', COUNT(*)
  FROM waitlist, kali
  WHERE waitlist.session_id IN (
    SELECT id FROM class_sessions WHERE institution_id <> kali.id
  )

UNION ALL

SELECT 'plans (otros studios)', COUNT(*)
  FROM plans, kali
  WHERE plans.institution_id <> kali.id

UNION ALL

SELECT 'subscriptions (via plans)', COUNT(*)
  FROM subscriptions, kali
  WHERE subscriptions.plan_id IN (
    SELECT id FROM plans WHERE institution_id <> kali.id
  )

UNION ALL

SELECT 'payments (via subscriptions)', COUNT(*)
  FROM payments, kali
  WHERE payments.subscription_id IN (
    SELECT id FROM subscriptions
    WHERE plan_id IN (
      SELECT id FROM plans WHERE institution_id <> kali.id
    )
  );


-- ══════════════════════════════════════════════════════════════
--  PASO 3 — DELETE REAL
--  Ejecutá solo después de verificar el DRY RUN.
--  Pegá el mismo UUID de Kali Studio abajo.
-- ══════════════════════════════════════════════════════════════

BEGIN;

DO $$
DECLARE
  kali_id UUID := 'de680a5f-b6d9-4659-88c8-12b93347d627';
BEGIN

  IF NOT EXISTS (SELECT 1 FROM institutions WHERE id = kali_id) THEN
    RAISE EXCEPTION 'UUID inválido: no se encontró ninguna institución con ese id. Abortando.';
  END IF;

  RAISE NOTICE 'Institución a conservar: %', (SELECT name FROM institutions WHERE id = kali_id);

  -- 1. Waitlist de sesiones de otras instituciones
  DELETE FROM waitlist
  WHERE session_id IN (
    SELECT id FROM class_sessions WHERE institution_id <> kali_id
  );
  RAISE NOTICE 'waitlist: OK';

  -- 2. Reservations de sesiones de otras instituciones
  DELETE FROM reservations
  WHERE session_id IN (
    SELECT id FROM class_sessions WHERE institution_id <> kali_id
  );
  RAISE NOTICE 'reservations: OK';

  -- 3. Class sessions de otras instituciones
  DELETE FROM class_sessions WHERE institution_id <> kali_id;
  RAISE NOTICE 'class_sessions: OK';

  -- 4. Schedule templates de otras instituciones
  DELETE FROM schedule_templates WHERE institution_id <> kali_id;
  RAISE NOTICE 'schedule_templates: OK';

  -- 5. Payments vinculados a subscriptions de otras instituciones
  DELETE FROM payments
  WHERE subscription_id IN (
    SELECT id FROM subscriptions
    WHERE plan_id IN (
      SELECT id FROM plans WHERE institution_id <> kali_id
    )
  );
  RAISE NOTICE 'payments: OK';

  -- 6. Subscriptions vinculadas a plans de otras instituciones
  DELETE FROM subscriptions
  WHERE plan_id IN (
    SELECT id FROM plans WHERE institution_id <> kali_id
  );
  RAISE NOTICE 'subscriptions: OK';

  -- 7. Plans de otras instituciones
  DELETE FROM plans WHERE institution_id <> kali_id;
  RAISE NOTICE 'plans: OK';

  -- 8. Profiles de usuarios de otras instituciones
  DELETE FROM profiles
  WHERE institution_id IS NOT NULL
    AND institution_id <> kali_id;
  RAISE NOTICE 'profiles: OK';

  -- 9. Las otras instituciones
  DELETE FROM institutions WHERE id <> kali_id;
  RAISE NOTICE 'institutions: OK';

END $$;

-- Verificación final antes de confirmar:
SELECT id, name FROM institutions;

-- Si la tabla muestra solo Kali Studio → COMMIT
-- Si algo está mal → ROLLBACK
COMMIT;
-- ROLLBACK;


-- ══════════════════════════════════════════════════════════════
--  PASO 4 — (Opcional) Listar auth.users que no son de Kali Studio
--  Borrarlos desde Authentication > Users en el dashboard de Supabase.
-- ══════════════════════════════════════════════════════════════

SELECT au.id, au.email, au.created_at
FROM auth.users au
LEFT JOIN profiles p ON p.id = au.id
  AND p.institution_id = 'de680a5f-b6d9-4659-88c8-12b93347d627'::uuid
WHERE p.id IS NULL
ORDER BY au.created_at;
