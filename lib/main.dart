import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/auth/register.dart';
import 'theme/kali_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const Register(),
    );
  }
}
