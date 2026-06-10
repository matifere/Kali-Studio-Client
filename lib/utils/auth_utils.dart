/// Strips technical wrappers (Exception:, AuthException(...), etc.) from a
/// raw error message.
String _cleanErrorMessage(String message) {
  return message
      .replaceFirst('AuthException(message: ', '')
      .replaceFirst(RegExp(r', statusCode:.*$'), '')
      .replaceFirst('Exception: ', '')
      .trim();
}

/// True if the message looks like a raw technical error that should never be
/// shown to the user (exception class names, network internals, type errors).
bool _looksTechnical(String message) {
  final technical = RegExp(
    r'(clientexception|socketexception|timeoutexception|handshakeexception|'
    r'postgrestexception|functionexception|functionsexception|storageexception|'
    r'formatexception|httpexception|xmlhttprequest|failed host lookup|'
    r'connection (refused|reset|closed)|statuscode|stack ?trace|'
    r"type '.+' is not a subtype|nosuchmethoderror|rangeerror|stateerror|"
    r'null check operator|instance of|errorobject|jwt|sqlstate|pgrst)',
    caseSensitive: false,
  );
  return technical.hasMatch(message);
}

/// Converts any caught error into a user-friendly Spanish message.
///
/// Known auth and network errors get a specific message. App-thrown
/// `Exception('mensaje para el usuario')` messages pass through cleaned.
/// Anything that still looks technical falls back to [fallback] so raw
/// errors never reach the user.
String humanizeError(
  Object error, {
  String fallback = 'Algo salió mal. Intentá de nuevo.',
}) {
  return humanizeAuthError(error.toString(), fallback: fallback);
}

/// Converts a raw Supabase / AuthException message into a user-friendly string.
String humanizeAuthError(
  String message, {
  String fallback = 'Algo salió mal. Intentá de nuevo.',
}) {
  final clean = _cleanErrorMessage(message).toLowerCase();

  // ── Network / connectivity ────────────────────────────────────────────────
  if (clean.contains('socketexception') ||
      clean.contains('failed host lookup') ||
      clean.contains('xmlhttprequest') ||
      clean.contains('connection refused') ||
      clean.contains('connection reset') ||
      clean.contains('connection closed') ||
      clean.contains('network is unreachable') ||
      clean.contains('no internet')) {
    return 'No pudimos conectarnos. Revisá tu conexión a internet e intentá de nuevo.';
  }
  if (clean.contains('timeoutexception') || clean.contains('timed out')) {
    return 'La conexión tardó demasiado. Intentá de nuevo en unos segundos.';
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
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
  if (clean.contains('jwt expired') || clean.contains('refresh_token')) {
    return 'Tu sesión expiró. Volvé a iniciar sesión.';
  }

  // ── Fallback: show the cleaned message only if it's safe for users ───────
  final original = _cleanErrorMessage(message);
  if (original.isEmpty || _looksTechnical(original)) return fallback;
  return original;
}
