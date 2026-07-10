import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import '../../models/models.dart';
import '../../supabase/booking_service.dart';
import '../../supabase/studio_service.dart';
import '../../supabase/waitlist_service.dart';
import '../../theme/kali_theme.dart';
import '../../utils/auth_utils.dart';
import '../../utils/ui_utils.dart';
import '../../widgets/motion.dart';
import '../../widgets/web_page_wrapper.dart';
import 'widgets/book_confirm_sheet.dart';
import 'widgets/schedule_card.dart';
import 'widgets/waitlist_sheet.dart';

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
  ({int used, int? limit, bool hasPlan})? _monthlyUsage;
  int _cancellationHours = 2;

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
    _loadMonthlyUsage(_visibleMonth);
    _loadCancellationHours();
  }

  Future<void> _loadCancellationHours() async {
    final studio = await StudioService.fetchCurrentInstitution();
    if (!mounted || studio == null) return;
    setState(() => _cancellationHours = studio.cancellationHours);
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
      KaliUI.showSnackBar(context, 'No se pudieron cargar las clases. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadMonthlyUsage(DateTime month) async {
    final usage = await BookingService.fetchMonthlyUsage(
      forDate: DateTime(month.year, month.month, 15),
    );
    if (!mounted) return;
    setState(() => _monthlyUsage = usage);
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
              const SizedBox(height: 14),
              _buildMonthlyUsageCard(),
              const SizedBox(height: 20),
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
              Pressable(
                onTap: () {
                  final newMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                  setState(() => _visibleMonth = newMonth);
                  _loadDatesWithSessions(newMonth);
                  _loadMonthlyUsage(newMonth);
                },
                child: Icon(Icons.chevron_left_rounded,
                    color: _mutedText, size: 24),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () {
                  final newMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                  setState(() => _visibleMonth = newMonth);
                  _loadDatesWithSessions(newMonth);
                  _loadMonthlyUsage(newMonth);
                },
                child: Icon(Icons.chevron_right_rounded,
                    color: _mutedText, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Builder(builder: (context) {
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            return Column(
              children: [
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
                  child: Pressable(
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
          );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyUsageCard() {
    final usage = _monthlyUsage;
    if (usage == null || !usage.hasPlan || usage.limit == null) {
      return const SizedBox.shrink();
    }

    final remaining = (usage.limit! - usage.used).clamp(0, usage.limit!);
    final progress = (usage.used / usage.limit!).clamp(0.0, 1.0);
    final monthName = _capitalize(DateFormat('MMMM', 'es').format(_visibleMonth));
    final isExhausted = remaining == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isExhausted
                      ? 'Sin clases restantes en $monthName'
                      : '$remaining clase${remaining == 1 ? '' : 's'} restante${remaining == 1 ? '' : 's'} en $monthName',
                  style: KaliText.body(
                    isExhausted ? KaliColors.clay : _primaryText,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${usage.used} / ${usage.limit}',
                style: KaliText.label(_secondaryText).copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: KaliColors.clay.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExhausted ? KaliColors.clay : KaliColors.espresso,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horarios Disponibles',
          style: GoogleFontsHelper.cormorant(
            _primaryText,
            24,
            italic: true,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sessions.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final cls = _sessions[index];
              final action =
                  cls.cardAction(forceFull: _fullSessionIds.contains(cls.id));
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == _sessions.length - 1 ? 0 : 14),
                child: FadeSlideIn(
                  // key por sesión: al cambiar de fecha la tarjeta se recrea
                  // y vuelve a animar su entrada.
                  key: ValueKey(cls.id),
                  delay: Duration(milliseconds: 50 * index),
                  child: ScheduleCard(
                    cls: cls,
                    action: action,
                    onTap: switch (action) {
                      ClassCardAction.book => () => _showBookConfirmation(cls),
                      ClassCardAction.joinWaitlist => () =>
                          _showJoinWaitlistConfirmation(cls),
                      ClassCardAction.leaveWaitlist => () =>
                          _showLeaveWaitlistConfirmation(cls),
                      ClassCardAction.booked => null,
                    },
                  ),
                ),
              );
            },
          ),
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
    final confirmed = await KaliUI.showBottomSheet<bool>(
      context: context,
      builder: BookConfirmSheet(cls: cls, cancellationHours: _cancellationHours),
    );
    if (confirmed == true) _bookClass(cls);
  }

  Future<void> _showJoinWaitlistConfirmation(PilatesClass cls) async {
    final confirmed = await KaliUI.showBottomSheet<bool>(
      context: context,
      builder: WaitlistSheet.join(cls: cls),
    );
    if (confirmed == true) _joinWaitlist(cls);
  }

  Future<void> _showLeaveWaitlistConfirmation(PilatesClass cls) async {
    final confirmed = await KaliUI.showBottomSheet<bool>(
      context: context,
      builder: WaitlistSheet.leave(cls: cls),
    );
    if (confirmed == true) _leaveWaitlist(cls);
  }

  Future<void> _joinWaitlist(PilatesClass cls) async {
    final id = await WaitlistService.joinWaitlist(cls.id);
    if (!mounted) return;
    if (id != null) {
      _showSnack(
          'Te anotaste en la lista de espera. Si se libera un lugar, te inscribimos automáticamente.');
      await _loadSessionsForDate(_selectedDate);
    } else {
      _showSnack('No pudimos anotarte en la lista. Intentá de nuevo.');
    }
  }

  Future<void> _leaveWaitlist(PilatesClass cls) async {
    if (cls.waitlistId == null) return;
    final ok = await WaitlistService.leaveWaitlist(cls.waitlistId!);
    if (!mounted) return;
    _showSnack(ok
        ? 'Saliste de la lista de espera.'
        : 'No pudimos sacarte de la lista. Intentá de nuevo.');
    if (ok) await _loadSessionsForDate(_selectedDate);
  }

  void _showSnack(String message) {
    KaliUI.showSnackBar(context, message);
  }

  Future<void> _bookClass(PilatesClass cls) async {
    try {
      final usage = await BookingService.fetchMonthlyUsage(forDate: cls.sessionDate);

      if (!usage.hasPlan) {
        if (!mounted) return;
        KaliUI.showSnackBar(context, 'Necesitás un plan activo para reservar clases.');
        return;
      }

      if (usage.limit != null && usage.used >= usage.limit!) {
        if (!mounted) return;
        KaliUI.showSnackBar(context, 'Alcanzaste el límite de ${usage.limit} clase${usage.limit == 1 ? '' : 's'} mensuales de tu plan.');
        return;
      }

      await BookingService.createReservation(cls.id);
      if (!mounted) return;
      KaliUI.showSnackBar(context, 'Reservaste ${cls.name}');
      await Future.wait([
        _loadSessionsForDate(_selectedDate),
        _loadMonthlyUsage(_visibleMonth),
      ]);
    } catch (e) {
      if (!mounted) return;
      final msg = humanizeError(
        e,
        fallback: 'No se pudo reservar. Intentá de nuevo.',
      );
      if (msg == 'La clase está llena.') {
        setState(() => _fullSessionIds.add(cls.id));
      }
      KaliUI.showSnackBar(context, msg);
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

