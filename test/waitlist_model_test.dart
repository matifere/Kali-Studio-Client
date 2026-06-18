import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/models/models.dart';
import 'package:kali_studio/supabase/booking_service.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

PilatesClass makeClass({
  String id = 'session-1',
  int totalSpots = 10,
  int takenSpots = 0,
  bool isBooked = false,
  String? reservationId,
  bool isInWaitlist = false,
  String? waitlistId,
  DateTime? sessionDate,
}) =>
    PilatesClass(
      id: id,
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
      reservationId: reservationId,
      isInWaitlist: isInWaitlist,
      waitlistId: waitlistId,
      sessionDate: sessionDate,
    );

Plan makePlan({
  String id = 'plan-1',
  String name = 'Plan Mensual',
  String description = '',
  double price = 15000,
  String currency = 'ARS',
  int? monthlyClasses,
}) =>
    Plan(
      id: id,
      name: name,
      description: description,
      price: price,
      currency: currency,
      monthlyClasses: monthlyClasses,
    );

UserPlan makeUserPlan({
  String status = 'active',
  DateTime? endDate,
  DateTime? startDate,
}) =>
    UserPlan(
      id: 'up-1',
      planId: 'plan-1',
      name: 'Plan Mensual',
      description: '',
      price: 15000,
      currency: 'ARS',
      startDate: startDate ?? DateTime.now().subtract(const Duration(days: 10)),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 20)),
      status: status,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════════════
  //  PilatesClass — availableSpots
  // ═══════════════════════════════════════════════════════════════
  group('PilatesClass.availableSpots', () {
    test('clase con lugares libres', () {
      expect(makeClass(totalSpots: 10, takenSpots: 6).availableSpots, 4);
    });

    test('clase llena devuelve 0', () {
      expect(makeClass(totalSpots: 5, takenSpots: 5).availableSpots, 0);
    });

    test('clase vacía devuelve totalSpots', () {
      expect(makeClass(totalSpots: 8, takenSpots: 0).availableSpots, 8);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  PilatesClass — waitlist state
  // ═══════════════════════════════════════════════════════════════
  group('PilatesClass — waitlist state', () {
    test('isInWaitlist es false por defecto', () {
      final cls = makeClass();
      expect(cls.isInWaitlist, false);
      expect(cls.waitlistId, isNull);
    });

    test('isInWaitlist true cuando está en lista de espera', () {
      final cls = makeClass(isInWaitlist: true, waitlistId: 'wl-abc');
      expect(cls.isInWaitlist, true);
      expect(cls.waitlistId, 'wl-abc');
    });

    test('isBooked y isInWaitlist son flags independientes', () {
      // La UI maneja la prioridad; el modelo no impone exclusión mutua
      final cls = makeClass(isBooked: false, isInWaitlist: true, waitlistId: 'wl-1');
      expect(cls.isBooked, false);
      expect(cls.isInWaitlist, true);
    });

    test('clase reservada tiene reservationId', () {
      final cls = makeClass(isBooked: true, reservationId: 'res-xyz');
      expect(cls.isBooked, true);
      expect(cls.reservationId, 'res-xyz');
    });

    test('clase llena con usuario en waitlist mantiene ambos estados', () {
      final cls = makeClass(
        totalSpots: 1,
        takenSpots: 1,
        isInWaitlist: true,
        waitlistId: 'wl-2',
      );
      expect(cls.availableSpots, 0);
      expect(cls.isInWaitlist, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  Plan — formattedPrice
  // ═══════════════════════════════════════════════════════════════
  group('Plan.formattedPrice', () {
    test('precio menor a 1000 no lleva punto', () {
      expect(makePlan(price: 500).formattedPrice, '500');
    });

    test('precio de 4 dígitos lleva punto de miles', () {
      expect(makePlan(price: 1000).formattedPrice, '1.000');
    });

    test('precio de 5 dígitos lleva punto de miles', () {
      expect(makePlan(price: 15000).formattedPrice, '15.000');
    });

    test('precio de 7 dígitos lleva dos puntos', () {
      expect(makePlan(price: 1000000).formattedPrice, '1.000.000');
    });

    test('precio cero', () {
      expect(makePlan(price: 0).formattedPrice, '0');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  Plan — features
  // ═══════════════════════════════════════════════════════════════
  group('Plan.features', () {
    test('parsea líneas de descripción', () {
      final plan = makePlan(description: 'Línea 1\nLínea 2\nLínea 3');
      expect(plan.features, ['Línea 1', 'Línea 2', 'Línea 3']);
    });

    test('ignora líneas en blanco', () {
      final plan = makePlan(description: 'A\n\nB\n\nC');
      expect(plan.features, ['A', 'B', 'C']);
    });

    test('ignora espacios en blanco alrededor de cada línea', () {
      final plan = makePlan(description: '  A  \n  B  ');
      expect(plan.features, ['A', 'B']);
    });

    test('descripción vacía devuelve lista vacía', () {
      expect(makePlan(description: '').features, isEmpty);
    });

    test('descripción solo espacios devuelve lista vacía', () {
      expect(makePlan(description: '   ').features, isEmpty);
    });

    test('descripción de una sola línea', () {
      expect(makePlan(description: 'Acceso ilimitado').features, ['Acceso ilimitado']);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  UserPlan — isActive / daysRemaining
  // ═══════════════════════════════════════════════════════════════
  group('UserPlan.isActive', () {
    test('status active → isActive true', () {
      expect(makeUserPlan(status: 'active').isActive, true);
    });

    test('status inactive → isActive false', () {
      expect(makeUserPlan(status: 'inactive').isActive, false);
    });

    test('status pending → isActive false', () {
      expect(makeUserPlan(status: 'pending').isActive, false);
    });
  });

  group('UserPlan.daysRemaining', () {
    test('plan que vence en 5 días devuelve 4 o 5 (inDays trunca)', () {
      final plan = makeUserPlan(endDate: DateTime.now().add(const Duration(days: 5)));
      // Duration.inDays truncates sub-day remainders, so 4 or 5 are both correct
      expect(plan.daysRemaining, inInclusiveRange(4, 5));
    });

    test('plan ya vencido devuelve 0, nunca negativo', () {
      final plan = makeUserPlan(endDate: DateTime.now().subtract(const Duration(days: 3)));
      expect(plan.daysRemaining, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  BookingService.throwIfBookingFailed — edge cases
  //  (la cobertura base ya está en booking_error_test.dart)
  // ═══════════════════════════════════════════════════════════════
  group('BookingService.throwIfBookingFailed — casos adicionales', () {
    test('ok: true ignora cualquier error presente', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': true, 'error': 'full'}),
        returnsNormally,
      );
    });

    test('ok: false con error null lanza mensaje genérico', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false, 'error': null}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No se pudo reservar.'),
        )),
      );
    });

    test('monthly_limit_exceeded lanza mensaje correcto', () {
      expect(
        () => BookingService.throwIfBookingFailed(
            {'ok': false, 'error': 'monthly_limit_exceeded'}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Alcanzaste el límite de clases mensuales de tu plan.'),
        )),
      );
    });
  });
}
