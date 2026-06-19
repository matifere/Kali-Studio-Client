# Kali Studio — Contexto del proyecto

> Este archivo se carga automáticamente en cada chat de Claude Code dentro de este repo.
> Mantenelo actualizado cuando cambie el esquema, los roles o la relación entre apps.

## Ecosistema (2 apps, 1 base de datos)

Hay **dos apps Flutter** que comparten **un único proyecto Supabase**:

- **Proyecto Supabase:** "Kali Studio" · ref `tmfcnvtjzmtpqhzvfxos`
- **Producto:** SaaS multi-tenant (marca **Argity**) para estudios de Pilates. Cada estudio es un *tenant* = `institution`. **Todos los datos están scopeados por `institution_id`** vía RLS.

| Repo | Paquete | Quién lo usa | Plataformas | Stack UI |
|------|---------|--------------|-------------|----------|
| **Kali-Studio-Client** (este) | `kali_studio` | Alumnos | Android/iOS + Web | setState, Firebase push |
| **Kali-Studio-Admin** | `argrity` | Dueños/entrenadores del estudio | Desktop/Web | `flutter_bloc` |

- **Este repo (Client):** reservar/cancelar clases, lista de espera, ver planes, perfil, notificaciones push.
- **Admin** (`C:\Users\ghian\Documentos\Kali-Studio-Admin`): gestionar alumnos, turnos (horarios), planes, pagos, y la **suscripción SaaS del estudio** (cobro vía MercadoPago).

## Base de datos (compartida entre ambas apps)

Schema `public`, todo tenant-scoped por `institution_id` con RLS. *(Derivado de `supabase/migrations` y del código; verificá columnas exactas antes de asumir.)*

- **profiles** — usuarios. `id` (= `auth.uid()`), `email`, `full_name`, `role` (`client` | `admin` | `sudo`), `is_active`, `institution_id`. Trigger `profiles_guard_self` impide que un no-admin cambie su propio `role`/`is_active`/`institution_id`.
- **institutions** — tenants (estudios).
- **class_sessions** — clases agendadas (turnos). `capacity`, `date`, `start_time`, `status` (`scheduled` | …), `template_id`, `name`, `institution_id`.
- **schedule_templates** — plantillas de clases recurrentes.
- **reservations** — reservas. `user_id`, `session_id`, `status` (`confirmed` | `cancelled`), `cancelled_at`, `cancelled_by`, `institution_id`. Único `(user_id, session_id)`.
- **waitlist** — lista de espera. `user_id`, `session_id`, `status` (`waiting`), `created_at` (orden FIFO).
- **plans** — planes de membresía. `max_reservations_per_month` (era `per_week` hasta la migración del 2026-06-18), `institution_id`.
- **subscriptions** — suscripción de un alumno a un plan. `user_id`, `plan_id`, `status` (`active`), `start_date`, `end_date`, `institution_id`.
- **payments** — registros de pago.
- **notifications** — notificaciones in-app. `user_id`, `title`, `body`, `type`. Trigger `send_push_on_notification` dispara el push.
- **mobile_push_tokens** / **push_subscriptions** — tokens FCM (mobile) y suscripciones web push.
- **saas_plans** / **tenant_subscriptions** — planes y suscripción SaaS del estudio (los usa Admin; gatean el acceso al panel).
- **private.email_config** — key/value (URLs de funciones, secrets de webhooks) para las edge functions de email.
- Storage: bucket **`avatars`**.

### RPCs / funciones clave
- **`book_session_if_available(p_session_id, p_user_id)`** — `SECURITY DEFINER`. Valida tenant, identidad (anti-IDOR/cross-tenant), usuario activo, capacidad, plan activo y **límite mensual**; inserta la reserva `confirmed`. **El cliente reserva SOLO por este RPC** (el insert directo en `reservations` es admin-only por RLS).
- **`promote_waitlist_on_cancellation()`** — trigger. Al cancelar, promueve al primer alumno en espera elegible (FIFO, respeta el límite mensual), lo notifica y le manda email.
- **`kali_institution_id()`**, **`kali_is_admin()`** — helpers de RLS.
- `send_class_reminders()`, `fill_profile_email()`.

### Modelo de autorización
Escribir en `class_sessions` / `plans` / `schedule_templates` / `subscriptions` / `reservations` (insert directo) / borrar `profiles` requiere `kali_is_admin()` (role `admin`/`sudo` y activo). Las lecturas se limitan a datos propios o, si sos admin, a toda tu institución.

### Edge functions (en `supabase/functions/` de este repo)
`create-preference` (MercadoPago), `delete-account`, `send-class-reminder`, `send-push`, `send-waitlist-email`.

> ⚠️ **Las migraciones del esquema viven SOLO en este repo** (`supabase/migrations/`, con timestamp). Admin no tiene carpeta `migrations`. Cualquier cambio de DB va acá.

## Convenciones
- Flutter/Dart, SDK `>=3.0.0 <4.0.0`, `supabase_flutter ^2.12`. UI y comentarios en **español**.
- Servicios de datos en `lib/supabase/*`. Firebase push en `lib/services/*` (con stub web vs impl mobile).
- Credenciales Supabase: por `--dart-define` (web) o `.env` (mobile). **Nunca** commitear secrets ni el `.env`.
