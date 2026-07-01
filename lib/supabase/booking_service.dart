import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/time_utils.dart';
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
            'id, date, status, '
            'name, description, instructor_name, start_time, end_time, capacity',
          )
          .eq('date', _dateStr(date))
          .eq('status', 'scheduled');
      if (institutionId != null) query = query.eq('institution_id', institutionId);
      final data = await query.order('start_time', ascending: true);

      final sessionIds = ((data as List?) ?? [])
          .map((row) => (row as Map<String, dynamic>)['id'] as String)
          .toList();

      final results = await Future.wait<Object?>([
        WaitlistService.fetchWaitlistForSessions(sessionIds),
        sessionIds.isEmpty
            ? Future.value(<dynamic>[])
            : _supabase.rpc('get_session_confirmed_counts',
                params: {'p_session_ids': sessionIds}),
        sessionIds.isEmpty
            ? Future.value(<dynamic>[])
            : _supabase
                .from('reservations')
                .select('id, session_id, status')
                .inFilter('session_id', sessionIds)
                .eq('user_id', userId),
      ]);

      final waitlistMap = results[0] as Map<String, String>;
      final countsMap = <String, int>{
        for (final row in (results[1] as List))
          (row as Map<String, dynamic>)['session_id'] as String:
              (row['confirmed_count'] as int? ?? 0),
      };

      final userReservations = results[2] as List;
      final userResMap = <String, String>{};
      for (final row in userReservations) {
        final r = row as Map<String, dynamic>;
        final status = r['status'] as String;
        if (status == 'confirmed' || status == 'waitlisted') {
          userResMap[r['session_id'] as String] = r['id'] as String;
        }
      }

      final sessions = ((data as List?) ?? [])
          .map((row) => _fromSessionRow(
                row as Map<String, dynamic>,
                userId,
                userResMap[(row)['id'] as String],
                countsMap[(row)['id'] as String] ?? 0,
              ))
          .toList();

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
                takenSpots: s.takenSpots,
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
            'id, date, name, instructor_name, start_time, end_time'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', todayStr);
      if (institutionId != null) query = query.eq('class_sessions.institution_id', institutionId);
      final data = await query.limit(50);

      final list = ((data as List?) ?? [])
          .map((row) => _fromReservationRow(row as Map<String, dynamic>, userId, 0))
          .toList()
        ..sort(_byDateAndTime);

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
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final data = await _supabase
          .from('reservations')
          .select(
            'id, session_id, status, '
            'class_sessions!inner('
            'id, date, name, description, instructor_name, start_time, end_time, capacity'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', _dateStr(todayDate))
          .limit(500);

      final validRows = ((data as List?) ?? [])
          .where((row) => (row as Map<String, dynamic>)['class_sessions'] != null)
          .toList();

      final sessionIds = validRows
          .map((row) => ((row as Map<String, dynamic>)['class_sessions'] as Map<String, dynamic>)['id'] as String)
          .toSet()
          .toList();

      final countsData = sessionIds.isEmpty
          ? <dynamic>[]
          : await _supabase.rpc('get_session_confirmed_counts',
              params: {'p_session_ids': sessionIds});

      final countsMap = <String, int>{
        for (final row in (countsData as List))
          (row as Map<String, dynamic>)['session_id'] as String:
              (row['confirmed_count'] as int? ?? 0),
      };

      final list = validRows
          .map((row) {
            final session = (row as Map<String, dynamic>)['class_sessions'] as Map<String, dynamic>;
            final takenSpots = countsMap[session['id'] as String] ?? 0;
            return _fromReservationRow(row, userId, takenSpots);
          })
          .where((cls) =>
              cls.sessionDate != null &&
              !cls.sessionDate!.isBefore(todayDate))
          .toList();

      list.sort(_byDateAndTime);

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

      return ((data as List?) ?? [])
          .map((d) => (d as Map<String, dynamic>)['date'] as String)
          .toSet();
    } catch (e) {
      debugPrint('BookingService.fetchDatesWithSessions error: $e');
      return {};
    }
  }


  static Future<({int used, int? limit, bool hasPlan})> fetchMonthlyUsage({DateTime? forDate}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return (used: 0, limit: null, hasPlan: false);

    final ref = forDate ?? DateTime.now();
    final from = _dateStr(DateTime(ref.year, ref.month, 1));
    final to = _dateStr(DateTime(ref.year, ref.month + 1, 0));

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
          .select('plan_id, plans(max_reservations_per_month)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .lte('start_date', _dateStr(DateTime.now()))
          .gte('end_date', _dateStr(DateTime.now()))
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final used = ((results[0] as List?) ?? []).length;
    final sub = results[1] as Map<String, dynamic>?;
    final planData = sub?['plans'] as Map<String, dynamic>?;
    final limit = planData?['max_reservations_per_month'] as int?;

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

    throwIfBookingFailed(result);
  }

  @visibleForTesting
  static void throwIfBookingFailed(Map<String, dynamic> result) {
    if (result['ok'] == true) return;
    final error = result['error'] as String?;
    if (error == 'full') throw Exception('La clase está llena.');
    if (error == 'no_plan') throw Exception('Necesitás un plan activo para reservar.');
    if (error == 'future_month') throw Exception('Solo podés reservar clases del mes actual.');
    if (error == 'already_booked') throw Exception('Ya tenés una reserva para esta clase.');
    if (error == 'monthly_limit_exceeded') throw Exception('Alcanzaste el límite de clases mensuales de tu plan.');
    throw Exception('No se pudo reservar. Código de error: $error');
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
            'class_sessions!inner('
            'id, date, name, description, instructor_name, start_time, end_time, capacity'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('class_sessions.date', _dateStr(first))
          .lte('class_sessions.date', _dateStr(last));
      if (institutionId != null) query = query.eq('class_sessions.institution_id', institutionId);
      final data = await query;

      final list = ((data as List?) ?? [])
          .where((row) {
            final session = (row as Map<String, dynamic>)['class_sessions'];
            if (session == null) return false;
            final dateStr = (session as Map<String, dynamic>)['date'] as String?;
            final d = DateTime.tryParse(dateStr ?? '');
            return d != null && d.isBefore(todayDate);
          })
          .map((row) => _fromReservationRow(row as Map<String, dynamic>, userId, 0))
          .toList()
        ..sort((a, b) => _byDateAndTime(b, a));

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
      return ((data as List?) ?? []).length;
    } catch (e) {
      debugPrint('BookingService.fetchMonthlyReservationCount error: $e');
      return 0;
    }
  }

  static Future<void> cancelReservation(String reservationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('reservations').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', reservationId).eq('user_id', userId);
  }


  static PilatesClass _fromSessionRow(
      Map<String, dynamic> row, String userId, String? myReservationId, int takenSpots) {
    final startTime = row['start_time'] as String? ?? '00:00:00';
    final endTime = row['end_time'] as String? ?? '00:00:00';

    return PilatesClass(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      instructor: row['instructor_name'] as String? ?? '',
      time: TimeUtils.formatTime24h(startTime),
      period: TimeUtils.timePeriod(startTime),
      room: '',
      level: '',
      durationMin: TimeUtils.calcDuration(startTime, endTime),
      totalSpots: row['capacity'] as int? ?? 0,
      takenSpots: takenSpots,
      equipment: '',
      description: row['description'] as String? ?? '',
      isBooked: myReservationId != null,
      reservationId: myReservationId,
      sessionDate: DateTime.tryParse(row['date'] as String? ?? ''),
    );
  }

  static PilatesClass _fromReservationRow(
      Map<String, dynamic> row, String userId, int takenSpots) {
    final reservationId = row['id'] as String;
    final session = row['class_sessions'] as Map<String, dynamic>;

    final startTime = session['start_time'] as String? ?? '00:00:00';
    final endTime = session['end_time'] as String? ?? '00:00:00';

    return PilatesClass(
      id: session['id'] as String,
      name: session['name'] as String? ?? '',
      instructor: session['instructor_name'] as String? ?? '',
      time: TimeUtils.formatTime24h(startTime),
      period: TimeUtils.timePeriod(startTime),
      room: '',
      level: '',
      durationMin: TimeUtils.calcDuration(startTime, endTime),
      totalSpots: session['capacity'] as int? ?? 0,
      takenSpots: takenSpots,
      equipment: '',
      description: session['description'] as String? ?? '',
      isBooked: true,
      reservationId: reservationId,
      sessionDate: DateTime.tryParse(session['date'] as String? ?? ''),
    );
  }

  /// Ordena por fecha y, dentro del mismo día, por hora de inicio.
  /// `time` viene en formato 24 h con cero a la izquierda, así que el
  /// orden lexicográfico coincide con el cronológico.
  static int _byDateAndTime(PilatesClass a, PilatesClass b) {
    final byDate = a.sessionDate!.compareTo(b.sessionDate!);
    return byDate != 0 ? byDate : a.time.compareTo(b.time);
  }

  static String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
