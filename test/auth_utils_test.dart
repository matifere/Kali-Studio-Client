import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/utils/auth_utils.dart';

void main() {
  group('humanizeAuthError', () {
    test('returns default fallback for empty string', () {
      expect(
        humanizeAuthError(''),
        'Algo salió mal. Intentá de nuevo.',
      );
    });

    test('returns custom fallback for empty string', () {
      expect(
        humanizeAuthError('', fallback: 'Error personalizado'),
        'Error personalizado',
      );
    });

    test('strips AuthException wrapper and returns humanized login error', () {
      const raw =
          'AuthException(message: Invalid login credentials, statusCode: 400, errorCode: invalid_credentials)';
      expect(humanizeAuthError(raw), 'Email o contraseña incorrectos.');
    });

    test('strips Exception: prefix', () {
      expect(
        humanizeAuthError('Exception: No autenticado'),
        'No autenticado',
      );
    });

    test('returns plain message unchanged', () {
      expect(
        humanizeAuthError('Algo salió mal'),
        'Algo salió mal',
      );
    });

    test('humanizes email-not-confirmed to Spanish message', () {
      const raw =
          'AuthException(message: Email not confirmed, statusCode: 401, errorCode: email_not_confirmed)';
      expect(
        humanizeAuthError(raw),
        'Necesitás confirmar tu email antes de ingresar. Revisá tu bandeja de entrada.',
      );
    });

    test('returns fallback for whitespace-only input', () {
      expect(
        humanizeAuthError('   '),
        'Algo salió mal. Intentá de nuevo.',
      );
    });
  });

  group('humanizeError', () {
    test('maps offline socket errors to a connectivity message', () {
      const raw =
          "ClientException with SocketException: Failed host lookup: 'tmfcnvtjzmtpqhzvfxos.supabase.co'";
      expect(
        humanizeError(Exception(raw)),
        'No pudimos conectarnos. Revisá tu conexión a internet e intentá de nuevo.',
      );
    });

    test('maps timeouts to a friendly message', () {
      expect(
        humanizeError(Exception('TimeoutException after 0:00:30.000000')),
        'La conexión tardó demasiado. Intentá de nuevo en unos segundos.',
      );
    });

    test('never shows raw PostgrestException details, uses fallback', () {
      const raw =
          'PostgrestException(message: duplicate key value violates unique constraint, code: 23505, details: , hint: null)';
      expect(
        humanizeError(Exception(raw), fallback: 'No se pudo reservar. Intentá de nuevo.'),
        'No se pudo reservar. Intentá de nuevo.',
      );
    });

    test('never shows type errors, uses fallback', () {
      const raw = "type 'Null' is not a subtype of type 'String'";
      expect(
        humanizeError(Exception(raw)),
        'Algo salió mal. Intentá de nuevo.',
      );
    });

    test('passes through app-thrown Spanish messages', () {
      expect(
        humanizeError(Exception('La clase está llena.')),
        'La clase está llena.',
      );
    });
  });
}
