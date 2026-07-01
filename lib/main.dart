import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kali_studio/auth/new_password_screen.dart';
import 'package:kali_studio/firebase_options.dart';
import 'package:kali_studio/services/mobile_push_service.dart';
import 'package:kali_studio/auth/register_success_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kali_studio/auth/welcome_screen.dart';
import 'package:kali_studio/auth/studio_selection_screen.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/screens/planes/planes_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/plan_service.dart';
import 'supabase/profile_manager.dart';
import 'supabase/studio_service.dart';
import 'supabase/supabase_auth_service.dart';
import 'theme/kali_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/ui_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  await dotenv.load(fileName: ".env");
  // Mismos nombres de clave en .env (móvil) y --dart-define (web) para evitar
  // que uno quede vacío: con URL vacía Supabase.initialize no falla, pero la
  // primera request (el login) tira "No host specified in URI".
  final url = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
  final anon = dotenv.env['SUPABASE_ANON'] ??
      const String.fromEnvironment(
        'SUPABASE_ANON',
        defaultValue: '',
      );

  assert(
    url.isNotEmpty && anon.isNotEmpty,
    'Faltan las credenciales de Supabase: revisá que .env (móvil) o los '
    '--dart-define (web) definan SUPABASE_URL y SUPABASE_ANON.',
  );

  await ThemeController.instance.load();
  await Supabase.initialize(
    url: url,
    anonKey: anon,
    // Flujo implicit (tokens en el fragment del redirect) en vez de PKCE.
    // PKCE necesita el code_verifier guardado en el mismo cliente que pidió el
    // reset; si el link de recuperación se abre en otro navegador/dispositivo el
    // canje del ?code= falla sin evento visible y "el link no hace nada".
    // Con implicit el link trae #access_token=...&type=recovery y dispara
    // passwordRecovery sin depender del verifier. Ver _AuthGate.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Push móvil (FCM). En web el push usa VAPID por separado, así que se omite.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await MobilePushService.instance.init();
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const KaliApp());
}

class KaliApp extends StatelessWidget {
  const KaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Argity',
          theme: KaliTheme.theme,
          darkTheme: KaliTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          debugShowCheckedModeBanner: false,
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _isPasswordRecovery = false;
  bool _checkingProfile = false;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _checkProfile();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isPasswordRecovery = true);
      } else if (state.event == AuthChangeEvent.signedIn) {
        clearProfileCache();
        StudioService.clearCache();
        // During registration the profile is created by signUp() right after
        // the session is established. Calling _checkProfile() here would race
        // against that upsert, find no profile yet, and sign the user out.
        if (SupabaseAuthService.pendingRegistration == null) {
          _checkProfile();
        }
      } else if (state.event == AuthChangeEvent.userUpdated ||
          state.event == AuthChangeEvent.signedOut) {
        clearProfileCache();
        StudioService.clearCache();
        setState(() => _isPasswordRecovery = false);
      }
    });
  }

  Profile? _currentProfile;
  bool _hasActivePlan = false;

  Future<void> _checkProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    setState(() => _checkingProfile = true);
    final profile = await obtenerPerfil();
    if (!mounted) return;
    if (profile == null) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        KaliUI.showSnackBar(context, 'Tu cuenta no está habilitada. Contactá al estudio.');
      }
    } else {
      _currentProfile = profile;
      if (profile.institutionId != null) {
        final studio = await StudioService.fetchCurrentInstitution();
        if (studio != null && studio.themeId != null) {
          ThemeController.instance.syncTheme(studio.themeId!);
        }
        // Detectamos si el alumno tiene un plan activo. Si no, se lo obliga a
        // activar uno antes de dejarlo entrar a la app (ver build()).
        final activePlan = await PlanService.fetchActivePlan();
        if (!mounted) return;
        _hasActivePlan = activePlan != null;
      }
    }
    if (mounted) setState(() => _checkingProfile = false);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final pendingRegistration = SupabaseAuthService.pendingRegistration;
        if (pendingRegistration != null) {
          return RegisterSuccessScreen(
            fullName: pendingRegistration.fullName,
            email: pendingRegistration.email,
            requiresEmailConfirmation:
                pendingRegistration.requiresEmailConfirmation,
            onComplete: () {
              SupabaseAuthService.clearPendingRegistration();
              if (!pendingRegistration.requiresEmailConfirmation) {
                _checkProfile();
              } else {
                setState(() {});
              }
            },
          );
        }

        if (_isPasswordRecovery) {
          return const NewPasswordScreen();
        }

        if (_checkingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final Session? session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          if (_currentProfile != null && _currentProfile!.institutionId == null) {
            return StudioSelectionScreen(
              onComplete: () => _checkProfile(),
            );
          }
          // Sin plan activo no dejamos entrar a la app: mostramos la pantalla
          // de planes en modo bloqueante hasta que active uno.
          if (_currentProfile != null && !_hasActivePlan) {
            return PlanesScreen(
              onPlanActivated: () => _checkProfile(),
            );
          }
          return const MainShell();
        }

        return const WelcomeScreen();
      },
    );
  }
}
