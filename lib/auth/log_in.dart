import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/utils/auth_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_utils.dart';

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
    final decorationColor = KaliColors.sand2;
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
                      onActionTap: () => _showResetSheet(),
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
                                    "INICIAR SESIÓN CON GOOGLE",
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

  void _showResetSheet() {
    KaliUI.showBottomSheet(
      context: context,
      builder: _ResetPasswordSheet(prefillEmail: _emailController.text.trim()),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa email y contraseña.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.message,
          fallback: 'No pudimos iniciar sesión. Intentá de nuevo.'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.toString(),
          fallback: 'No pudimos iniciar sesión. Intentá de nuevo.'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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

class _ResetPasswordSheet extends StatefulWidget {
  final String prefillEmail;
  const _ResetPasswordSheet({required this.prefillEmail});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        // Web vuelve al sitio; móvil abre la app vía deep link (custom scheme).
        // supabase_flutter detecta el link entrante y dispara el evento
        // passwordRecovery, que _AuthGate ya enruta a NewPasswordScreen.
        redirectTo: kIsWeb ? 'https://turnos.argity.com' : kAuthDeepLink,
      );
      if (!mounted) return;
      setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Mostrar el motivo real (rate limit, email inválido, sin conexión…) en
      // vez de un genérico: humanizeError ya lo traduce a español seguro.
      KaliUI.showSnackBar(context, humanizeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: KaliColors.warmWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: KaliColors.sand2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recuperar contraseña',
                style: KaliText.loginDisplay(KaliColors.espresso)
                    .copyWith(fontSize: 26, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text(
              _sent
                  ? 'Te enviamos un email con las instrucciones para restablecer tu contraseña.'
                  : 'Ingresá tu email y te enviamos un enlace para restablecer tu contraseña.',
              style: KaliText.body(KaliColors.clayDark, size: 14).copyWith(height: 1.5),
            ),
            if (!_sent) ...[
              const SizedBox(height: 20),
              KaliTextField(
                label: 'CORREO ELECTRÓNICO',
                hint: 'tu@ejemplo.com',
                suffixIcon: Icons.mail_outline_rounded,
                controller: _emailCtrl,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: KaliColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _loading ? 'Enviando...' : 'Enviar enlace',
                    style: KaliText.body(KaliColors.sand,
                        size: 14, weight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar',
                      style: KaliText.body(KaliColors.clayDark,
                          size: 14, weight: FontWeight.w500)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UpperLogo extends StatelessWidget {
  const UpperLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/LOGO NARANJA.png',
      width: 90,
      height: 90,
      fit: BoxFit.contain,
    );
  }
}
