import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/profile_manager.dart';
import '../../theme/kali_theme.dart';
import '../../widgets/kali_avatar.dart';
import '../../widgets/web_page_wrapper.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile? profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late List<String> _selectedPatologias;
  bool _isSaving = false;
  Uint8List? _selectedAvatarBytes;
  String? _avatarDataUrl;

  static const _opcionesPatologias = [
    'Hernia de disco',
    'Escoliosis',
    'Osteoporosis',
    'Embarazo',
    'Hipertensión',
    'Diabetes',
    'Lesión de rodilla',
    'Lesión de hombro',
    'Lesión de cadera',
    'Lesión de columna',
    'Cirugía reciente',
    'Artritis / Artrosis',
    'Fibromialgia',
  ];

  Color get _pageBackground => KaliColors.warmWhite;
  Color get _surfaceColor => KaliColors.sand;
  Color get _fieldColor => KaliColors.sand;
  Color get _primaryText => KaliColors.espresso;
  Color get _secondaryText => KaliColors.clayDark;
  Color get _mutedIcon => KaliColors.clay;
  Color get _borderColor => KaliColors.sand2;
  Color get _avatarBackground => KaliColors.sand;
  Color get _avatarBorder => KaliColors.sand2;
  String get _displayName =>
      _nameController.text.trim().isEmpty ? 'Perfil' : _nameController.text;

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _nameController =
        TextEditingController(text: widget.profile?.fullName ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _phoneController = TextEditingController(text: widget.profile?.phone ?? '');
    _selectedPatologias = List<String>.from(widget.profile?.patologias ?? []);
    _nameController.addListener(_handleNameChanged);
    _avatarDataUrl = widget.profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // subscribe for dark-mode rebuilds
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildProfileHero(),
              const SizedBox(height: 30),
              _buildField(
                label: 'Nombre Completo',
                controller: _nameController,
              ),
              const SizedBox(height: 18),
              _buildField(
                label: 'Correo Electrónico',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _buildField(
                label: 'Número de Teléfono',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              _buildPatologiasSection(),
              const SizedBox(height: 30),
              _buildSecurityRow(),
              const SizedBox(height: 18),
              _buildUpdateButton(),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child:
                Icon(Icons.arrow_back_rounded, color: _primaryText, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Editar perfil',
          style: KaliText.loginDisplay(_primaryText).copyWith(
            fontSize: 22,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildProfileHero() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _pickAvatar,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarBackground,
                border: Border.all(
                  color: _avatarBorder,
                  width: 3,
                ),
              ),
              child: KaliAvatarContent(
                avatarUrl: _avatarDataUrl,
                selectedBytes: _selectedAvatarBytes,
                fallbackLetter: _nameController.text.trim().isEmpty
                    ? '-'
                    : _nameController.text.trim()[0].toUpperCase(),
                fallbackFontSize: 42,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: KaliText.loginDisplay(_primaryText).copyWith(
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isSaving ? null : _pickAvatar,
            child: Text(
              'Cambiar foto',
              style: KaliText.body(
                _mutedIcon,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label,
            style: KaliText.body(
              _secondaryText,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: KaliText.body(
            _primaryText,
            size: 14,
            weight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _inputBorder(_borderColor.withValues(alpha: 0.35)),
            enabledBorder: _inputBorder(_borderColor.withValues(alpha: 0.35)),
            focusedBorder: _inputBorder(_mutedIcon),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _buildPatologiasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            'Patologías',
            style: KaliText.body(_secondaryText, size: 13, weight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'Seleccioná las que aplican para que el instructor pueda adaptar la clase.',
            style: KaliText.body(_secondaryText, size: 12, weight: FontWeight.w400)
                .copyWith(height: 1.4),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _opcionesPatologias.map((p) {
            final selected = _selectedPatologias.contains(p);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedPatologias.remove(p)
                    : _selectedPatologias.add(p);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? KaliColors.espresso : _fieldColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? KaliColors.espresso : _borderColor,
                  ),
                ),
                child: Text(
                  p,
                  style: KaliText.body(
                    selected ? KaliColors.warmWhite : _primaryText,
                    size: 13,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSecurityRow() {
    return InkWell(
      onTap: () => _showChangePasswordSheet(),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: _mutedIcon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cambiar Contraseña',
                style: KaliText.body(
                  _primaryText,
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: _secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    final buttonBackground = KaliColors.espresso;
    final buttonTextColor = KaliColors.sand;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: FilledButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonTextColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          _isSaving ? 'Guardando...' : 'Actualizar Perfil',
          style: KaliText.body(
            buttonTextColor,
            size: 15,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 82,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final extension = file.name.toLowerCase().endsWith('.png')
          ? 'png'
          : file.mimeType?.split('/').last ?? 'jpeg';
      final dataUrl = 'data:image/$extension;base64,${base64Encode(bytes)}';

      if (!mounted) return;

      setState(() {
        _selectedAvatarBytes = bytes;
        _avatarDataUrl = dataUrl;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $error')),
      );
    }
  }

  Future<void> _showChangePasswordSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChangePasswordSheet(),
    );
  }

  Future<void> _saveProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      if (_emailController.text.trim() != (user.email ?? '')) {
        await client.auth.updateUser(
          UserAttributes(email: _emailController.text.trim()),
        );
      }

      await client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'avatar_url': _avatarDataUrl,
        'patologias': _selectedPatologias,
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (newPass.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contraseña actualizada',
            style: KaliText.body(KaliColors.clay),
          ),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: KaliColors.sand2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cambiar contraseña',
              style: KaliText.loginDisplay(KaliColors.espresso).copyWith(
                fontSize: 28,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: 'Nueva contraseña',
              controller: _newPasswordCtrl,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),
            _PasswordField(
              label: 'Confirmar contraseña',
              controller: _confirmPasswordCtrl,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: KaliText.body(KaliColors.clay, size: 13, weight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: KaliColors.espresso,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _saving ? 'Guardando...' : 'Actualizar contraseña',
                  style: KaliText.body(KaliColors.sand, size: 14, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KaliText.body(KaliColors.clayDark, size: 13, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: KaliText.body(KaliColors.espresso, size: 14, weight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: KaliColors.sand,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: KaliColors.sand2.withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: KaliColors.sand2.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: KaliColors.clay),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: KaliColors.clayDark,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
