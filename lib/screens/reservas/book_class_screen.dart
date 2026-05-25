import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import '../../models/models.dart';
import '../../services/push_notification_service.dart';
import '../../supabase/booking_service.dart';
import '../../supabase/waitlist_service.dart';
import '../../theme/kali_theme.dart';
import '../../widgets/web_page_wrapper.dart';

class BookClassScreen extends StatefulWidget {
  const BookClassScreen({super.key});

  @override
  State<BookClassScreen> createState() => _BookClassScreenState();
}

class _BookClassScreenState extends State<BookClassScreen> {
  final List<String> _weekDays = const [
    'Lu',
    'Ma',
    'Mi',
    'Ju',
    'Vi',
    'Sa',
    'Do',
  ];

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  List<PilatesClass> _sessions = [];
  bool _isLoadingSessions = false;
  Set<String> _datesWithSessions = {};
  final Set<String> _fullSessionIds = {};

  Color get _pageBackground => KaliColors.warmWhite;
  Color get _surfaceColor => KaliColors.sand;
  Color get _primaryText => KaliColors.espresso;
  Color get _secondaryText => KaliColors.clayDark;
  Color get _mutedText => KaliColors.clayDark;
  Color get _pillBackground => KaliColors.sand2;
  Color get _calendarDayMuted => KaliColors.clayDark.withValues(alpha: 0.6);
  Color get _calendarSelectedBackground => KaliColors.espresso;
  Color get _calendarSelectedText => KaliColors.background;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
    _loadDatesWithSessions(_visibleMonth);
    _loadSessionsForDate(_selectedDate);
  }

  Future<void> _loadDatesWithSessions(DateTime month) async {
    final dates = await BookingService.fetchDatesWithSessions(month);
    if (!mounted) return;
    setState(() => _datesWithSessions = dates);
  }

  Future<void> _loadSessionsForDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await BookingService.fetchSessionsForDate(date);
      if (!mounted) return;
      setState(() => _sessions = sessions);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar las clases. Intentá de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildCalendar(context),
              const SizedBox(height: 34),
              _buildAvailabilitySection(),
            ],
          ),
        ),
        ),
      ),
    );
  }


  Widget _buildCalendar(BuildContext context) {
    final days = _calendarDaysForMonth(_visibleMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 44) / 7;
        return _buildCalendarContent(days, cellWidth);
      },
    );
  }

  Widget _buildCalendarContent(List<DateTime> days, double cellWidth) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(
                      DateFormat('MMMM yyyy', 'es').format(_visibleMonth)),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFontsHelper.cormorant(
                    _primaryText,
                    24,
                    italic: true,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final newMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                  setState(() => _visibleMonth = newMonth);
                  _loadDatesWithSessions(newMonth);
                },
                child: Icon(Icons.chevron_left_rounded,
                    color: _mutedText, size: 24),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final newMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                  setState(() => _visibleMonth = newMonth);
                  _loadDatesWithSessions(newMonth);
                },
                child: Icon(Icons.chevron_right_rounded,
                    color: _mutedText, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: _weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: KaliText.label(_calendarDayMuted)
                            .copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 0,
            runSpacing: 10,
            children: days.map((date) {
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              final isPast = date.isBefore(todayDate);
              final isOutsideMonth = date.month != _visibleMonth.month;
              final isSelected = _isSameDay(date, _selectedDate);
              final hasClasses =
                  _datesWithSessions.contains(_dateStr(date));

              Color textColor;
              if (isSelected) {
                textColor = _calendarSelectedText;
              } else if (isPast || isOutsideMonth) {
                textColor = _calendarDayMuted;
              } else {
                textColor = _primaryText;
              }

              return SizedBox(
                width: cellWidth,
                child: Center(
                  child: GestureDetector(
                    onTap: isPast ? null : () {
                      setState(() => _selectedDate = date);
                      _loadSessionsForDate(date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? _calendarSelectedBackground
                            : (hasClasses && !isPast && !isOutsideMonth)
                                ? KaliColors.clay.withValues(alpha: 0.18)
                                : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: KaliText.body(
                            textColor,
                            size: 14,
                            weight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Horarios Disponibles',
                overflow: TextOverflow.ellipsis,
                style: GoogleFontsHelper.cormorant(
                  _primaryText,
                  24,
                  italic: true,
                  weight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _pillBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _formattedSelectedDate(),
                style: KaliText.label(_mutedText)
                    .copyWith(fontSize: 9, letterSpacing: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isLoadingSessions)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_sessions.isEmpty)
          _buildEmptyState()
        else
          ..._sessions.asMap().entries.map((entry) {
            final index = entry.key;
            final cls = entry.value;
            final isFull = cls.availableSpots == 0 || _fullSessionIds.contains(cls.id);
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == _sessions.length - 1 ? 0 : 14),
              child: _ScheduleCard(
                cls: cls,
                isFull: isFull,
                onBook: (isFull || cls.isBooked) ? null : () => _showBookConfirmation(cls),
                onJoinWaitlist: (isFull && !cls.isBooked && !cls.isInWaitlist) ? () => _joinWaitlist(cls) : null,
                onLeaveWaitlist: cls.isInWaitlist ? () => _leaveWaitlist(cls) : null,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, color: _mutedText, size: 28),
          const SizedBox(height: 10),
          Text(
            'No hay horarios cargados para este dia',
            style: KaliText.body(
              _primaryText,
              size: 14,
              weight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Proba seleccionando otra fecha del calendario.',
            style: KaliText.body(
              _secondaryText,
              size: 12,
              weight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<DateTime> _calendarDaysForMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final leadingDays = firstOfMonth.weekday - 1;
    final totalCells = ((leadingDays + lastOfMonth.day) / 7).ceil() * 7;
    final startDate = firstOfMonth.subtract(Duration(days: leadingDays));

    return List<DateTime>.generate(
      totalCells,
      (index) => DateTime(
        startDate.year,
        startDate.month,
        startDate.day + index,
      ),
    );
  }

  String _formattedSelectedDate() {
    final text = DateFormat("EEEE, d 'de' MMM", 'es').format(_selectedDate);
    return _capitalize(text);
  }

  Future<void> _showBookConfirmation(PilatesClass cls) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookConfirmSheet(cls: cls),
    );
    if (confirmed == true) _bookClass(cls);
  }

  Future<void> _joinWaitlist(PilatesClass cls) async {
    final granted = await PushNotificationService.requestPermission();
    if (granted) {
      final existing = await PushNotificationService.getExistingSubscription();
      final subJson = existing ?? await PushNotificationService.subscribe();
      if (subJson != null) await WaitlistService.savePushSubscription(subJson);
    }
    final id = await WaitlistService.joinWaitlist(cls.id);
    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          granted
              ? 'Te anotaste en la lista de espera. Te avisamos si se libera un cupo.'
              : 'Estás en la lista de espera. Activá las notificaciones para recibir avisos.',
          style: KaliText.body(KaliColors.clay),
        ),
        backgroundColor: KaliColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      await _loadSessionsForDate(_selectedDate);
    }
  }

  Future<void> _leaveWaitlist(PilatesClass cls) async {
    if (cls.waitlistId == null) return;
    await WaitlistService.leaveWaitlist(cls.waitlistId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Saliste de la lista de espera.',
          style: KaliText.body(KaliColors.clay)),
      backgroundColor: KaliColors.espresso,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    await _loadSessionsForDate(_selectedDate);
  }

  Future<void> _bookClass(PilatesClass cls) async {
    try {
      final usage = await BookingService.fetchWeeklyUsage(forDate: cls.sessionDate);

      if (!usage.hasPlan) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Necesitás un plan activo para reservar clases.',
              style: KaliText.body(KaliColors.clay),
            ),
            backgroundColor: KaliColors.espresso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (usage.limit != null && usage.used >= usage.limit!) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alcanzaste el límite de ${usage.limit} clase${usage.limit == 1 ? '' : 's'} semanales de tu plan.',
              style: KaliText.body(KaliColors.clay),
            ),
            backgroundColor: KaliColors.espresso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      await BookingService.createReservation(cls.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reservaste ${cls.name}',
            style: KaliText.body(KaliColors.clay),
          ),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _loadSessionsForDate(_selectedDate);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : 'No se pudo reservar. Intentá de nuevo.';
      if (msg == 'La clase está llena.') {
        setState(() => _fullSessionIds.add(cls.id));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: KaliText.body(KaliColors.clay)),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _loadSessionsForDate(_selectedDate);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _BookConfirmSheet extends StatelessWidget {
  final PilatesClass cls;

  const _BookConfirmSheet({required this.cls});

  @override
  Widget build(BuildContext context) {
    final primaryText = KaliColors.espresso;
    final mutedText = KaliColors.clayDark;

    final dateStr = cls.sessionDate != null
        ? DateFormat("EEEE d 'de' MMMM", 'es').format(cls.sessionDate!)
        : '';

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
            'Confirmar reserva',
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
          if (dateStr.isNotEmpty || cls.time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (dateStr.isNotEmpty)
                  dateStr[0].toUpperCase() + dateStr.substring(1),
                if (cls.time.isNotEmpty) '${cls.time} ${cls.period}',
              ].join(' · '),
              style: KaliText.body(
                mutedText,
                size: 13,
                weight: FontWeight.w400,
              ),
            ),
          ],
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
                Icon(Icons.info_outline_rounded,
                    size: 18, color: KaliColors.clay),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solo podés cancelar hasta 24 horas antes de la clase. Pasado ese límite, se descontará una sesión de tu plan semanal.',
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
          _BookConfirmButton(
            label: 'Confirmar reserva',
            filled: true,
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 12),
          _BookConfirmButton(
            label: 'Cancelar',
            filled: false,
            onTap: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BookConfirmButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _BookConfirmButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? KaliColors.espresso : Colors.transparent;
    final fg = filled ? KaliColors.background : KaliColors.espresso;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: KaliColors.espresso),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: KaliText.label(fg)
              .copyWith(fontSize: 12, letterSpacing: 1.8),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final PilatesClass cls;
  final bool isFull;
  final VoidCallback? onBook;
  final VoidCallback? onJoinWaitlist;
  final VoidCallback? onLeaveWaitlist;

  const _ScheduleCard({
    required this.cls,
    required this.isFull,
    required this.onBook,
    this.onJoinWaitlist,
    this.onLeaveWaitlist,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = KaliColors.sand;
    final primaryText = KaliColors.espresso;
    final secondaryText = KaliColors.clayDark;
    final dotColor = KaliColors.clayDark.withValues(alpha: 0.72);
    final buttonBackground = KaliColors.espresso;
    final buttonForeground = KaliColors.background;

    final Widget button;
    if (cls.isBooked) {
      button = Text(
        'Reservada',
        style: KaliText.label(buttonBackground)
            .copyWith(fontSize: 9, letterSpacing: 1.2),
      );
    } else if (cls.isInWaitlist) {
      button = _HoverPill(
        label: 'En espera',
        background: KaliColors.clayDark,
        foreground: KaliColors.warmWhite,
        onTap: onLeaveWaitlist,
      );
    } else if (isFull) {
      button = _HoverPill(
        label: 'En espera',
        background: KaliColors.sand2,
        foreground: KaliColors.espresso,
        onTap: onJoinWaitlist,
      );
    } else {
      button = _HoverPill(
        label: 'Reservar',
        background: buttonBackground,
        foreground: buttonForeground,
        onTap: onBook,
      );
    }

    return Opacity(
      opacity: isFull ? 0.58 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cls.time,
                        maxLines: 1,
                        style: KaliText.body(
                          primaryText,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cls.durationMin} min',
                        style: KaliText.label(secondaryText)
                            .copyWith(fontSize: 9, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cls.name,
                    style: GoogleFontsHelper.cormorant(
                      primaryText,
                      22,
                      italic: true,
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          cls.instructor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KaliText.body(
                            secondaryText,
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            button,
          ],
        ),
      ),
    );
  }
}

class _HoverPill extends StatefulWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _HoverPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  State<_HoverPill> createState() => _HoverPillState();
}

class _HoverPillState extends State<_HoverPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 0.72 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.label,
              style: KaliText.label(widget.foreground)
                  .copyWith(fontSize: 10, letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}
