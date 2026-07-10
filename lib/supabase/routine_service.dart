import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Rutina asignada al alumno (routine_assignments + routines).
class MyRoutine {
  final String name;
  final String? description;
  final List<String> exercises;
  final DateTime? assignedAt;

  const MyRoutine({
    required this.name,
    this.description,
    this.exercises = const [],
    this.assignedAt,
  });
}

class RoutineService {
  static final _supabase = Supabase.instance.client;

  /// Rutina vigente del alumno logueado, o null si no tiene ninguna.
  /// La RLS solo le permite leer su propia asignación.
  static Future<MyRoutine?> fetchMyRoutine() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('routine_assignments')
          .select('assigned_at, routines(name, description, exercises)')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      final routine = (data['routines'] as Map<String, dynamic>?) ?? {};
      return MyRoutine(
        name: routine['name'] as String? ?? 'Rutina',
        description: routine['description'] as String?,
        exercises: routine['exercises'] != null
            ? List<String>.from(
                (routine['exercises'] as List).map((e) => e.toString()))
            : const [],
        assignedAt: DateTime.tryParse(data['assigned_at'] as String? ?? ''),
      );
    } catch (e) {
      debugPrint('RoutineService.fetchMyRoutine error: $e');
      return null;
    }
  }
}
