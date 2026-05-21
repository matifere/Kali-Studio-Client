import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import '../../models/models.dart';
import '../../supabase/booking_service.dart';
import '../../theme/kali_theme.dart';
import '../../widgets/web_page_wrapper.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late DateTime _selectedMonth;
  late Future<List<PilatesClass>> _historyFuture;

  Color get _pageBackground => KaliColors.warmWhite;
  Color get _primaryText => KaliColors.espresso;
  Color get _mutedText => KaliColors.clayDark;
  Color get _cardBackground => KaliColors.sand;
  Color get _chipBackground => KaliColors.sand2;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _historyFuture = _fetch();
  }

  Future<List<PilatesClass>> _fetch() =>
      BookingService.fetchPastReservationsForMonth(
          _selectedMonth.year, _selectedMonth.month);

  void _goToPrevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _historyFuture = _fetch();
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (_selectedMonth.isBefore(currentMonth)) {
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        _historyFuture = _fetch();
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMonthSelector(),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<PilatesClass>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  final classes = snapshot.data ?? [];
                  if (classes.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildList(classes);
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _chipBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _primaryText),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Historial',
            style: GoogleFontsHelper.cormorant(
              _primaryText,
              38,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthLabel =
        DateFormat("MMMM yyyy", 'es').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goToPrevMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 22, color: _primaryText),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            monthLabel[0].toUpperCase() + monthLabel.substring(1),
            style: KaliText.body(
              _primaryText,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: _canGoNext ? _goToNextMonth : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _canGoNext ? _chipBackground : _chipBackground.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 22,
                  color: _canGoNext
                      ? _primaryText
                      : _mutedText.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PilatesClass> classes) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _HistoryCard(
        cls: classes[i],
        cardBackground: _cardBackground,
        chipBackground: _chipBackground,
        primaryText: _primaryText,
        mutedText: _mutedText,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined,
                size: 36, color: _mutedText.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Sin clases este mes',
              style: GoogleFontsHelper.cormorant(
                _primaryText,
                26,
                weight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay reservas pasadas para este período.',
              style: KaliText.body(
                _mutedText,
                size: 14,
                weight: FontWeight.w400,
              ).copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 32, color: _mutedText.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el historial.',
              style: KaliText.body(
                _mutedText,
                size: 14,
                weight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PilatesClass cls;
  final Color cardBackground;
  final Color chipBackground;
  final Color primaryText;
  final Color mutedText;

  const _HistoryCard({
    required this.cls,
    required this.cardBackground,
    required this.chipBackground,
    required this.primaryText,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = cls.sessionDate != null
        ? DateFormat("d 'de' MMM", 'es').format(cls.sessionDate!)
        : '';
    final timeStr = cls.time.isNotEmpty ? '${cls.time} ${cls.period}' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _DateBadge(date: cls.sessionDate, mutedText: mutedText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.name,
                  style: GoogleFontsHelper.cormorant(
                    primaryText,
                    20,
                    weight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                if (timeStr.isNotEmpty)
                  Text(
                    '$dateStr · $timeStr',
                    style: KaliText.body(
                      mutedText,
                      size: 12,
                      weight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                if (cls.instructor.isNotEmpty)
                  Text(
                    cls.instructor,
                    style: KaliText.body(
                      mutedText,
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${cls.durationMin} min',
              style: KaliText.label(mutedText)
                  .copyWith(fontSize: 10, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime? date;
  final Color mutedText;

  const _DateBadge({required this.date, required this.mutedText});

  @override
  Widget build(BuildContext context) {
    final day = date != null ? date!.day.toString() : '—';
    final month = date != null
        ? DateFormat('MMM', 'es').format(date!).toUpperCase()
        : '';

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: KaliColors.sand2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: GoogleFontsHelper.cormorant(
              KaliColors.espresso,
              22,
              weight: FontWeight.w400,
            ),
          ),
          Text(
            month,
            style: KaliText.label(mutedText)
                .copyWith(fontSize: 9, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }
}
