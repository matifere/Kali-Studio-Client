import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kali_studio/auth/log_in.dart' show LogIn, UpperLogo;
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/utils/auth_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_utils.dart';

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
    final decorationColor = KaliColors.sand2;
    return Scaffold(
      backgroundColor: KaliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KaliColors.espresso),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: Column(
                            spacing: 16,
                            children: [
                              const Spacer(),
                              const UpperLogo(),
                              Text(
                                'Crear cuenta',
                                textAlign: TextAlign.center,
                                style: KaliText.loginDisplay(KaliColors.espresso),
                              ),
                              KaliTextField(
                                  label: 'NOMBRE COMPLETO',
                                  hint: 'Tu nombre completo',
                                  suffixIcon: Icons.person,
                                  controller: _fullNameController),
                              KaliTextField(
                                  label: 'CORREO ELECTRÓNICO',
                                  hint: 'tumail@mail.com',
                                  suffixIcon: Icons.mail,
                                  controller: _emailController),
                              KaliTextField(
                                label: 'CONTRASEÑA',
                                hint: '• • • • • • • •',
                                obscureText: !_showPassword,
                                controller: _passwordController,
                                suffixIcon: _showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () => setState(() => _showPassword = !_showPassword),
                              ),
                              KaliTextField(
                                label: 'CONFIRMAR CONTRASEÑA',
                                hint: '• • • • • • • •',
                                obscureText: !_showPassword,
                                controller: _confirmPasswordController,
                                suffixIcon: _showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () => setState(() => _showPassword = !_showPassword),
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
                                          _isLoading ? 'Creando cuenta...' : 'Registrarse',
                                          style: KaliText.buttonText(KaliColors.background),
                                        ),
                                        if (!_isLoading) const Icon(Icons.arrow_forward),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  const Row(
                                    spacing: 4,
                                    children: [
                                      Expanded(child: Divider()),
                                      Text("o"),
                                      Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _handleGoogleLogin,
                                      icon: _isLoading
                                          ? const SizedBox.shrink()
                                          : Image.network(
                                              'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                              height: 24,
                                            ),
                                      label: _isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: KaliColors.clay,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              "REGISTRARSE CON GOOGLE",
                                              style: KaliText.label(KaliColors.espresso).copyWith(
                                                fontSize: 12,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: KaliColors.espresso,
                                        elevation: 0,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(27),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text("O", style: KaliText.body(KaliColors.clayDark, size: 12)),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => const LogIn())),
                                child: const Text('Iniciar Sesión'),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Completa todos los campos.');
      return;
    }

    if (password.length < 8) {
      _showMessage('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      if (!mounted) return;
      final pending = SupabaseAuthService.pendingRegistration;
      if (pending != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.message,
          fallback: 'No pudimos crear la cuenta. Intentá de nuevo.'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.toString(),
          fallback: 'No pudimos crear la cuenta. Intentá de nuevo.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('No pudimos iniciar sesión con Google. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    KaliUI.showSnackBar(context, message);
  }
}
