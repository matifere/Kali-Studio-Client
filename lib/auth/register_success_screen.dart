import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/auth/register.dart';
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/supabase/studio_service.dart';
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterSuccessScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final bool requiresEmailConfirmation;

  const RegisterSuccessScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.requiresEmailConfirmation,
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> {
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _selectedConditions = <String>{};
  String? _studioName;

  static const List<_ConditionOption> _conditionOptions = [
    _ConditionOption(
      id: 'espalda',
      title: 'Lesion de espalda',
      icon: Icons.accessibility_new_rounded,
    ),
    _ConditionOption(
      id: 'cardiaca',
      title: 'Condicion cardiaca',
      icon: Icons.favorite_rounded,
    ),
    _ConditionOption(
      id: 'embarazo',
      title: 'Embarazo',
      icon: Icons.pregnant_woman_rounded,
    ),
    _ConditionOption(
      id: 'articulares',
      title: 'Problemas articulares',
      icon: Icons.healing_rounded,
    ),
  ];

  String get _firstName {
    final parts =
        widget.fullName.trim().split(' ').where((part) => part.isNotEmpty);
    return parts.isEmpty ? 'vos' : parts.first;
  }

  @override
  void initState() {
    super.initState();
    StudioService.fetchCurrentInstitution().then((studio) {
      if (mounted && studio != null) setState(() => _studioName = studio.name);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleCondition(String id) {
    setState(() {
      if (_selectedConditions.contains(id)) {
        _selectedConditions.remove(id);
      } else {
        _selectedConditions.add(id);
      }
    });
  }

  Future<void> _goNext() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _selectedConditions.isNotEmpty) {
      final patologias = _conditionOptions
          .where((o) => _selectedConditions.contains(o.id))
          .map((o) => o.title)
          .toList();
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'patologias': patologias}).eq('id', user.id);
      } catch (e) {
        debugPrint('patologias save error (non-critical): $e');
      }
    }

    SupabaseAuthService.clearPendingRegistration();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => widget.requiresEmailConfirmation
            ? const LogIn()
            : const MainShell(),
      ),
      (route) => false,
    );
  }

  void _goBackToRegister() {
    SupabaseAuthService.clearPendingRegistration();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Register()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = KaliColors.warmWhite;
    final primary = KaliColors.espresso;
    final primarySoft = KaliColors.espressoL;
    final surface = KaliColors.sand;
    final surfaceAlt = KaliColors.sand2;
    final accent = KaliColors.clay;
    final muted = KaliColors.clayDark;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 170),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _goBackToRegister,
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _studioName ?? '',
                                textAlign: TextAlign.center,
                                style: KaliText.headingItalic(primary, size: 24)
                                    .copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(34),
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                primarySoft,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.requiresEmailConfirmation
                                      ? 'Paso final antes de ingresar'
                                      : 'Tu perfil ya esta listo',
                                  style: KaliText.label(KaliColors.warmWhite)
                                      .copyWith(fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Bienestar\n& salud',
                                style: KaliText.loginDisplay(
                                  KaliColors.warmWhite,
                                ).copyWith(
                                  fontSize: 46,
                                  height: 0.92,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.requiresEmailConfirmation
                                    ? 'Hola, $_firstName. Ya registramos ${widget.email}. Antes de entrar, contanos si hay algo que debamos tener en cuenta para acompanarte mejor.'
                                    : 'Hola, $_firstName. Antes de empezar, contanos si hay alguna condicion o detalle que debamos conocer para adaptar tu experiencia.',
                                style: KaliText.body(
                                  KaliColors.warmWhite.withValues(alpha: 0.82),
                                  size: 14,
                                  weight: FontWeight.w400,
                                ).copyWith(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Selecciona si aplica',
                          style: KaliText.heading(primary, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esta informacion nos ayuda a acompanarte con mas cuidado en tus clases.',
                          style: KaliText.body(
                            muted,
                            size: 14,
                            weight: FontWeight.w400,
                          ).copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        ..._conditionOptions.map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ConditionCard(
                              option: option,
                              isSelected:
                                  _selectedConditions.contains(option.id),
                              onTap: () => _toggleCondition(option.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Otras condiciones o detalles',
                                style: KaliText.headingItalic(primary, size: 24),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Escribe aqui cualquier informacion relevante...',
                                  hintStyle: KaliText.body(
                                    muted.withValues(alpha: 0.8),
                                    size: 13,
                                  ),
                                  filled: true,
                                  fillColor: surfaceAlt.withValues(alpha: 0.55),
                                  contentPadding: const EdgeInsets.all(18),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: muted.withValues(alpha: 0.16),
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: accent),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                style: KaliText.body(primary, size: 14),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Opcional',
                                  style: KaliText.label(muted)
                                      .copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                colors: [
                                  primary.withValues(alpha: 0.05),
                                  primary.withValues(alpha: 0.72),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Tu bienestar es parte de la experiencia.',
                                  style: KaliText.loginDisplay(
                                    KaliColors.warmWhite,
                                  ).copyWith(
                                    fontSize: 28,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  decoration: BoxDecoration(
                    color: background.withValues(alpha: 0.92),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _goNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: KaliColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            widget.requiresEmailConfirmation
                                ? 'Guardar y seguir'
                                : 'Guardar y continuar',
                            style: KaliText.body(
                              KaliColors.background,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _goNext,
                        child: Text(
                          widget.requiresEmailConfirmation
                              ? 'Lo hago despues'
                              : 'Omitir por ahora',
                          style: KaliText.body(
                            accent,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionOption {
  final String id;
  final String title;
  final IconData icon;

  const _ConditionOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _ConditionCard extends StatelessWidget {
  final _ConditionOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = KaliColors.espresso;
    final accent = KaliColors.clay;
    final muted = KaliColors.clayDark;
    final surface = isSelected ? KaliColors.sand2 : KaliColors.sand;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.22),
                  ),
                  child: Icon(option.icon, color: primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.title,
                    style: KaliText.body(
                      primary,
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : muted.withValues(alpha: 0.26),
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
