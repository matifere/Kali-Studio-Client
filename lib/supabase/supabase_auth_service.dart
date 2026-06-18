import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/mobile_push_service.dart';
import '../utils/auth_utils.dart';
import 'profile_manager.dart';
import 'studio_service.dart';

class AuthResult {
  final bool requiresEmailConfirmation;
  final String? message;

  const AuthResult({
    this.requiresEmailConfirmation = false,
    this.message,
  });
}

class PendingRegistration {
  final String fullName;
  final String email;
  final bool requiresEmailConfirmation;

  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.requiresEmailConfirmation,
  });
}

class SupabaseAuthService {
  const SupabaseAuthService();

  static PendingRegistration? _pendingRegistration;

  static PendingRegistration? get pendingRegistration => _pendingRegistration;

  static void clearPendingRegistration() => _pendingRegistration = null;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String studioId,
  }) async {
    // Setear ANTES del signUp para que cuando _AuthGate reciba el evento
    // de auth ya vea pendingRegistration != null y muestre RegisterSuccessScreen
    _pendingRegistration = PendingRegistration(
      fullName: fullName,
      email: email,
      requiresEmailConfirmation: false,
    );

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        // En móvil el link de confirmación abre la app vía deep link; en web
        // emailRedirectTo se ignora y se usa el Site URL del proyecto.
        emailRedirectTo: kIsWeb ? null : kAuthDeepLink,
      );

      final requiresEmailConfirmation = response.session == null;

      final user = response.user;
      if (user != null && !requiresEmailConfirmation) {
        try {
          await _upsertProfile(userId: user.id, fullName: fullName, institutionId: studioId);
        } catch (e) {
          debugPrint('_upsertProfile error (non-critical): $e');
        }
      }

      _pendingRegistration = PendingRegistration(
        fullName: fullName,
        email: email,
        requiresEmailConfirmation: requiresEmailConfirmation,
      );

      return AuthResult(
        requiresEmailConfirmation: requiresEmailConfirmation,
        message: requiresEmailConfirmation
            ? 'Te enviamos un email para confirmar tu cuenta.'
            : null,
      );
    } catch (e) {
      _pendingRegistration = null;
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await Future.wait([
        _ensureProfile(user),
        getInstitutionId(),
      ]);
      // Registrar el token FCM de este dispositivo para el usuario (no-op en web).
      unawaited(MobilePushService.instance.syncToken());
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final fullName =
            (user.userMetadata?['full_name'] as String?)?.trim() ?? '';
        await _upsertProfile(userId: user.id, fullName: fullName);
      }
    } catch (e) {
      debugPrint('_ensureProfile error (non-critical): $e');
    }
  }

  Future<void> signOut() async {
    // Antes de cerrar sesión (mientras el RLS todavía lo permite) borrar el
    // token FCM de este dispositivo para no recibir push de la cuenta saliente.
    await MobilePushService.instance.removeToken();
    clearProfileCache();
    StudioService.clearCache();
    await _client.auth.signOut();
  }

  /// Borra de forma permanente la cuenta del usuario logueado y todos sus
  /// datos asociados (reservas, lista de espera, suscripciones, pagos,
  /// notificaciones) vía la Edge Function `delete-account`, y luego cierra
  /// la sesión local. Requerido por App Store y Google Play.
  Future<void> deleteAccount() async {
    if (_client.auth.currentSession == null) {
      throw Exception('Tu sesión expiró. Volvé a iniciar sesión.');
    }

    final response = await _client.functions.invoke('delete-account');

    if (response.status != 200) {
      final err = (response.data as Map<String, dynamic>?)?['error'] as String?
          ?? 'No pudimos eliminar tu cuenta. Intentá de nuevo.';
      throw Exception(err);
    }

    await signOut();
  }

  Future<void> _upsertProfile({
    required String userId,
    required String fullName,
    String? institutionId,
  }) async {
    await _client.from('profiles').upsert(
      {
        'id': userId,
        'full_name': fullName,
        if (institutionId != null) 'institution_id': institutionId,
      },
      onConflict: 'id',
    );
  }
}
