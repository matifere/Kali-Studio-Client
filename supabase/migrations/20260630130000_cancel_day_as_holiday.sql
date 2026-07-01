-- Feriados: cancelar todas las clases de un día y devolver el crédito a cada alumno.
--
-- El admin elige una fecha y esta función, de forma atómica (todo o nada):
--   1. Cancela las class_sessions de ese día de su institución (status -> 'cancelled').
--      El cliente solo muestra clases 'scheduled', así que desaparecen de la reserva.
--   2. Cancela las reservas 'confirmed' de esas sesiones. Como el conteo mensual solo
--      cuenta reservas 'confirmed', el crédito vuelve solo y NO se toma como clase
--      perdida: el alumno puede volver a reservar otra clase ese mes.
--   3. Notifica a cada alumno afectado (el INSERT en notifications dispara el push a
--      iOS/Android vía el trigger trg_send_push).
--   4. Limpia la lista de espera de esas sesiones (la clase ya no existe).
--
-- Orden importante: se cancela la SESIÓN antes que las reservas. Así el trigger
-- promote_waitlist_on_cancellation ve la sesión en 'cancelled' (no 'scheduled') y no
-- promueve a nadie a una clase que ya es feriado.

create or replace function public.cancel_day_as_holiday(p_date date, p_reason text default null)
returns json
language plpgsql
security definer
set search_path = public
as $fn$
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
$fn$;

grant execute on function public.cancel_day_as_holiday(date, text) to authenticated;
