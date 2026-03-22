import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool requiresEmailConfirmation;
  final String? message;

  const AuthResult({
    this.requiresEmailConfirmation = false,
    this.message,
  });
}

class SupabaseAuthService {
  const SupabaseAuthService();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user != null) {
      try {
        await _upsertProfile(userId: user.id, fullName: fullName);
      } catch (_) {
        // Auth should still work even if the profile row depends on DB-side policies or triggers.
      }
    }

    final requiresEmailConfirmation = response.session == null;

    return AuthResult(
      requiresEmailConfirmation: requiresEmailConfirmation,
      message: requiresEmailConfirmation
          ? 'Te enviamos un email para confirmar tu cuenta.'
          : null,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> _upsertProfile({
    required String userId,
    required String fullName,
  }) async {
    await _client.from('profiles').upsert(
      {
        'id': userId,
        'full_name': fullName,
        'is_active': true,
      },
      onConflict: 'id',
    );
  }
}
