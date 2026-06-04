import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'profile_manager.dart';

sealed class PaymentPreference {
  const PaymentPreference();
}

class MercadoPagoPayment extends PaymentPreference {
  final String url;
  const MercadoPagoPayment(this.url) : super();
}

class TransferPayment extends PaymentPreference {
  final String alias;
  const TransferPayment(this.alias) : super();
}

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
      final Object raw = await query.order('price', ascending: true);
      if (raw is! List) return [];
      return raw.map((e) => Plan.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('PlanService.fetchAvailablePlans error: $e');
      return [];
    }
  }

  static Future<PaymentPreference> createPaymentPreference(String planId) async {
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

    final data = response.data as Map<String, dynamic>?;

    final alias = data?['alias'] as String?;
    if (alias != null) return TransferPayment(alias);

    final url = data?['url'] as String?;
    if (url != null) return MercadoPagoPayment(url);

    throw Exception('Respuesta de pago no válida');
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
