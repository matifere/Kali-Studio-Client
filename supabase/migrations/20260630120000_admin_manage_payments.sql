-- Permite que el staff (admin/sudo) elimine y edite pagos dentro de su
-- institución. Hace falta para que la app Admin pueda deshacer o editar una
-- asignación de plan: borrar una suscripción requiere antes borrar sus pagos
-- (la FK payments.subscription_id NO es ON DELETE CASCADE), y editar el plan
-- de una suscripción debe poder ajustar el monto/moneda del pago asociado.
--
-- Mismo criterio de institución que staff_read_institution_payments: el staff
-- y el alumno dueño del pago deben pertenecer a la misma institución.

drop policy if exists staff_delete_institution_payments on public.payments;
create policy staff_delete_institution_payments on public.payments
  for delete to authenticated
  using (exists (
    select 1
    from public.profiles staff
    join public.profiles student on student.id = payments.user_id
    where staff.id = auth.uid()
      and staff.role = any (array['sudo'::public.user_role, 'admin'::public.user_role])
      and staff.institution_id = student.institution_id
  ));

drop policy if exists staff_update_institution_payments on public.payments;
create policy staff_update_institution_payments on public.payments
  for update to authenticated
  using (exists (
    select 1
    from public.profiles staff
    join public.profiles student on student.id = payments.user_id
    where staff.id = auth.uid()
      and staff.role = any (array['sudo'::public.user_role, 'admin'::public.user_role])
      and staff.institution_id = student.institution_id
  ))
  with check (exists (
    select 1
    from public.profiles staff
    join public.profiles student on student.id = payments.user_id
    where staff.id = auth.uid()
      and staff.role = any (array['sudo'::public.user_role, 'admin'::public.user_role])
      and staff.institution_id = student.institution_id
  ));
