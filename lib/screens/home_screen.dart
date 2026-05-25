import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/supabase/booking_service.dart';
import 'package:kali_studio/supabase/plan_service.dart';
import 'package:kali_studio/supabase/profile_manager.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import '../models/models.dart';
import '../theme/kali_theme.dart';
import '../widgets/web_page_wrapper.dart';

// ── Data ─────────────────────────────────────────────────────────────────────

class _HomeData {
  final Profile? profile;
  final PilatesClass? nextClass;
  final int monthlyCount;
  final UserPlan? plan;

  const _HomeData({
    required this.profile,
    required this.nextClass,
    required this.monthlyCount,
    required this.plan,
  });
}

// ── Widget ────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToReservas;
  final VoidCallback? onGoToPlanes;

  const HomeScreen({super.key, this.onGoToReservas, this.onGoToPlanes});

  static _HomeData? _cache;
  static DateTime? _cacheTime;

  static void invalidateCache() {
    _cache = null;
    _cacheTime = null;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Future<_HomeData> _dataFuture;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<_HomeData> _loadAll() async {
    final now = DateTime.now();
    if (HomeScreen._cache != null &&
        HomeScreen._cacheTime != null &&
        now.difference(HomeScreen._cacheTime!).inSeconds < 30) {
      return HomeScreen._cache!;
    }
    final results = await Future.wait<Object?>([
      obtenerPerfil().catchError((_) => null),
      BookingService.fetchNextReservation().catchError((_) => null),
      BookingService.fetchMonthlyReservationCount(now.year, now.month)
          .catchError((_) => 0),
      PlanService.fetchActivePlan().catchError((_) => null),
    ]);
    HomeScreen._cache = _HomeData(
      profile: results[0] as Profile?,
      nextClass: results[1] as PilatesClass?,
      monthlyCount: (results[2] as int?) ?? 0,
      plan: results[3] as UserPlan?,
    );
    HomeScreen._cacheTime = now;
    return HomeScreen._cache!;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          bottom: false,
          child: WebPageWrapper(
            child: FutureBuilder<_HomeData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(data),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Tu próxima clase'),
                            const SizedBox(height: 14),
                            data?.nextClass != null
                                ? _buildNextClassCard(data!.nextClass!)
                                : _buildEmptyCard(
                                    title: 'Sin próxima clase',
                                    subtitle: 'Todavía no tenés clases reservadas.',
                                  ),
                            const SizedBox(height: 28),
                            _sectionLabel('Tu plan'),
                            const SizedBox(height: 14),
                            data?.plan != null
                                ? _buildPlanCard(data!.plan!)
                                : _buildEmptyCard(
                                    title: 'Sin plan activo',
                                    subtitle: 'Todavía no tenés un plan activo.',
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildHero(_HomeData? data) {
    final name = data?.profile?.fullName.split(' ').first ?? '';
    final count = data?.monthlyCount ?? 0;
    final countLabel = count == 0
        ? 'Sin clases este mes'
        : count == 1
            ? '1 clase este mes'
            : '$count clases este mes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -50,
            child: _decorativeCircle(150, alpha: 0.15),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BIENVENIDA DE VUELTA',
                style: KaliText.label(KaliColors.clay)
                    .copyWith(fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: 'Hola, ',
                  style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 34,
                      weight: FontWeight.w400),
                  children: [
                    TextSpan(
                      text: name.isNotEmpty ? name : '...',
                      style: GoogleFontsHelper.cormorant(KaliColors.clay, 34,
                          italic: true, weight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _statPill(countLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(PilatesClass cls) {
    return _buildDarkCard(
      onTap: widget.onGoToReservas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: cls.time,
              style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 42,
                  weight: FontWeight.w400),
              children: [
                TextSpan(
                  text: ' ${cls.period}',
                  style: KaliText.body(
                    KaliColors.warmWhite.withValues(alpha: 0.72),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(cls.name,
              style: KaliText.body(KaliColors.warmWhite, size: 26,
                  weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
              cls.sessionDate != null
                  ? _capitalize(DateFormat("EEEE d 'de' MMM", 'es').format(cls.sessionDate!))
                  : '',
              style: KaliText.body(
                  KaliColors.warmWhite.withValues(alpha: 0.65), size: 14)),
          const SizedBox(height: 22),
          Row(children: [
            _infoPill(cls.instructor.split(' ').first),
            const SizedBox(width: 8),
            _infoPill('${cls.durationMin} min'),
          ]),
          const SizedBox(height: 14),
          _ctaButton(label: 'Ver clase', onTap: widget.onGoToReservas),
        ],
      ),
    );
  }

  Widget _buildPlanCard(UserPlan plan) {
    final vence = DateFormat("d 'de' MMMM", 'es').format(plan.endDate);
    final days = plan.daysRemaining;
    final daysLabel = days == 0
        ? 'Vence hoy'
        : days == 1
            ? 'Vence mañana'
            : 'Vence en $days días';

    return _buildDarkCard(
      onTap: widget.onGoToPlanes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name,
              style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 38,
                  weight: FontWeight.w400)),
          const SizedBox(height: 8),
          Text('Vence el $vence',
              style: KaliText.body(
                  KaliColors.warmWhite.withValues(alpha: 0.65), size: 14)),
          const SizedBox(height: 22),
          Row(children: [
            _infoPill(daysLabel),
            if (plan.maxReservations != null) ...[
              const SizedBox(width: 8),
              _infoPill('${plan.maxReservations} clases'),
            ],
          ]),
          const SizedBox(height: 14),
          _ctaButton(label: 'Ver plan', onTap: widget.onGoToPlanes),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 28,
                  weight: FontWeight.w400)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: KaliText.body(
                      KaliColors.warmWhite.withValues(alpha: 0.72), size: 14)
                  .copyWith(height: 1.5)),
        ],
      ),
    );
  }

  // ── Shared card shell ──────────────────────────────────────────────────────

  Widget _buildDarkCard({required Widget child, VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: KaliColors.espresso,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -58,
                top: 12,
                child: _decorativeCircle(160, alpha: 0.52),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _decorativeCircle(double size, {required double alpha}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KaliColors.espressoL.withValues(alpha: alpha),
      ),
    );
  }

  Widget _ctaButton({required String label, VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KaliColors.clay,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: KaliText.body(KaliColors.background, size: 14,
                  weight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: KaliText.body(KaliColors.warmWhite.withValues(alpha: 0.72),
              size: 11, weight: FontWeight.w500)),
    );
  }

  Widget _statPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFD7C2B4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: KaliText.body(
                    KaliColors.warmWhite.withValues(alpha: 0.88),
                    size: 13, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: KaliText.label(KaliColors.clayDark)
          .copyWith(fontSize: 10, letterSpacing: 2.1),
    );
  }
}
