import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'profile_manager.dart';

class PaymentPreference {
  final String? mpUrl;
  final String? alias;
  const PaymentPreference({this.mpUrl, this.alias});
}

class PlanService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Plan>> fetchAvailablePlans() async {
    final institutionId = await getInstitutionId();
    try {
      var query = _supabase
          .from('plans')
          .select('id, name, description, price, currency, max_reservations_per_month')
          .eq('is_active', true);
      if (institutionId != null) query = query.eq('institution_id', institutionId);
      final Object raw = await query.order('price', ascending: true);
      if (raw is! List) return [];
      return raw.map((e) => Plan.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('PlanService.fetchAvailablePlans error: $e');
      return [];
    }
  }

  static Future<PaymentPreference> createPaymentPreference(String planId) async {
    if (_supabase.auth.currentSession == null) {
      throw Exception('Tu sesión expiró. Volvé a iniciar sesión.');
    }

    dynamic data;
    try {
      final res = await _supabase.functions.invoke(
        'create-preference',
        body: {'plan_id': planId},
      );
      data = res.data;
    } on FunctionException catch (e) {
      throw Exception(e.details ?? 'No pudimos iniciar el pago. Intentá de nuevo.');
    } catch (e) {
      throw Exception('No pudimos iniciar el pago. Intentá de nuevo.');
    }

    if (data is Map<String, dynamic>) {
      final url = data['url'] as String?;
      final alias = data['alias'] as String?;
      final error = data['error'] as String?;

      if (error != null) throw Exception(error);
      
      if (url != null || alias != null) {
        return PaymentPreference(mpUrl: url, alias: alias);
      }
    }

    throw Exception('No pudimos procesar la respuesta del pago. Intentá de nuevo.');
  }

  static Future<UserPlan?> fetchActivePlan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // mismo criterio que el servidor: activo y cubriendo la fecha de hoy
      final data = await _supabase
          .from('subscriptions')
          .select(
            'id, plan_id, start_date, end_date, status, '
            'plans(name, description, price, currency, max_reservations_per_month)',
          )
          .eq('user_id', userId)
          .eq('status', 'active')
          .lte('start_date', todayStr)
          .gte('end_date', todayStr)
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
        monthlyClasses: plan['max_reservations_per_month'] as int?,
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
