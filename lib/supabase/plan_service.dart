import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'profile_manager.dart';

class PlanService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Plan>> fetchAvailablePlans() async {
    final institutionId = await getInstitutionId();
    try {
      var query = _supabase
          .from('plans')
          .select('id, name, description, price, currency, max_reservations_per_week')
          .eq('is_active', true);
      if (institutionId != null) query = query.eq('institution_id', institutionId);
      final data = await query.order('price', ascending: true);
      return (data as List)
          .map((e) => Plan.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PlanService.fetchAvailablePlans error: $e');
      return [];
    }
  }

  static Future<String> createPaymentPreference(String planId) async {
    if (_supabase.auth.currentSession == null) throw Exception('No autenticado');

    final response = await _supabase.functions.invoke(
      'create-preference',
      body: {'plan_id': planId},
    );

    if (response.status != 200) {
      final err = (response.data as Map<String, dynamic>?)?['error'] as String?
          ?? 'Error al crear el pago';
      throw Exception(err);
    }

    final url = (response.data as Map<String, dynamic>?)?['url'] as String?;
    if (url == null) throw Exception('URL de pago no disponible');
    return url;
  }

  static Future<UserPlan?> fetchActivePlan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('subscriptions')
          .select(
            'id, plan_id, start_date, end_date, status, '
            'plans(name, description, price, currency, max_reservations_per_week)',
          )
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;

      final plan = (data['plans'] as Map<String, dynamic>?) ?? {};

      final startDate = DateTime.tryParse(data['start_date'] as String? ?? '');
      final endDate = DateTime.tryParse(data['end_date'] as String? ?? '');
      if (startDate == null || endDate == null) return null;

      return UserPlan(
        id: data['id'] as String,
        planId: data['plan_id'] as String? ?? '',
        name: plan['name'] as String? ?? 'Plan',
        description: plan['description'] as String? ?? '',
        price: (plan['price'] as num?)?.toDouble() ?? 0,
        currency: plan['currency'] as String? ?? '',
        maxReservations: null,
        weeklyClasses: plan['max_reservations_per_week'] as int?,
        startDate: startDate,
        endDate: endDate,
        status: data['status'] as String,
      );
    } catch (e) {
      debugPrint('PlanService.fetchActivePlan error: $e');
      return null;
    }
  }
}
