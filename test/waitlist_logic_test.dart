import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/models/models.dart';
import 'package:kali_studio/supabase/waitlist_service.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

PilatesClass makeClass({
  int totalSpots = 10,
  int takenSpots = 0,
  bool isBooked = false,
  bool isInWaitlist = false,
  String? waitlistId,
}) =>
    PilatesClass(
      id: 'session-1',
      name: 'Reformer',
      instructor: 'Ana García',
      time: '10:00',
      period: 'AM',
      room: 'A',
      level: 'Intermedio',
      durationMin: 55,
      totalSpots: totalSpots,
      takenSpots: takenSpots,
      equipment: '',
      description: '',
      isBooked: isBooked,
      isInWaitlist: isInWaitlist,
      waitlistId: waitlistId,
    );

void main() {
  // ═══════════════════════════════════════════════════════════════
  //  PilatesClass.isFull / availableSpots — clase sobrevendida
  // ═══════════════════════════════════════════════════════════════
  group('PilatesClass.isFull', () {
    test('clase con lugares libres no está llena', () {
      expect(makeClass(totalSpots: 10, takenSpots: 9).isFull, false);
    });

    test('clase exactamente llena', () {
      expect(makeClass(totalSpots: 5, takenSpots: 5).isFull, true);
    });

    test('clase sobrevendida (taken > total) también está llena', () {
      expect(makeClass(totalSpots: 5, takenSpots: 7).isFull, true);
    });

    test('availableSpots nunca es negativo aunque esté sobrevendida', () {
      expect(makeClass(totalSpots: 5, takenSpots: 7).availableSpots, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  PilatesClass.cardAction — decisión del botón de la tarjeta
  // ═══════════════════════════════════════════════════════════════
  group('PilatesClass.cardAction', () {
    test('clase con lugar y sin reserva → reservar', () {
      expect(
        makeClass(totalSpots: 10, takenSpots: 4).cardAction(),
        ClassCardAction.book,
      );
    });

    test('clase llena sin reserva ni espera → anotarse en lista', () {
      expect(
        makeClass(totalSpots: 5, takenSpots: 5).cardAction(),
        ClassCardAction.joinWaitlist,
      );
    });

    test('clase sobrevendida → anotarse en lista, nunca reservar', () {
      expect(
        makeClass(totalSpots: 5, takenSpots: 7).cardAction(),
        ClassCardAction.joinWaitlist,
      );
    });

    test('usuario ya reservado → reservada, aunque la clase esté llena', () {
      expect(
        makeClass(totalSpots: 5, takenSpots: 5, isBooked: true).cardAction(),
        ClassCardAction.booked,
      );
    });

    test('usuario en lista de espera → salir de la lista', () {
      expect(
        makeClass(
          totalSpots: 5,
          takenSpots: 5,
          isInWaitlist: true,
          waitlistId: 'wl-1',
        ).cardAction(),
        ClassCardAction.leaveWaitlist,
      );
    });

    test(
        'en espera con cupo liberado sigue mostrando "en espera" '
        '(la promoción es automática en el backend)', () {
      // Si se liberó un lugar, el trigger de la BD inscribe al primero de la
      // lista que respete su límite semanal; el cliente no debe ofrecer
      // "reservar" mientras el usuario figure en la waitlist.
      expect(
        makeClass(
          totalSpots: 5,
          takenSpots: 4,
          isInWaitlist: true,
          waitlistId: 'wl-1',
        ).cardAction(),
        ClassCardAction.leaveWaitlist,
      );
    });

    test('reservado tiene prioridad sobre en-espera', () {
      expect(
        makeClass(isBooked: true, isInWaitlist: true).cardAction(),
        ClassCardAction.booked,
      );
    });

    test('forceFull fuerza lista de espera aunque el conteo local tenga lugar',
        () {
      // Caso: el servidor rechazó la reserva por capacidad ("full") pero el
      // conteo local todavía no se refrescó.
      expect(
        makeClass(totalSpots: 10, takenSpots: 4).cardAction(forceFull: true),
        ClassCardAction.joinWaitlist,
      );
    });

    test('forceFull no pisa una reserva existente', () {
      expect(
        makeClass(isBooked: true).cardAction(forceFull: true),
        ClassCardAction.booked,
      );
    });

    test('forceFull no pisa el estado en-espera', () {
      expect(
        makeClass(isInWaitlist: true, waitlistId: 'wl-1')
            .cardAction(forceFull: true),
        ClassCardAction.leaveWaitlist,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  WaitlistService.mapWaitlistRows — mapeo de filas de la BD
  // ═══════════════════════════════════════════════════════════════
  group('WaitlistService.mapWaitlistRows', () {
    test('mapea filas válidas a session_id → waitlist_id', () {
      final map = WaitlistService.mapWaitlistRows([
        {'id': 'wl-1', 'session_id': 's-1'},
        {'id': 'wl-2', 'session_id': 's-2'},
      ]);
      expect(map, {'s-1': 'wl-1', 's-2': 'wl-2'});
    });

    test('lista null devuelve mapa vacío', () {
      expect(WaitlistService.mapWaitlistRows(null), isEmpty);
    });

    test('lista vacía devuelve mapa vacío', () {
      expect(WaitlistService.mapWaitlistRows([]), isEmpty);
    });

    test('ignora filas malformadas sin romper las válidas', () {
      final map = WaitlistService.mapWaitlistRows([
        {'id': 'wl-1', 'session_id': 's-1'},
        {'id': null, 'session_id': 's-2'},
        {'session_id': 's-3'},
        'no-soy-un-mapa',
        {'id': 'wl-5', 'session_id': 42},
      ]);
      expect(map, {'s-1': 'wl-1'});
    });

    test('si hay filas duplicadas por sesión gana la última', () {
      final map = WaitlistService.mapWaitlistRows([
        {'id': 'wl-viejo', 'session_id': 's-1'},
        {'id': 'wl-nuevo', 'session_id': 's-1'},
      ]);
      expect(map, {'s-1': 'wl-nuevo'});
    });
  });
}
