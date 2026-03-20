import 'package:flutter/material.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _emailController = TextEditingController();

  final _passController = TextEditingController();

  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              color: KaliColors.background,
              width: MediaQuery.of(context).size.width * .5,
            ),
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
                      onPressed: () {
                        // TODO IMPLEMENTAR
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const MainShell()));
                      },
                      child: SizedBox(
                          width: double.infinity,
                          child: Center(
                              child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Iniciar Sesión',
                                style:
                                    KaliText.buttonText(KaliColors.background),
                              ),
                              const Icon(Icons.arrow_forward)
                            ],
                          ))),
                    ),
                    const Divider(),
                    TextButton(
                      child: const Text("crear cuenta"),
                      onPressed: () {},
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
