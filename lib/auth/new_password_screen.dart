import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_utils.dart';
import '../utils/ui_utils.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || confirm.isEmpty) {
      _showSnack('Completá ambos campos.');
      return;
    }
    if (pass.length < 8) {
      _showSnack('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
    } catch (e) {
      // Solo acá hay un error real: el cambio de contraseña no se aplicó.
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(humanizeError(
        e,
        fallback: 'No pudimos actualizar la contraseña. Intentá de nuevo.',
      ));
      return;
    }

    // Éxito: la contraseña ya quedó cambiada en el servidor. El signOut es solo
    // para limpiar la sesión de recuperación; cambiar la contraseña rota la
    // sesión y hace que signOut pueda tirar excepción, pero eso NO es un error
    // para el usuario (antes mostraba "Error al actualizar" pese a haber
    // funcionado). Por eso va aparte y se ignora si falla.
    if (mounted) {
      _showSnack('¡Contraseña actualizada! Ya podés iniciar sesión.');
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {/* la contraseña ya se cambió; ignoramos */}
    if (mounted) setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    KaliUI.showSnackBar(context, msg);
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    spacing: 16,
                    children: [
                      const Spacer(),
                      Text(
                        'Nueva contraseña',
                        textAlign: TextAlign.center,
                        style: KaliText.loginDisplay(KaliColors.espresso),
                      ),
                      Text(
                        'Elegí una contraseña segura para tu cuenta.',
                        textAlign: TextAlign.center,
                        style: KaliText.body(KaliColors.clayDark, size: 14)
                            .copyWith(height: 1.5),
                      ),
                      KaliTextField(
                        label: 'NUEVA CONTRASEÑA',
                        hint: '• • • • • • • •',
                        suffixIcon: _showPass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        obscureText: !_showPass,
                        controller: _passCtrl,
                        onSuffixTap: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                      KaliTextField(
                        label: 'CONFIRMAR CONTRASEÑA',
                        hint: '• • • • • • • •',
                        suffixIcon: _showConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        obscureText: !_showConfirm,
                        controller: _confirmCtrl,
                        onSuffixTap: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              _loading ? 'Guardando...' : 'Guardar contraseña',
                              style: KaliText.buttonText(KaliColors.background),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
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
