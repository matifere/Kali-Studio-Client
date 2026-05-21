import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/utils/auth_utils.dart';

void main() {
  test('humanizeAuthError returns fallback for empty input', () {
    expect(humanizeAuthError(''), 'Algo salió mal. Intentá de nuevo.');
  });
}
