import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(200)),
                    color: KaliColors.sand2,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(topLeft: Radius.circular(200)),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      Text(
                        "Crear cuenta",
                        textAlign: TextAlign.center,
                        style: KaliText.loginDisplay(KaliColors.espresso),
                      ),
                      const KaliTextField(
                          label: "NOMBRE COMPLETO",
                          hint: "John Doe",
                          suffixIcon: Icons.person),
                      const KaliTextField(
                          label: "CORREO ELECTRONICO",
                          hint: "tumail@mail.com",
                          suffixIcon: Icons.mail),
                      KaliTextField(
                        label: "CONTRASEÑA",
                        hint: "• • • • • • • •",
                        obscureText: !_showPassword,
                        suffixIcon: _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixTap: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                      KaliTextField(
                        label: "CONFIRMAR CONTRASEÑA",
                        hint: "• • • • • • • •",
                        obscureText: !_showPassword,
                        suffixIcon: _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
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
                                  'Registrarse',
                                  style: KaliText.buttonText(
                                      KaliColors.background),
                                ),
                                const Icon(Icons.arrow_forward)
                              ],
                            ))),
                      ),
                      const Divider(),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const LogIn()));
                          },
                          child: const Text("Iniciar Sesion"))
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
