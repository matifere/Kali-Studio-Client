import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kali_studio/auth/new_password_screen.dart';
import 'package:kali_studio/auth/register_success_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kali_studio/auth/register.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_auth_service.dart';
import 'theme/kali_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  const url = String.fromEnvironment('SUPABASE_URL');
  const anon = String.fromEnvironment('SUPABASE_ANON');

  await ThemeController.instance.load();
  await Supabase.initialize(url: url, anonKey: anon);
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
          title: 'Kali Studio',
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
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isPasswordRecovery = true);
      } else if (state.event == AuthChangeEvent.userUpdated ||
          state.event == AuthChangeEvent.signedOut) {
        setState(() => _isPasswordRecovery = false);
      }
    });
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
          );
        }

        if (_isPasswordRecovery) {
          return const NewPasswordScreen();
        }

        final Session? session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MainShell();
        }

        return const Register();
      },
    );
  }
}
