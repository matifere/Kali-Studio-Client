import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const SupabaseAuthService();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                      KaliTextField(
                          label: "NOMBRE COMPLETO",
                          hint: "John Doe",
                          suffixIcon: Icons.person,
                          controller: _fullNameController),
                      KaliTextField(
                          label: "CORREO ELECTRONICO",
                          hint: "tumail@mail.com",
                          suffixIcon: Icons.mail,
                          controller: _emailController),
                      KaliTextField(
                        label: "CONTRASEÑA",
                        hint: "• • • • • • • •",
                        obscureText: !_showPassword,
                        controller: _passwordController,
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
                        controller: _confirmPasswordController,
                        suffixIcon: _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixTap: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: SizedBox(
                            width: double.infinity,
                            child: Center(
                                child: Row(
                              spacing: 8,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLoading
                                      ? 'Creando cuenta...'
                                      : 'Registrarse',
                                  style: KaliText.buttonText(
                                      KaliColors.background),
                                ),
                                if (!_isLoading) const Icon(Icons.arrow_forward)
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

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Completa todos los campos.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.requiresEmailConfirmation) {
        _showMessage(
            result.message ?? 'Revisa tu email para confirmar la cuenta.');
        return;
      }

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
        ? 'No pudimos crear la cuenta. Intenta de nuevo.'
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
