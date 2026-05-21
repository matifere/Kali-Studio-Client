import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'profile_manager.dart';
import 'waitlist_service.dart';

class BookingService {
  static final _supabase = Supabase.instance.client;


  static Future<List<PilatesClass>> fetchSessionsForDate(
      DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final institutionId = await getInstitutionId();
    try {
      var query = _supabase
          .from('class_sessions')
          .select(
            'id, date, start_time, end_time, capacity, status, '
            'schedule_templates(name, description, instructor_name), '
            'reservations(id, user_id, status)',
          )
          .eq('date', _dateStr(date))
          .eq('status', 'scheduled');
      if (institutionId != null) query = query.eq('institution_id', institutionId);
      final data = await query.order('start_time', ascending: true);

      final sessions = (data as List)
          .map((row) => _fromSessionRow(row as Map<String, dynamic>, userId))
          .toList();

      final sessionIds = sessions.map((s) => s.id).toList();

      final results = await Future.wait<Object?>([
        WaitlistService.fetchWaitlistForSessions(sessionIds),
        sessionIds.isEmpty
            ? Future.value(<dynamic>[])
            : _supabase.rpc('get_session_confirmed_counts',
                params: {'p_session_ids': sessionIds}),
      ]);

      final waitlistMap = results[0] as Map<String, String>;
      final countsMap = <String, int>{
        for (final row in (results[1] as List))
          (row as Map<String, dynamic>)['session_id'] as String:
              (row['confirmed_count'] as int? ?? 0),
      };

      return sessions
          .map((s) => PilatesClass(
                id: s.id,
                name: s.name,
                instructor: s.instructor,
                time: s.time,
                period: s.period,
                room: s.room,
                level: s.level,
                durationMin: s.durationMin,
                totalSpots: s.totalSpots,
                takenSpots: countsMap[s.id] ?? s.takenSpots,
                equipment: s.equipment,
                description: s.description,
                isBooked: s.isBooked,
                reservationId: s.reservationId,
                sessionDate: s.sessionDate,
                isInWaitlist: waitlistMap.containsKey(s.id),
                waitlistId: waitlistMap[s.id],
              ))
          .toList();
    } catch (e) {
      debugPrint('BookingService.fetchSessionsForDate error: $e');
      rethrow;
    }
  }


  static Future<PilatesClass?> fetchNextReservation() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final todayStr = _dateStr(DateTime.now());
    final institutionId = await getInstitutionId();

    try {
      var query = _supabase
          .from('reservations')
          .select(
            'id, '
            'class_sessions!inner('
            'id, date, start_time, end_time, '
            'schedule_templates(name, instructor_name)'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', todayStr);
      if (institutionId != null) query = query.eq('class_sessions.institution_id', institutionId);
      final data = await query.limit(1);

      final list = (data as List)
          .map((row) => _fromReservationRow(row as Map<String, dynamic>, userId))
          .toList()
        ..sort((a, b) => a.sessionDate!.compareTo(b.sessionDate!));

      return list.firstOrNull;
    } catch (e) {
      debugPrint('BookingService.fetchNextReservation error: $e');
      return null;
    }
  }

