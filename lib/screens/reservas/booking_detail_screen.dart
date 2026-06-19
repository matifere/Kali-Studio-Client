import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import 'package:kali_studio/widgets/kali_button.dart';
import '../../models/models.dart';
import '../../supabase/booking_service.dart';
import '../../theme/kali_theme.dart';
import '../../utils/auth_utils.dart';
import 'booking_history_screen.dart';
import '../../widgets/motion.dart';
import '../../widgets/web_page_wrapper.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _detailsPanelKey = GlobalKey();
  List<PilatesClass> _reservations = [];
  PilatesClass? _selectedReservation;
  bool _isLoading = true;
  bool _isCancelling = false;

  Color get _pageBackground => KaliColors.warmWhite;
  Color get _surfaceColor => KaliColors.sand;
  Color get _panelColor => KaliColors.sand;
  Color get _primaryText => KaliColors.espresso;
  Color get _secondaryText => KaliColors.clayDark;
  Color get _mutedText => KaliColors.clayDark;
  Color get _accentSurface => KaliColors.clay;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final reservations = await BookingService.fetchUserReservations();
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _selectedReservation = reservations.firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar las reservas. Intentá de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReservations = _reservations.isNotEmpty;
    final heroClass = hasReservations ? _reservations.first : null;
    final detailsClass = _selectedReservation ?? heroClass;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 28),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (hasReservations && heroClass != null) ...[
                _buildHeroCard(heroClass),
                const SizedBox(height: 20),
                ..._buildSupportingCards(heroClass),
                const SizedBox(height: 28),
                if (detailsClass != null) _buildDetailsPanel(detailsClass),
              ] else
                _buildEmptyReservationsState(),
              const SizedBox(height: 28),
              _buildHistoryPrompt(),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildHeroCard(PilatesClass cls) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1F14), Color(0xFF3D2B1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -72,
            top: -72,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'PROXIMA',
                      style: KaliText.label(Colors.white70)
                          .copyWith(fontSize: 10, letterSpacing: 1.9),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 42),
              Text(
                cls.name,
                style: GoogleFontsHelper.cormorant(
                  Colors.white,
                  28,
                  weight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: Colors.white.withValues(alpha: 0.72)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _heroScheduleText(cls),
                      style: KaliText.body(
                        Colors.white.withValues(alpha: 0.72),
                        size: 12,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  _buildInstructorAvatar(cls.instructor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cls.instructor,
                      style: KaliText.body(
                        Colors.white,
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () {
                      setState(() => _selectedReservation = _reservations.firstOrNull);
                      _scrollToDetails();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: _accentSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Detalles',
                        style: KaliText.body(
                          Colors.white,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSupportingCards(PilatesClass first) {
    final related = _reservations
        .where((item) => item.id != first.id)
        .toList(growable: false);

    final cards = <Widget>[];
    for (var i = 0; i < related.length; i++) {
      final item = related[i];
      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: i == related.length - 1 ? 0 : 14),
          child: FadeSlideIn(
            key: ValueKey(item.id),
            delay: Duration(milliseconds: 60 * i),
            child: _BookingPreviewCard(
              title: item.name,
              badge: _relativeDateBadge(item.sessionDate),
              dateText: _supportDateText(item),
              instructor: item.instructor,
              onPrimaryTap: () {
                setState(() => _selectedReservation = item);
                _scrollToDetails();
              },
              onSecondaryTap: () { _showCancelConfirmation(item); },
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildDetailsPanel(PilatesClass cls) {
    return Container(
      key: _detailsPanelKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de la reserva',
            style: GoogleFontsHelper.cormorant(
              _primaryText,
              28,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: '${cls.durationMin} min'),
              if (cls.room.isNotEmpty) _InfoChip(label: cls.room),
              if (cls.level.isNotEmpty) _InfoChip(label: cls.level),
              if (cls.equipment.isNotEmpty) _InfoChip(label: cls.equipment),
            ],
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            title: 'Instructora',
            value: cls.instructor.isEmpty ? 'Por confirmar' : cls.instructor,
          ),
          if (cls.totalSpots > 0) ...[
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.event_seat_outlined,
              title: 'Disponibilidad',
              value: '${cls.availableSpots} de ${cls.totalSpots} lugares libres',
            ),
          ],
          if (cls.room.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.location_on_outlined,
              title: 'Estudio',
              value: cls.room,
            ),
          ],
          if (cls.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              cls.description,
              style: KaliText.body(
                _secondaryText,
                size: 13,
                weight: FontWeight.w400,
              ).copyWith(height: 1.7),
            ),
          ],
          const SizedBox(height: 20),
          KaliButton(
            text: _isCancelling ? 'Cancelando...' : 'Cancelar reserva',
            onPressed: _isCancelling ? null : () { _showCancelConfirmation(cls); },
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
      child: Column(
        children: [
          Container(height: 1, color: KaliColors.sand2),
          const SizedBox(height: 22),
          Text(
            'Quieres ver tus clases pasadas?',
            style: KaliText.body(
              _mutedText,
              size: 14,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BookingHistoryScreen()),
            ),
            child: Text(
              'Ver Historial de Reservas',
              style: KaliText.body(
                _primaryText,
                size: 14,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReservationsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, color: _secondaryText, size: 30),
          const SizedBox(height: 12),
          Text(
            'No tenes reservas activas',
            style: GoogleFontsHelper.cormorant(
              _primaryText,
              28,
              weight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando reserves una nueva clase, va a aparecer aca.',
            style: KaliText.body(
              _mutedText,
              size: 14,
              weight: FontWeight.w400,
            ).copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorAvatar(String instructor) {
    final initials = instructor.trim().isEmpty
        ? '--'
        : instructor
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF184B63),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          initials,
          style: KaliText.body(
            Colors.white,
            size: 12,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _heroScheduleText(PilatesClass cls) {
    final datePart = cls.sessionDate != null
        ? '${DateFormat("d 'de' MMM", 'es').format(cls.sessionDate!)} · '
        : '';
    if (cls.time.isEmpty) return '${datePart}Horario por confirmar';
    final endHour = _formatEndTime(cls.time, cls.period, cls.durationMin);
    return '$datePart${cls.time} ${cls.period} - $endHour';
  }

  String _supportDateText(PilatesClass cls) {
    final datePart = cls.sessionDate != null
        ? '${DateFormat("d 'de' MMM", 'es').format(cls.sessionDate!)} · '
        : '';
    if (cls.time.isEmpty) return '${datePart}Horario por confirmar';
    return '$datePart${cls.time} ${cls.period}';
  }

  String _relativeDateBadge(DateTime? date) {
    if (date == null) return 'PRÓXIMA';
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = date.difference(todayDate).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'MAÑANA';
    if (diff <= 7) return 'EN $diff DÍAS';
    return 'PRÓXIMA SEMANA';
  }

  String _formatEndTime(String startTime, String period, int durationMin) {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.last) ?? 0;
    var hour24 = hour % 12;
    if (period.toUpperCase() == 'PM') {
      hour24 += 12;
    }

    final startMinutes = hour24 * 60 + minute;
    final endMinutes = startMinutes + durationMin;
    final endHour24 = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;
    final endPeriod = endHour24 >= 12 ? 'PM' : 'AM';
    final normalizedHour = endHour24 % 12 == 0 ? 12 : endHour24 % 12;

    return '${normalizedHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';
  }

  void _scrollToDetails() {
    final ctx = _detailsPanelKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }



  DateTime? _classDateTime(PilatesClass cls) {
    if (cls.sessionDate == null || cls.time.isEmpty) return null;
    final parts = cls.time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(
      cls.sessionDate!.year,
      cls.sessionDate!.month,
      cls.sessionDate!.day,
      hour,
      minute,
    );
  }

  bool _isWithin2Hours(PilatesClass cls) {
    final classTime = _classDateTime(cls);
    if (classTime == null) return false;
    final diff = classTime.difference(DateTime.now());
    return diff.inHours < 2;
  }

  Future<void> _showCancelConfirmation(PilatesClass cls) async {
    final within2h = _isWithin2Hours(cls);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CancelConfirmSheet(
        cls: cls,
        within2h: within2h,
      ),
    );

    if (confirmed == true) _cancelReservation(cls);
  }

  Future<void> _cancelReservation(PilatesClass cls) async {
    final reservationId = cls.reservationId;
    if (reservationId == null) return;

    setState(() => _isCancelling = true);

    try {
      await BookingService.cancelReservation(reservationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva cancelada',
            style: KaliText.body(KaliColors.clay),
          ),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeError(
            e,
            fallback: 'No se pudo cancelar la reserva. Intentá de nuevo.',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }
}

class _BookingPreviewCard extends StatelessWidget {
  final String title;
  final String badge;
  final String dateText;
  final String instructor;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  const _BookingPreviewCard({
    required this.title,
    required this.badge,
    required this.dateText,
    required this.instructor,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = KaliColors.sand;
    final primaryText = KaliColors.espresso;
    final pillBackground = KaliColors.sand2;
    final pillText = KaliColors.clayDark;
    final actionText = KaliColors.espresso;
    final secondaryActionText = KaliColors.clayDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFontsHelper.cormorant(
                    primaryText,
                    20,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: KaliText.label(pillText)
                      .copyWith(fontSize: 9, letterSpacing: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MiniInfoRow(
            icon: Icons.event_outlined,
            text: dateText,
          ),
          const SizedBox(height: 8),
          _MiniInfoRow(
            icon: Icons.person_outline_rounded,
            text: instructor,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Pressable(
                onTap: onPrimaryTap,
                child: Text(
                  'Ver detalles',
                  style: KaliText.body(
                    actionText,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Pressable(
                onTap: onSecondaryTap,
                child: Text(
                  'Cancelar',
                  style: KaliText.body(
                    secondaryActionText,
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final textColor = KaliColors.clayDark;
    return Row(
      children: [
        Icon(icon, size: 15, color: textColor),
        const SizedBox(width: 7),
        Text(
          text,
          style: KaliText.body(
            textColor,
            size: 12,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final background = KaliColors.sand2;
    final textColor = KaliColors.espresso;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KaliText.body(
          textColor,
          size: 12,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final iconBackground = KaliColors.sand2;
    final iconColor = KaliColors.clayDark;
    final titleColor = KaliColors.clayDark;
    final valueColor = KaliColors.espresso;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KaliText.body(
                  titleColor,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: KaliText.body(
                  valueColor,
                  size: 13,
                  weight: FontWeight.w500,
                ).copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelConfirmSheet extends StatelessWidget {
  final PilatesClass cls;
  final bool within2h;

  const _CancelConfirmSheet({
    required this.cls,
    required this.within2h,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = KaliColors.espresso;
    final mutedText = KaliColors.clayDark;

    return Container(
      decoration: BoxDecoration(
        color: KaliColors.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
            'Cancelar reserva',
            style: GoogleFontsHelper.cormorant(
              primaryText,
              30,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cls.name,
            style: KaliText.body(
              mutedText,
              size: 14,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: KaliColors.clay.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  within2h
                      ? Icons.block_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: KaliColors.clay,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    within2h
                        ? 'No podés cancelar esta clase. Faltan menos de 2 horas y el período de cancelación ya cerró.'
                        : 'Una vez confirmada, solo podés cancelar hasta 2 horas antes de la clase.',
                    style: KaliText.body(
                      primaryText,
                      size: 13,
                      weight: FontWeight.w400,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!within2h) ...[
            KaliButton(
              text: 'Confirmar cancelación',
              onPressed: () => Navigator.pop(context, true),
              outlined: true,
            ),
            const SizedBox(height: 12),
          ],
          KaliButton(
            text: within2h ? 'Entendido' : 'Volver',
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
