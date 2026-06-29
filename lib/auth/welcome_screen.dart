import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/auth/register.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final decorationColor = KaliColors.sand2;
    return Scaffold(
      backgroundColor: KaliColors.background,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const UpperLogo(),
                      const SizedBox(height: 32),
                      Text(
                        'Argity Turnos',
                        textAlign: TextAlign.center,
                        style: KaliText.loginDisplay(KaliColors.espresso),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu aplicación de gestión integral',
                        textAlign: TextAlign.center,
                        style: KaliText.body(KaliColors.clayDark, size: 16),
                      ),
                      const SizedBox(height: 64),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LogIn(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: KaliColors.espresso,
                            foregroundColor: KaliColors.warmWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Iniciar Sesión',
                            style: KaliText.buttonText(KaliColors.warmWhite),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Register(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KaliColors.espresso,
                            side: BorderSide(
                              color: KaliColors.espresso,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Registrarse',
                            style: KaliText.buttonText(KaliColors.espresso),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