  static Future<List<PilatesClass>> fetchUserReservations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from('reservations')
          .select(
            'id, session_id, status, '
            'class_sessions('
            'id, date, start_time, end_time, capacity, '
            'schedule_templates(name, description, instructor_name), '
            'reservations(id, user_id, status)'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .limit(500);

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final list = (data as List)
          .where((row) => (row as Map<String, dynamic>)['class_sessions'] != null)
          .map((row) =>
              _fromReservationRow(row as Map<String, dynamic>, userId))
          .where((cls) =>
              cls.sessionDate != null &&
              !cls.sessionDate!.isBefore(todayDate))
          .toList();

      list.sort((a, b) => a.sessionDate!.compareTo(b.sessionDate!));

      return list;
    } catch (e) {
      debugPrint('BookingService.fetchUserReservations error: $e');
      rethrow;
    }
  }


  static Future<Set<String>> fetchDatesWithSessions(DateTime month) async {
    final institutionId = await getInstitutionId();
    try {
      final first = DateTime(month.year, month.month, 1);
      final last = DateTime(month.year, month.month + 1, 0);

      final data = await _supabase.rpc(
        'get_dates_with_available_sessions',
        params: {
          'p_from': _dateStr(first),
          'p_to': _dateStr(last),
          if (institutionId != null) 'p_institution_id': institutionId,
        },
      );

      return (data as List)
          .map((d) => (d as Map<String, dynamic>)['date'] as String)
          .toSet();
    } catch (e) {
      debugPrint('BookingService.fetchDatesWithSessions error: $e');
      return {};
    }
  }


  static Future<({int used, int? limit, bool hasPlan})> fetchWeeklyUsage({DateTime? forDate}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return (used: 0, limit: null, hasPlan: false);

    final ref = forDate ?? DateTime.now();
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final from = _dateStr(DateTime(monday.year, monday.month, monday.day));
    final to = _dateStr(DateTime(sunday.year, sunday.month, sunday.day));

    final results = await Future.wait<Object?>([
      _supabase
          .from('reservations')
          .select('id, class_sessions!inner(date)')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', from)
          .lte('class_sessions.date', to),
      _supabase
          .from('subscriptions')
          .select('plan_id, plans(max_reservations_per_week)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final used = ((results[0] as List?) ?? []).length;
    final sub = results[1] as Map<String, dynamic>?;
    final planData = sub?['plans'] as Map<String, dynamic>?;
    final limit = planData?['max_reservations_per_week'] as int?;

    return (used: used, limit: limit, hasPlan: sub != null);
  }

  static Future<void> createReservation(String sessionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No autenticado');

    final dynamic raw = await _supabase.rpc('book_session_if_available', params: {
      'p_session_id': sessionId,
      'p_user_id': userId,
    });

    final Map<String, dynamic> result;
    if (raw is Map<String, dynamic>) {
      result = raw;
    } else if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      result = raw.first as Map<String, dynamic>;
    } else {
      throw Exception('Respuesta inesperada del servidor.');
    }

    if (result['ok'] != true) {
      if (result['error'] == 'full') throw Exception('La clase está llena.');
      if (result['error'] == 'no_plan') throw Exception('Necesitás un plan activo para reservar.');
      if (result['error'] == 'already_booked') throw Exception('Ya tenés una reserva para esta clase.');
      throw Exception('No se pudo reservar.');
    }
  }


  static Future<List<PilatesClass>> fetchPastReservationsForMonth(
      int year, int month) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final institutionId = await getInstitutionId();

    try {
      var query = _supabase
          .from('reservations')
          .select(
            'id, session_id, status, '
            'class_sessions('
            'id, date, start_time, end_time, capacity, '
            'schedule_templates(name, description, instructor_name), '
            'reservations(id, user_id, status)'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', _dateStr(first))
          .lte('class_sessions.date', _dateStr(last));
      if (institutionId != null) query = query.eq('class_sessions.institution_id', institutionId);
      final data = await query;

      final list = (data as List)
          .where((row) {
            final session = (row as Map<String, dynamic>)['class_sessions'];
            if (session == null) return false;
            final dateStr = (session as Map<String, dynamic>)['date'] as String?;
            final d = DateTime.tryParse(dateStr ?? '');
            return d != null && d.isBefore(todayDate);
          })
          .map((row) => _fromReservationRow(row as Map<String, dynamic>, userId))
          .toList()
        ..sort((a, b) => b.sessionDate!.compareTo(a.sessionDate!));

      return list;
    } catch (e) {
      debugPrint('BookingService.fetchPastReservationsForMonth error: $e');
      rethrow;
    }
  }


  static Future<int> fetchMonthlyReservationCount(int year, int month) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);

    try {
      final data = await _supabase
          .from('reservations')
          .select('id, class_sessions!inner(date)')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', _dateStr(first))
          .lte('class_sessions.date', _dateStr(last));
      return (data as List).length;
    } catch (e) {
      debugPrint('BookingService.fetchMonthlyReservationCount error: $e');
      return 0;
    }
  }

  static Future<void> cancelReservation(String reservationId) async {
    await _supabase.from('reservations').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', reservationId);
  }


  static PilatesClass _fromSessionRow(
      Map<String, dynamic> row, String userId) {
    final template =
        (row['schedule_templates'] as Map<String, dynamic>?) ?? {};
    final allReservations = (row['reservations'] as List?) ?? [];
    final confirmed =
        allReservations.where((r) => r['status'] == 'confirmed').toList();
    final mine = confirmed
        .where((r) => r['user_id'] == userId)
        .map((r) => r['id'] as String)
        .firstOrNull;

    final startTime = row['start_time'] as String? ?? '00:00:00';
    final endTime = row['end_time'] as String? ?? '00:00:00';

    return PilatesClass(
      id: row['id'] as String,
      name: template['name'] as String? ?? '',
      instructor: template['instructor_name'] as String? ?? '',
      time: _formatTime(startTime),
      period: _timePeriod(startTime),
      room: '',
      level: '',
      durationMin: _calcDuration(startTime, endTime),
      totalSpots: row['capacity'] as int? ?? 0,
      takenSpots: confirmed.length,
      equipment: '',
      description: template['description'] as String? ?? '',
      isBooked: mine != null,
      reservationId: mine,
      sessionDate: DateTime.tryParse(row['date'] as String? ?? ''),
    );
  }

  static PilatesClass _fromReservationRow(
      Map<String, dynamic> row, String userId) {
    final reservationId = row['id'] as String;
    final session = row['class_sessions'] as Map<String, dynamic>;
    final template =
        (session['schedule_templates'] as Map<String, dynamic>?) ?? {};
    final allReservations = (session['reservations'] as List?) ?? [];
    final confirmed =
        allReservations.where((r) => r['status'] == 'confirmed').toList();

    final startTime = session['start_time'] as String? ?? '00:00:00';
    final endTime = session['end_time'] as String? ?? '00:00:00';

    return PilatesClass(
      id: session['id'] as String,
      name: template['name'] as String? ?? '',
      instructor: template['instructor_name'] as String? ?? '',
      time: _formatTime(startTime),
      period: _timePeriod(startTime),
      room: '',
      level: '',
      durationMin: _calcDuration(startTime, endTime),
      totalSpots: session['capacity'] as int? ?? 0,
      takenSpots: confirmed.length,
      equipment: '',
      description: template['description'] as String? ?? '',
      isBooked: true,
      reservationId: reservationId,
      sessionDate: DateTime.tryParse(session['date'] as String? ?? ''),
    );
  }

  static String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _formatTime(String dbTime) {
    final parts = dbTime.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _timePeriod(String dbTime) {
    final h = int.tryParse(dbTime.split(':').first) ?? 0;
    return h < 12 ? 'AM' : 'PM';
  }

  static int _calcDuration(String startTime, String endTime) {
    final sp = startTime.split(':');
    final ep = endTime.split(':');
    final startMin =
        (int.tryParse(sp[0]) ?? 0) * 60 + (int.tryParse(sp[1]) ?? 0);
    final endMin =
        (int.tryParse(ep[0]) ?? 0) * 60 + (int.tryParse(ep[1]) ?? 0);
    final diff = endMin - startMin;
    return diff > 0 ? diff : 60;
  }
}
