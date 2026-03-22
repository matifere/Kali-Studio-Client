import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';
import '../models/models.dart';
import '../theme/kali_theme.dart';

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

  static final Map<DateTime, List<PilatesClass>> _scheduleByDate =
      _buildScheduleByDate();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 28),
              _buildHeader(),
              const SizedBox(height: 28),
              _buildCalendar(context),
              const SizedBox(height: 34),
              _buildAvailabilitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
        const Icon(Icons.notifications_none_rounded,
            color: Color(0xFF2E1B16), size: 22),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservar Clase',
          style: GoogleFontsHelper.cormorant(
            const Color(0xFF2E1B16),
            38,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Encuentra el momento perfecto para tu bienestar.',
          style: KaliText.body(
            const Color(0xFF866B57),
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final days = _calendarDaysForMonth(_visibleMonth);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _capitalize(
                    DateFormat('MMMM yyyy', 'es').format(_visibleMonth)),
                style: GoogleFontsHelper.cormorant(
                  const Color(0xFF2E1B16),
                  24,
                  italic: true,
                  weight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                }),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF7A604B), size: 24),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                }),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF7A604B), size: 24),
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
                        style: KaliText.label(const Color(0xFFC7B7A6))
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
              final isOutsideMonth = date.month != _visibleMonth.month;
              final isSelected = _isSameDay(date, _selectedDate);
              final hasClasses = _classesForDate(date).isNotEmpty;

              return SizedBox(
                width: (MediaQuery.of(context).size.width - 84) / 7,
                child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF2E1B16)
                            : Colors.transparent,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: KaliText.body(
                              isSelected
                                  ? Colors.white
                                  : isOutsideMonth
                                      ? const Color(0xFFC7B7A6)
                                      : const Color(0xFF3D2B23),
                              size: 14,
                              weight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (hasClasses && !isSelected)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8A6A53),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
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
    final classes = _classesForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Horarios Disponibles',
              style: GoogleFontsHelper.cormorant(
                const Color(0xFF2E1B16),
                24,
                italic: true,
                weight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E7DA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _formattedSelectedDate(),
                style: KaliText.label(const Color(0xFF7A604B))
                    .copyWith(fontSize: 9, letterSpacing: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (classes.isEmpty)
          _buildEmptyState()
        else
          ...classes.asMap().entries.map((entry) {
            final index = entry.key;
            final cls = entry.value;
            final isFull = cls.availableSpots == 0;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == classes.length - 1 ? 0 : 14),
              child: _ScheduleCard(
                cls: cls,
                isFull: isFull,
                onBook: isFull ? null : () => _bookClass(cls),
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
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined,
              color: Color(0xFF8A6A53), size: 28),
          const SizedBox(height: 10),
          Text(
            'No hay horarios cargados para este dia',
            style: KaliText.body(
              const Color(0xFF5E4A3B),
              size: 14,
              weight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Proba seleccionando otra fecha del calendario.',
            style: KaliText.body(
              const Color(0xFF8A6A53),
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

  List<PilatesClass> _classesForDate(DateTime date) {
    return _scheduleByDate[_normalizeDate(date)] ?? const [];
  }

  String _formattedSelectedDate() {
    final text = DateFormat("EEEE, d 'de' MMM", 'es').format(_selectedDate);
    return _capitalize(text);
  }

  void _bookClass(PilatesClass cls) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reservaste ${cls.name}',
          style: KaliText.body(KaliColors.clay),
        ),
        backgroundColor: KaliColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static Map<DateTime, List<PilatesClass>> _buildScheduleByDate() {
    final now = DateTime.now();

    PilatesClass clone(
      PilatesClass cls,
      String idSuffix, {
      String? time,
      String? period,
      int? takenSpots,
      String? name,
      String? instructor,
      int? durationMin,
    }) {
      return PilatesClass(
        id: '${cls.id}_$idSuffix',
        name: name ?? cls.name,
        instructor: instructor ?? cls.instructor,
        time: time ?? cls.time,
        period: period ?? cls.period,
        room: cls.room,
        level: cls.level,
        durationMin: durationMin ?? cls.durationMin,
        totalSpots: cls.totalSpots,
        takenSpots: takenSpots ?? cls.takenSpots,
        equipment: cls.equipment,
        description: cls.description,
        isBooked: cls.isBooked,
      );
    }

    return {
      DateTime(now.year, now.month, now.day): [
        clone(KaliData.todayClasses[0], 'd0_1'),
        clone(
          KaliData.todayClasses[1],
          'd0_2',
          time: '10:00',
          period: 'AM',
        ),
      ],
      DateTime(now.year, now.month, now.day + 1): [
        clone(KaliData.todayClasses[3], 'd1_1'),
        clone(
          KaliData.todayClasses[2],
          'd1_2',
          time: '11:30',
          period: 'AM',
          takenSpots: 8,
        ),
        clone(
          KaliData.todayClasses[1],
          'd1_3',
          time: '6:00',
          period: 'PM',
          durationMin: 75,
          name: 'Vinyasa Deep',
          instructor: 'Luciana Paz',
        ),
      ],
      DateTime(now.year, now.month, now.day + 2): [
        clone(
          KaliData.todayClasses[1],
          'd2_1',
          time: '9:00',
          period: 'AM',
          instructor: 'Mateo Rivas',
          name: 'Mindful Pilates',
          durationMin: 45,
        ),
        clone(
          KaliData.todayClasses[0],
          'd2_2',
          time: '7:30',
          period: 'AM',
          takenSpots: 4,
          name: 'Yoga Flow',
        ),
      ],
      DateTime(now.year, now.month, now.day + 4): [
        clone(
          KaliData.todayClasses[2],
          'd4_1',
          time: '8:30',
          period: 'AM',
          takenSpots: 2,
        ),
        clone(
          KaliData.todayClasses[3],
          'd4_2',
          time: '6:30',
          period: 'PM',
          takenSpots: 7,
        ),
      ],
      DateTime(now.year, now.month, now.day + 7): [
        clone(
          KaliData.todayClasses[1],
          'd7_1',
          time: '10:00',
          period: 'AM',
          takenSpots: 3,
        ),
        clone(
          KaliData.todayClasses[2],
          'd7_2',
          time: '12:00',
          period: 'PM',
          takenSpots: 1,
        ),
      ],
    };
  }
}

class _ScheduleCard extends StatelessWidget {
  final PilatesClass cls;
  final bool isFull;
  final VoidCallback? onBook;

  const _ScheduleCard({
    required this.cls,
    required this.isFull,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isFull ? 0.58 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                cls.time,
                style: KaliText.body(
                  const Color(0xFF2E1B16),
                  size: 20,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: const Color(0xFFD9CCBE),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: GoogleFontsHelper.cormorant(
                      const Color(0xFF2E1B16),
                      24,
                      italic: true,
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cls.instructor,
                          style: KaliText.body(
                            const Color(0xFF7A604B),
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB09C88),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${cls.durationMin} min',
                        style: KaliText.label(const Color(0xFF5D5044))
                            .copyWith(fontSize: 9, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            isFull
                ? Text(
                    'Completo',
                    style: KaliText.label(const Color(0xFFA69281))
                        .copyWith(fontSize: 9, letterSpacing: 1.2),
                  )
                : GestureDetector(
                    onTap: onBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1B16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Reservar',
                        style: KaliText.label(Colors.white)
                            .copyWith(fontSize: 10, letterSpacing: 1.2),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
