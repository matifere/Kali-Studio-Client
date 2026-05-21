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

    test('strips AuthException wrapper and statusCode suffix', () {
      const raw =
          'AuthException(message: Invalid login credentials, statusCode: 400, errorCode: invalid_credentials)';
      expect(humanizeAuthError(raw), 'Invalid login credentials');
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

    test('strips AuthException with email-not-confirmed message', () {
      const raw =
          'AuthException(message: Email not confirmed, statusCode: 401, errorCode: email_not_confirmed)';
      expect(humanizeAuthError(raw), 'Email not confirmed');
    });

    test('returns fallback for whitespace-only input', () {
      expect(
        humanizeAuthError('   '),
        'Algo salió mal. Intentá de nuevo.',
      );
    });
  });
}
