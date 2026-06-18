import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../home_screen.dart';
import '../../models/models.dart';
import '../../supabase/plan_service.dart';
import '../../theme/kali_theme.dart';
import '../../utils/auth_utils.dart';
import '../../widgets/google_fonts_helper.dart';
import '../../widgets/motion.dart';
import '../../widgets/web_page_wrapper.dart';

class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  late final PageController _pageCtrl;
  late final Future<List<Plan>> _plansFuture;
  late Future<UserPlan?> _activePlanFuture;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _plansFuture = PlanService.fetchAvailablePlans();
    _activePlanFuture = PlanService.fetchActivePlan();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _refreshActivePlan() {
    setState(() {
      _activePlanFuture = PlanService.fetchActivePlan();
    });
  }

  void _goTo(int index, int total) {
    if (index < 0 || index >= total) return;
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _showPlanDetail(UserPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlanDetailSheet(plan: plan),
    );
  }

  Future<void> _showActivateSheet(Plan plan) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActivatePlanSheet(plan: plan),
    );
    if (confirmed == true) {
      HomeScreen.invalidateCache();
      _refreshActivePlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Tu plan actual'),
                      const SizedBox(height: 14),
                      _buildActivePlanCard(),
                      const SizedBox(height: 36),
                      _sectionLabel('Planes disponibles'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildCarousel(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return FutureBuilder<List<Plan>>(
      future: _plansFuture,
      builder: (context, plansSnap) {
        if (plansSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 340,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final plans = plansSnap.data ?? [];
        if (plans.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KaliColors.sand,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                'No hay planes disponibles por el momento.',
                style: KaliText.body(KaliColors.clayDark, size: 14),
              ),
            ),
          );
        }
        return FutureBuilder<UserPlan?>(
          future: _activePlanFuture,
          builder: (context, activeSnap) {
            final activePlanId = activeSnap.data?.planId;
            return Column(
              children: [
                SizedBox(
                  height: 340,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: plans.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) {
                      final alreadyActive = activePlanId == plans[i].id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildPlanCard(
                          plans[i],
                          featured: i == 0,
                          alreadyActive: alreadyActive,
                          onActivate: alreadyActive
                              ? null
                              : () => _showActivateSheet(plans[i]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _arrowButton(
                      icon: Icons.arrow_back_rounded,
                      enabled: _currentPage > 0,
                      onTap: () => _goTo(_currentPage - 1, plans.length),
                    ),
                    const SizedBox(width: 16),
                    ...List.generate(
                        plans.length, (i) => _dot(i == _currentPage)),
                    const SizedBox(width: 16),
                    _arrowButton(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _currentPage < plans.length - 1,
                      onTap: () => _goTo(_currentPage + 1, plans.length),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? KaliColors.espresso : KaliColors.sand2,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? KaliColors.warmWhite : KaliColors.clayDark,
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? KaliColors.espresso : KaliColors.sand2,
      ),
    );
  }

  Widget _buildHero() {
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
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KaliColors.espressoL.withValues(alpha: 0.55),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUSCRIPCIONES',
                style: KaliText.label(KaliColors.clay)
                    .copyWith(fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Elegí el plan que mejor se adapta a tu ritmo.',
                style: KaliText.body(
                  KaliColors.warmWhite.withValues(alpha: 0.72),
                  size: 14,
                  weight: FontWeight.w400,
                ).copyWith(height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard() {
    return FutureBuilder<UserPlan?>(
      future: _activePlanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: KaliColors.espresso,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final plan = snapshot.data;
        if (plan == null) {
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
                Text('Sin plan activo',
                    style: GoogleFontsHelper.cormorant(
                        KaliColors.warmWhite, 28, weight: FontWeight.w400)),
                const SizedBox(height: 8),
                Text(
                  'Activá un plan desde la sección de abajo.',
                  style: KaliText.body(
                      KaliColors.warmWhite.withValues(alpha: 0.65), size: 14),
                ),
              ],
            ),
          );
        }
        final vence =
            DateFormat("d 'de' MMMM", 'es').format(plan.endDate);
        final dias = plan.daysRemaining;
        final diasLabel = dias == 0
            ? 'Vence hoy'
            : dias == 1
                ? 'Vence mañana'
                : 'Vence en $dias días';
        return Container(
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
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KaliColors.espressoL.withValues(alpha: 0.52),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: GoogleFontsHelper.cormorant(
                          KaliColors.warmWhite, 38, weight: FontWeight.w400)),
                  const SizedBox(height: 8),
                  Text('Vence el $vence',
                      style: KaliText.body(
                          KaliColors.warmWhite.withValues(alpha: 0.65),
                          size: 14)),
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _infoPill(diasLabel),
                          if (plan.weeklyClasses != null) ...[
                            const SizedBox(width: 8),
                            _infoPill('${plan.weeklyClasses} cl/sem'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Pressable(
                        onTap: () => _showPlanDetail(plan),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: KaliColors.clay,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Ver detalle',
                              style: KaliText.body(KaliColors.background,
                                  size: 14, weight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(Plan plan,
      {bool featured = false,
      bool alreadyActive = false,
      VoidCallback? onActivate}) {
    final bg = featured ? KaliColors.espresso : KaliColors.sand;
    final textPrimary = featured ? KaliColors.warmWhite : KaliColors.espresso;
    final textSecondary = featured
        ? KaliColors.warmWhite.withValues(alpha: 0.65)
        : KaliColors.clayDark;
    final checkBg = featured
        ? Colors.white.withValues(alpha: 0.12)
        : KaliColors.sand2;
    final checkIcon = featured
        ? KaliColors.warmWhite.withValues(alpha: 0.80)
        : KaliColors.clayDark;
    final ctaBg = featured ? KaliColors.clay : KaliColors.espresso;
    final ctaText = featured ? KaliColors.background : KaliColors.warmWhite;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(32),
        border: featured
            ? null
            : Border.all(color: KaliColors.sand2, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Stack(
        children: [
          if (featured)
            Positioned(
              right: -50,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KaliColors.espressoL.withValues(alpha: 0.5),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featured)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KaliColors.clay,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'MÁS POPULAR',
                    style: KaliText.label(KaliColors.background)
                        .copyWith(fontSize: 9, letterSpacing: 1.6),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFontsHelper.cormorant(
                            textPrimary, 32, weight: FontWeight.w400),
                        ),
                        Text(
                          plan.description,
                          style: KaliText.body(textSecondary, size: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${plan.formattedPrice}',
                        style: GoogleFontsHelper.cormorant(
                          textPrimary, 34, weight: FontWeight.w400),
                      ),
                      Text(
                        plan.currency,
                        style: KaliText.body(textSecondary,
                            size: 11, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (plan.weeklyClasses != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _planPill(
                    '${plan.weeklyClasses} clase${plan.weeklyClasses == 1 ? '' : 's'} por semana',
                    checkBg, checkIcon,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.features
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: checkBg,
                                ),
                                child: Icon(Icons.check,
                                    size: 12, color: checkIcon),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                f,
                                style: KaliText.body(checkIcon,
                                    size: 13, weight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Pressable(
                onTap: onActivate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: alreadyActive
                        ? (featured
                            ? Colors.white.withValues(alpha: 0.15)
                            : KaliColors.sand2)
                        : ctaBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (alreadyActive) ...[
                        Icon(Icons.check_circle_outline_rounded,
                            size: 15,
                            color: featured
                                ? KaliColors.warmWhite.withValues(alpha: 0.7)
                                : KaliColors.clayDark),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        alreadyActive ? 'Plan activo' : 'Activar plan',
                        textAlign: TextAlign.center,
                        style: KaliText.body(
                          alreadyActive
                              ? (featured
                                  ? KaliColors.warmWhite.withValues(alpha: 0.7)
                                  : KaliColors.clayDark)
                              : ctaText,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
      child: Text(
        text,
        style: KaliText.body(
          KaliColors.warmWhite.withValues(alpha: 0.80),
          size: 11,
          weight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _planPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: KaliText.body(fg, size: 12, weight: FontWeight.w600)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: KaliText.label(KaliColors.clayDark)
          .copyWith(fontSize: 10, letterSpacing: 2.1),
    );
  }
}

// ─── Sheet de confirmación ────────────────────────────────────────────────────
class _ActivatePlanSheet extends StatefulWidget {
  final Plan plan;
  const _ActivatePlanSheet({required this.plan});

  @override
  State<_ActivatePlanSheet> createState() => _ActivatePlanSheetState();
}

class _ActivatePlanSheetState extends State<_ActivatePlanSheet> {
  bool _loadingMethod = true; // fetching payment method on open
  bool _loading = false;
  bool _awaitingVerification = false;
  String? _alias;
  String? _mpUrl;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethod();
  }

  Future<void> _fetchPaymentMethod() async {
    try {
      final preference = await PlanService.createPaymentPreference(widget.plan.id);
      if (!mounted) return;
      switch (preference) {
        case MercadoPagoPayment(:final url):
          setState(() { _loadingMethod = false; _mpUrl = url; });
        case TransferPayment(:final alias):
          setState(() { _loadingMethod = false; _alias = alias; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMethod = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeError(
            e,
            fallback: 'No pudimos iniciar el pago. Intentá de nuevo.',
          )),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openMp() {
    if (_mpUrl == null) return;
    setState(() => _awaitingVerification = true);
    launchUrl(Uri.parse(_mpUrl!), webOnlyWindowName: '_blank');
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final plan = await PlanService.fetchActivePlan();
      if (!mounted) return;
      if (plan != null && plan.planId == widget.plan.id) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Plan activado correctamente!',
                style: KaliText.body(KaliColors.clay)),
            backgroundColor: KaliColors.espresso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El pago aún no fue confirmado. Esperá unos segundos e intentá de nuevo.',
              style: KaliText.body(KaliColors.warmWhite.withValues(alpha: 0.9)),
            ),
            backgroundColor: KaliColors.espresso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _infoText {
    if (_alias != null) return 'Hacé la transferencia al alias indicado y avisale a tu instructor para activar tu plan.';
    if (_awaitingVerification) return 'Una vez aprobado el pago, tu plan se activa automáticamente.';
    return 'Serás redirigido a MercadoPago para completar el pago de forma segura.';
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
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
              plan.name,
              style: GoogleFontsHelper.cormorant(
                  KaliColors.espresso, 34, weight: FontWeight.w400),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${plan.formattedPrice}',
                  style: GoogleFontsHelper.cormorant(
                      KaliColors.espresso, 28, weight: FontWeight.w400),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(plan.currency,
                      style: KaliText.body(KaliColors.clayDark,
                          size: 12, weight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (plan.weeklyClasses != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: KaliColors.sand,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: KaliColors.espresso),
                    const SizedBox(width: 8),
                    Text(
                      '${plan.weeklyClasses} clase${plan.weeklyClasses == 1 ? '' : 's'} por semana',
                      style: KaliText.body(KaliColors.espresso,
                          size: 14, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!_loadingMethod)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KaliColors.sand,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: KaliColors.clayDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _infoText,
                        style: KaliText.body(KaliColors.clayDark, size: 13)
                            .copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_loadingMethod)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_alias != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: KaliColors.sand,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alias de transferencia',
                            style: KaliText.body(KaliColors.clayDark,
                                size: 12, weight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _alias!,
                            style: KaliText.body(KaliColors.espresso,
                                size: 16, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _alias!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alias copiado')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      color: KaliColors.espresso,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: KaliColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Ya transferí, verificar',
                          style: KaliText.body(KaliColors.sand,
                              size: 14, weight: FontWeight.w700),
                        ),
                ),
              ),
            ] else if (!_awaitingVerification)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _openMp,
                  style: FilledButton.styleFrom(
                    backgroundColor: KaliColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Continuar con el pago',
                        style: KaliText.body(KaliColors.sand,
                            size: 14, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: KaliColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Ya pagué, verificar',
                          style: KaliText.body(KaliColors.sand,
                              size: 14, weight: FontWeight.w700),
                        ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: Text('Cancelar',
                    style: KaliText.body(KaliColors.clayDark,
                        size: 14, weight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet detalle del plan activo ────────────────────────────────────────────
class _PlanDetailSheet extends StatelessWidget {
  final UserPlan plan;
  const _PlanDetailSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final inicio = DateFormat("d 'de' MMMM yyyy", 'es').format(plan.startDate);
    final fin = DateFormat("d 'de' MMMM yyyy", 'es').format(plan.endDate);
    final dias = plan.daysRemaining;
    final diasLabel = dias == 0
        ? 'Vence hoy'
        : dias == 1
            ? 'Vence mañana'
            : '$dias días restantes';

    return Container(
      decoration: BoxDecoration(
        color: KaliColors.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
            plan.name,
            style: GoogleFontsHelper.cormorant(
                KaliColors.espresso, 34, weight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          _row('Estado', _statusLabel(plan.status)),
          _divider(),
          _row('Inicio', inicio),
          _divider(),
          _row('Vencimiento', fin),
          _divider(),
          _row('Tiempo restante', diasLabel),
          if (plan.weeklyClasses != null) ...[
            _divider(),
            _row('Clases por semana', '${plan.weeklyClasses}'),
          ],
          const SizedBox(height: 28),
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
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':   return 'Activo';
      case 'pending':  return 'Pendiente';
      case 'expired':  return 'Vencido';
      default:         return status;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: KaliText.body(KaliColors.clayDark,
                  size: 13, weight: FontWeight.w500)),
          Text(value,
              style: KaliText.body(KaliColors.espresso,
                  size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: KaliColors.sand2, thickness: 1, height: 1);
}
