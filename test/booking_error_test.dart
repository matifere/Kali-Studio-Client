import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/supabase/booking_service.dart';

void main() {
  group('BookingService.throwIfBookingFailed', () {
    test('does not throw when ok is true', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': true}),
        returnsNormally,
      );
    });

    test('throws correct message for full class', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false, 'error': 'full'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('La clase está llena.'),
          ),
        ),
      );
    });

    test('throws correct message when user has no active plan', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false, 'error': 'no_plan'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Necesitás un plan activo para reservar.'),
          ),
        ),
      );
    });

    test('throws correct message when already booked', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false, 'error': 'already_booked'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Ya tenés una reserva para esta clase.'),
          ),
        ),
      );
    });

    test('throws correct message when weekly limit exceeded', () {
      expect(
        () => BookingService.throwIfBookingFailed(
            {'ok': false, 'error': 'weekly_limit_exceeded'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Alcanzaste el límite de clases semanales de tu plan.'),
          ),
        ),
      );
    });

    test('throws generic message for unknown error codes', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false, 'error': 'unknown_error'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No se pudo reservar.'),
          ),
        ),
      );
    });

    test('throws generic message when error key is absent', () {
      expect(
        () => BookingService.throwIfBookingFailed({'ok': false}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No se pudo reservar.'),
          ),
        ),
      );
    });
  });
}
