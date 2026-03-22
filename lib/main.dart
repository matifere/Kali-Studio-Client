import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kali_studio/auth/register.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/kali_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
      url: dotenv.env['URL'] ?? "", anonKey: dotenv.env['ANON'] ?? "");
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
    return MaterialApp(
      title: 'Kali Studio',
      theme: KaliTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final Session? session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MainShell();
        }

        return const Register();
      },
    );
  }
}
