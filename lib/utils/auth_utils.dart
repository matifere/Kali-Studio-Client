/// Converts a raw Supabase / AuthException message into a user-friendly string.
String humanizeAuthError(
  String message, {
  String fallback = 'Algo salió mal. Intentá de nuevo.',
}) {
  var clean = message
      .replaceFirst('AuthException(message: ', '')
      .replaceFirst(RegExp(r', statusCode:.*$'), '')
      .replaceFirst('Exception: ', '')
      .trim();
  return clean.isEmpty ? fallback : clean;
}
