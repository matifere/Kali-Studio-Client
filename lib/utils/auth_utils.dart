/// Converts a raw Supabase / AuthException message into a user-friendly string.
String humanizeAuthError(
  String message, {
  String fallback = 'Algo salió mal. Intentá de nuevo.',
}) {
  var clean = message
      .replaceFirst('AuthException(message: ', '')
      .replaceFirst(RegExp(r', statusCode:.*$'), '')
      .replaceFirst('Exception: ', '')
      .trim()
      .toLowerCase();

  if (clean.contains('email not confirmed')) {
    return 'Necesitás confirmar tu email antes de ingresar. Revisá tu bandeja de entrada.';
  }
  if (clean.contains('invalid login credentials') ||
      clean.contains('invalid_credentials') ||
      clean.contains('invalid email or password')) {
    return 'Email o contraseña incorrectos.';
  }
  if (clean.contains('user already registered') ||
      clean.contains('email address already registered') ||
      clean.contains('already been registered')) {
    return 'Este email ya está registrado. Probá iniciando sesión.';
  }
  if (clean.contains('password should be at least') ||
      clean.contains('weak_password') ||
      clean.contains('password is too short')) {
    return 'La contraseña debe tener al menos 6 caracteres.';
  }
  if (clean.contains('unable to validate email address') ||
      clean.contains('invalid email')) {
    return 'El formato del email no es válido.';
  }
  if (clean.contains('email link is invalid or has expired') ||
      clean.contains('token has expired')) {
    return 'El enlace expiró o ya fue usado. Solicitá uno nuevo.';
  }
  if (clean.contains('too many requests') || clean.contains('rate limit')) {
    return 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
  }

  // Fallback: return the original message cleaned but not lowercased
  final original = message
      .replaceFirst('AuthException(message: ', '')
      .replaceFirst(RegExp(r', statusCode:.*$'), '')
      .replaceFirst('Exception: ', '')
      .trim();

  return original.isEmpty ? fallback : original;
}
