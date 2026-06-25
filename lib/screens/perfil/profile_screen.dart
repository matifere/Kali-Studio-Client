import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/register.dart';
import '../../supabase/profile_manager.dart';
import '../../supabase/supabase_auth_service.dart';
import '../../theme/kali_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/kali_avatar.dart';
import '../../widgets/web_page_wrapper.dart';
import 'consentimiento_screen.dart';
import 'edit_profile_screen.dart';
import '../../utils/ui_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;

  Color get _pageBackground => KaliColors.warmWhite;
  Color get _surfaceColor => KaliColors.sand;
  Color get _primaryText => KaliColors.espresso;
  Color get _secondaryText => KaliColors.clayDark;
  Color get _mutedIcon => KaliColors.clay;
  Color get _dividerColor => KaliColors.sand2;
  Color get _chevronColor => KaliColors.clayDark.withValues(alpha: 0.72);
  Color get _avatarBorder => KaliColors.sand2;
  Color get _dangerColor => const Color(0xFFB3463C);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'sin correo';

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
              const SizedBox(height: 26),
              _buildProfileHeader(email),
              const SizedBox(height: 28),
              _buildSectionTitle('Cuenta'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Editar perfil',
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(profile: _profile),
                        ),
                      );

                      if (updated == true) {
                        await _cargarPerfil();
                      }
                    },
                  ),
                  _softDivider(),
                  _buildMenuRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Eliminar cuenta',
                    iconColor: _dangerColor,
                    titleColor: _dangerColor,
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('Preferencias'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    onTap: _handleNotificationsTap,
                  ),
                  _softDivider(),
                  _buildSwitchRow(),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('Soporte'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Ayuda',
                    onTap: () => launchUrl(
                      Uri.parse('https://wa.me/5491130681395'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  _softDivider(),
                  _buildMenuRow(
                    icon: Icons.description_outlined,
                    title: 'Consentimiento',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConsentimientoScreen()),
                    ),
                  ),
                  _softDivider(),
                  _buildMenuRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    onTap: () => launchUrl(
                      Uri.parse('https://turnos.argity.com/privacy.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildLogoutButton(context),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String email) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [KaliColors.clay, KaliColors.sand],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: _avatarBorder, width: 2),
            ),
            child: KaliAvatarContent(
              avatarUrl: _profile?.avatarUrl,
              fallbackLetter: _initialLetter(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.fullName ?? 'Perfil',
            style: KaliText.loginDisplay(_primaryText).copyWith(
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: KaliText.body(
              _secondaryText,
              size: 13,
              weight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: KaliText.loginDisplay(_primaryText).copyWith(
          fontSize: 24,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? _mutedIcon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: KaliText.body(
                  titleColor ?? _primaryText,
                  size: 14,
                  weight: FontWeight.w400,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: KaliText.body(
                  _secondaryText,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, size: 18, color: _chevronColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow() {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 20, color: _mutedIcon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Modo oscuro',
                  style: KaliText.body(
                    _primaryText,
                    size: 14,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              Switch.adaptive(
                value: ThemeController.instance.isDarkMode,
                activeThumbColor: KaliColors.espresso,
                activeTrackColor: const Color(0xFFB8A18D),
                onChanged: ThemeController.instance.setDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _softDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(height: 1, thickness: 1, color: _dividerColor),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _signOut(context),
        style: FilledButton.styleFrom(
          backgroundColor: KaliColors.espresso,
          foregroundColor: KaliColors.background,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          'Cerrar sesión',
          style: KaliText.body(
            KaliColors.background,
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _initialLetter() {
    final name = _profile?.fullName.trim();
    if (name == null || name.isEmpty) {
      return '-';
    }
    return name[0].toUpperCase();
  }

  Future<void> _cargarPerfil() async {
    final perfil = await obtenerPerfil();

    if (!mounted) return;

    setState(() {
      _profile = perfil;
    });
  }

  void _showMessage(String message) {
    KaliUI.showSnackBar(context, message);
  }

  Future<void> _handleNotificationsTap() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      _showMessage('Las notificaciones ya están activadas.');
      return;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();

      if (result.isGranted) {
        _showMessage('Notificaciones activadas.');
      } else {
        _showMessage('No se activaron las notificaciones.');
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await const SupabaseAuthService().signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Register()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          'Eliminar cuenta',
          style: KaliText.body(_primaryText, size: 18, weight: FontWeight.w700),
        ),
        content: Text(
          'Esta acción es permanente. Se eliminarán tu cuenta y todos tus '
          'datos: reservas, lista de espera, planes y notificaciones. '
          'No se puede deshacer.',
          style: KaliText.body(_secondaryText, size: 14, weight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: KaliText.body(_secondaryText, size: 14, weight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Eliminar',
              style: KaliText.body(_dangerColor, size: 14, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await const SupabaseAuthService().deleteAccount();

      if (!mounted) return;
      Navigator.of(context).pop(); // cerrar el loader

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Register()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // cerrar el loader
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
