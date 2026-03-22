import 'package:flutter/material.dart';
import 'package:kali_studio/auth/register.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = const SupabaseAuthService();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(200)),
                    color: KaliColors.sand2,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(200)),
                    color: KaliColors.sand2,
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  spacing: 16,
                  children: [
                    const Spacer(),
                    const UpperLogo(),
                    Text(
                      "Bienvenid@ de vuelta",
                      textAlign: TextAlign.center,
                      style: KaliText.loginDisplay(KaliColors.espresso),
                    ),
                    KaliTextField(
                      label: 'CORREO ELECTRÓNICO',
                      hint: 'tu@ejemplo.com',
                      suffixIcon: Icons.mail_outline_rounded,
                      controller: _emailController,
                    ),
                    KaliTextField(
                      label: 'CONTRASEÑA',
                      hint: '• • • • • • • •',
                      suffixIcon: _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      obscureText: !_showPassword,
                      controller: _passController,
                      actionLabel: '¿Olvidaste tu contraseña?',
                      onActionTap: () {
                        // navegar a recuperación
                      },
                      onSuffixTap: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: SizedBox(
                          width: double.infinity,
                          child: Center(
                              child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLoading ? 'Ingresando...' : 'Iniciar Sesión',
                                style:
                                    KaliText.buttonText(KaliColors.background),
                              ),
                              if (!_isLoading) const Icon(Icons.arrow_forward)
                            ],
                          ))),
                    ),
                    const Divider(),
                    TextButton(
                      child: const Text("crear cuenta"),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const Register()));
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa email y contraseña.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on AuthException catch (error) {
      _showMessage(_humanizeError(error.message));
    } catch (error) {
      _showMessage(_humanizeError(error.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _humanizeError(String message) {
    final clean = message.replaceFirst('AuthException(message: ', '');
    final normalized =
        clean.replaceFirst(RegExp(r', statusCode:.*$'), '').trim();
    return normalized.isEmpty
        ? 'No pudimos iniciar sesion. Intenta de nuevo.'
        : normalized;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

class UpperLogo extends StatelessWidget {
  const UpperLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: KaliColors.espresso,
          ),
        ),
        const Icon(
          Icons.self_improvement,
          color: KaliColors.background,
          size: 25,
        )
      ],
    );
  }
}
