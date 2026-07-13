import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart' show UpperLogo;
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/supabase/profile_manager.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_utils.dart';

class StudioSelectionScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const StudioSelectionScreen({super.key, this.onComplete});

  @override
  State<StudioSelectionScreen> createState() => _StudioSelectionScreenState();
}

class _StudioSelectionScreenState extends State<StudioSelectionScreen> {
  final _codeController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      KaliUI.showSnackBar(context, 'Por favor, ingresá el código de tu gimnasio.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No session');

      // Llamamos a la nueva función RPC
      await Supabase.instance.client.rpc('join_institution', params: {'p_code': code});

      clearProfileCache();

      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        // Mostrar el mensaje de error que lanza el RAISE EXCEPTION en PostgreSQL
        KaliUI.showSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        KaliUI.showSnackBar(context, 'Código inválido o error de conexión. Intentá nuevamente.');
      }
    }
  }

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
                      const SizedBox(height: 24),
                      Text(
                        'Unite a tu estudio',
                        style: KaliText.loginDisplay(KaliColors.espresso),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresá el código de acceso o escaneá el QR en recepción para vincular tu cuenta.',
                        style: KaliText.body(KaliColors.clayDark, size: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      KaliTextField(
                        label: 'CÓDIGO DE ACCESO',
                        hint: 'Ej. GIMNASIO-123',
                        suffixIcon: Icons.qr_code_scanner_rounded,
                        controller: _codeController,
                        onSuffixTap: () {
                          // TODO: Implementar escáner QR a futuro
                          KaliUI.showSnackBar(context, 'El escáner QR estará disponible muy pronto.');
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSaving ? null : _handleContinue,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isSaving 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text('Continuar', style: KaliText.buttonText(KaliColors.background)),
                                  const Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          try {
                            await Supabase.instance.client.auth.signOut();
                          } catch (_) {}
                        },
                        child: Text(
                          'Cerrar sesión',
                          style: KaliText.body(KaliColors.espresso, size: 14, weight: FontWeight.w600),
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
