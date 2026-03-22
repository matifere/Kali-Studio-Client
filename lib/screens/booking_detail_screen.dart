import 'package:flutter/material.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import 'package:kali_studio/widgets/kali_button.dart';
import '../models/models.dart';
import '../theme/kali_theme.dart';
import 'book_class_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final PilatesClass pilatesClass;

  const BookingDetailScreen({super.key, required this.pilatesClass});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PilatesClass> _reservations = [];
  bool _reservationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _syncReservations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_reservationsInitialized) {
      _syncReservations();
    }

    final hasReservations = _reservations.isNotEmpty;
    final cls = hasReservations ? _reservations.first : widget.pilatesClass;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: _buildFab(),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildHeaderText(),
              const SizedBox(height: 28),
              if (hasReservations) ...[
                _buildHeroCard(cls),
                const SizedBox(height: 20),
                ..._buildSupportingCards(cls),
                const SizedBox(height: 28),
                _buildDetailsPanel(cls),
              ] else
                _buildEmptyReservationsState(),
              const SizedBox(height: 28),
              _buildHistoryPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF2E1B16)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 22,
        ),
        const SizedBox(width: 10),
        Text(
          'Sienna Wellness',
          style: GoogleFontsHelper.cormorant(
            const Color(0xFF2E1B16),
            18,
            italic: true,
            weight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E6D6),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.person_rounded,
              size: 18, color: Color(0xFF8C6C54)),
        ),
      ],
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Reservas',
          style: GoogleFontsHelper.cormorant(
            const Color(0xFF2E1B16),
            42,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gestiona tus proximas sesiones de bienestar y\nmanten tu ritmo de autocuidado.',
          style: KaliText.body(
            const Color(0xFF97775E),
            size: 14,
            weight: FontWeight.w400,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildHeroCard(PilatesClass cls) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1814), Color(0xFF3A241E)],
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
                  Icon(Icons.more_vert_rounded,
                      color: Colors.white.withValues(alpha: 0.65), size: 18),
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
                  _buildInstructorAvatar(),
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
                  GestureDetector(
                    onTap: _scrollToDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F2E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Detalles',
                        style: KaliText.body(
                          const Color(0xFF2E1B16),
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

  List<Widget> _buildSupportingCards(PilatesClass cls) {
    final related = _reservations
        .where((item) => item.id != cls.id)
        .take(2)
        .toList(growable: false);

    final cards = <Widget>[];
    for (var i = 0; i < related.length; i++) {
      final item = related[i];
      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: i == related.length - 1 ? 0 : 14),
          child: _BookingPreviewCard(
            title: item.name,
            badge: i == 0 ? 'EN 3 DIAS' : 'PROXIMA SEMANA',
            dateText: _supportDateText(item, i),
            instructor: item.instructor,
            onPrimaryTap: _scrollToDetails,
            onSecondaryTap: () => _cancelReservation(item),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildDetailsPanel(PilatesClass cls) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E7),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de la reserva',
            style: GoogleFontsHelper.cormorant(
              const Color(0xFF2E1B16),
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
              _InfoChip(label: cls.room),
              _InfoChip(label: cls.level),
              _InfoChip(label: cls.equipment),
            ],
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            title: 'Instructora',
            value: '${cls.instructor} · ${KaliData.luciana.certification}',
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.event_seat_outlined,
            title: 'Disponibilidad',
            value: '${cls.availableSpots} de ${cls.totalSpots} lugares libres',
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.location_on_outlined,
            title: 'Estudio',
            value: 'Kali Studio · Palermo · ${cls.room}',
          ),
          const SizedBox(height: 18),
          Text(
            cls.description,
            style: KaliText.body(
              const Color(0xFF6A5646),
              size: 13,
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
          const SizedBox(height: 20),
          if (!cls.isBooked)
            KaliButton(text: 'Confirmar reserva', onPressed: _onBook)
          else
            KaliButton(
              text: 'Cancelar reserva',
              onPressed: () => _cancelReservation(cls),
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
          Container(height: 1, color: const Color(0xFFE9DFD1)),
          const SizedBox(height: 22),
          Text(
            'Quieres ver tus clases pasadas?',
            style: KaliText.body(
              const Color(0xFF8D7561),
              size: 14,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _scrollToTop,
            child: Text(
              'Ver Historial de Reservas',
              style: KaliText.body(
                const Color(0xFF2E1B16),
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
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined,
              color: Color(0xFF8A6A53), size: 30),
          const SizedBox(height: 12),
          Text(
            'No tenes reservas activas',
            style: GoogleFontsHelper.cormorant(
              const Color(0xFF2E1B16),
              28,
              weight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando reserves una nueva clase, va a aparecer aca.',
            style: KaliText.body(
              const Color(0xFF8D7561),
              size: 14,
              weight: FontWeight.w400,
            ).copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _openBookClassScreen,
      backgroundColor: const Color(0xFF2E1B16),
      child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
    );
  }

  Widget _buildInstructorAvatar() {
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
          KaliData.luciana.initials,
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
    final endHour = _formatEndTime(cls.time, cls.period, cls.durationMin);
    return 'Martes 13 Oct, ${cls.time} ${cls.period} - $endHour';
  }

  String _supportDateText(PilatesClass cls, int index) {
    if (index == 0) {
      return 'Viernes 16 Oct, ${cls.time} ${cls.period}';
    }
    return 'Lunes 19 Oct, ${cls.time} ${cls.period}';
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
    _scrollController.animateTo(
      520,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onBook() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KaliColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmationSheet(cls: widget.pilatesClass),
    );
  }

  void _openBookClassScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookClassScreen()),
    );
  }

  void _syncReservations() {
    _reservations = List<PilatesClass>.from(
      KaliData.todayClasses.where((item) => item.isBooked),
    );

    if (_reservations.every((item) => item.id != widget.pilatesClass.id) &&
        widget.pilatesClass.isBooked) {
      _reservations.insert(0, widget.pilatesClass);
    }

    _reservationsInitialized = true;
  }

  void _cancelReservation(PilatesClass cls) {
    setState(() {
      _reservations.removeWhere((item) => item.id == cls.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva cancelada',
          style: KaliText.body(KaliColors.clay),
        ),
        backgroundColor: KaliColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
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
                    const Color(0xFF3A271F),
                    20,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE4D7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: KaliText.label(const Color(0xFF8B715D))
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
              GestureDetector(
                onTap: onPrimaryTap,
                child: Text(
                  'Editar',
                  style: KaliText.body(
                    const Color(0xFF7E614D),
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onSecondaryTap,
                child: Text(
                  'Cancelar',
                  style: KaliText.body(
                    const Color(0xFF9A8571),
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
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF7D6A5B)),
        const SizedBox(width: 7),
        Text(
          text,
          style: KaliText.body(
            const Color(0xFF7D6A5B),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECE3D8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KaliText.body(
          const Color(0xFF6D5949),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E7DA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF7E614D)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KaliText.body(
                  const Color(0xFF8E7664),
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: KaliText.body(
                  const Color(0xFF3B2A22),
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

class _ConfirmationSheet extends StatelessWidget {
  final PilatesClass cls;

  const _ConfirmationSheet({required this.cls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KaliColors.sand2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: KaliColors.espresso,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: KaliColors.clay, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            'Reserva confirmada',
            style: GoogleFontsHelper.cormorant(KaliColors.espresso, 24),
          ),
          const SizedBox(height: 8),
          Text(
            '${cls.name} · ${cls.time} ${cls.period}',
            style: KaliText.caption(KaliColors.clayDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          KaliButton(
            text: 'Ver mis reservas',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          KaliButton(
            text: 'Volver al inicio',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            outlined: true,
          ),
        ],
      ),
    );
  }
}
