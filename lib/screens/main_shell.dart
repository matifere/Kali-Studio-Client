import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/notification_service.dart';
import '../supabase/studio_service.dart';
import '../theme/kali_theme.dart';
import '../utils/responsive.dart';
import 'notifications_screen.dart';
import 'reservas/book_class_screen.dart';
import 'reservas/booking_detail_screen.dart';
import 'home_screen.dart';
import 'perfil/profile_screen.dart';
import 'planes/planes_screen.dart';
import 'rutina/rutina_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final Future<Studio?> _institutionFuture;
  int _unreadCount = 0;
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    _institutionFuture = StudioService.fetchCurrentInstitution();
    _loadUnreadCount();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.fetchUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  void _subscribeToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _notifChannel = NotificationService.subscribeToNotifications(
      userId: userId,
      onNew: (_) {
        if (mounted) setState(() => _unreadCount++);
      },
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadUnreadCount());
  }

  Widget _bellIcon() {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: KaliColors.espresso),
          onPressed: _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: KaliColors.espresso,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Envuelve la pantalla activa con un fade + leve desplazamiento al cambiar
  /// de pestaña, para que la transición no sea un corte seco.
  Widget _animatedBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: _buildScreen(),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          onGoToReservas: () => setState(() => _currentIndex = 1),
          onGoToPlanes: () => setState(() => _currentIndex = 4),
        );
      // const omitido intencionalmente: causa "Trying to render a disposed
      // EngineFlutterView" en Flutter web al cambiar de tema (ver commit 430c155)
      case 1:
        // ignore: prefer_const_constructors
        return BookingDetailScreen();
      case 2:
        // ignore: prefer_const_constructors
        return BookClassScreen();
      case 3:
        // ignore: prefer_const_constructors
        return RutinaScreen();
      case 4:
        // ignore: prefer_const_constructors
        return PlanesScreen();
      case 5:
        // ignore: prefer_const_constructors
        return ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  final List<_NavItem> _navItems = const [
    _NavItem(
        icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: 'Mis reservas'),
    _NavItem(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: 'Reservar clases'),
    _NavItem(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        label: 'Mi rutina'),
    _NavItem(
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership,
        label: 'Planes'),
    _NavItem(
        icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShell(context);
  }

  Widget _buildShell(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: KaliColors.warmWhite,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebar(),
            Expanded(child: _animatedBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: KaliColors.warmWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: KaliColors.espresso),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
            'Argity Turnos',
            style: KaliText.body(KaliColors.espresso, size: 15, weight: FontWeight.w600),
          ),
        actions: [_bellIcon()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: KaliColors.sand2, thickness: 1, height: 1),
        ),
      ),
      body: _animatedBody(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: Responsive.sidebarWidth,
      decoration: BoxDecoration(
        color: KaliColors.warmWhite,
        border: Border(
          right: BorderSide(color: KaliColors.sand2, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSidebarLogo(),
            const SizedBox(height: 20),
            ..._navItems.asMap().entries.map(
                  (e) => _buildSidebarItem(index: e.key, item: e.value),
                ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: _bellIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: FutureBuilder<Studio?>(
            future: _institutionFuture,
            builder: (context, snapshot) {
              final studio = snapshot.data;
              final logoUrl = studio?.logoUrl;
              final studioName = studio?.name ?? '';

              if (logoUrl != null && logoUrl.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          logoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              studioName,
                              style: KaliText.body(
                                KaliColors.espresso,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Usando Argity Turnos',
                              style: KaliText.body(
                                KaliColors.clayDark,
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        Divider(color: KaliColors.sand2, thickness: 1, height: 1),
      ],
    );
  }

  Widget _buildSidebarItem({required int index, required _NavItem item, BuildContext? drawerContext}) {
    final isActive = index == _currentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() => _currentIndex = index);
            if (drawerContext != null) Navigator.of(drawerContext).pop();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? KaliColors.espresso : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive
                      ? KaliColors.warmWhite
                      : KaliColors.clayDark,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: KaliText.body(
                    isActive ? KaliColors.warmWhite : KaliColors.clayDark,
                    size: 13,
                    weight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: KaliColors.warmWhite,
      child: Builder(
        builder: (ctx) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebarLogo(),
              const SizedBox(height: 12),
              ..._navItems.asMap().entries.map(
                    (e) => _buildSidebarItem(index: e.key, item: e.value, drawerContext: ctx),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
