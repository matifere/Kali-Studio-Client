import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WaitlistService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> joinWaitlist(String sessionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('waitlist')
          .upsert(
            {'user_id': userId, 'session_id': sessionId, 'status': 'waiting'},
            onConflict: 'user_id, session_id',
          )
          .select('id')
          .single();
      return data['id'] as String?;
    } catch (e) {
      debugPrint('WaitlistService.joinWaitlist error: $e');
      return null;
    }
  }

  static Future<void> leaveWaitlist(String waitlistId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('waitlist').delete()
          .eq('id', waitlistId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('WaitlistService.leaveWaitlist error: $e');
    }
  }

  // Returns map of session_id → waitlist_id for sessions the user is waiting on
  static Future<Map<String, String>> fetchWaitlistForSessions(
      List<String> sessionIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || sessionIds.isEmpty) return {};

    try {
      final data = await _supabase
          .from('waitlist')
          .select('id, session_id')
          .eq('user_id', userId)
          .eq('status', 'waiting')
          .inFilter('session_id', sessionIds);

      return {
        for (final row in ((data as List?) ?? []))
          row['session_id'] as String: row['id'] as String,
      };
    } catch (e) {
      debugPrint('WaitlistService.fetchWaitlistForSessions error: $e');
      return {};
    }
  }

  static Future<void> savePushSubscription(String subscriptionJson) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final sub = jsonDecode(subscriptionJson) as Map<String, dynamic>;
      final keys = sub['keys'] as Map<String, dynamic>;
      await _supabase.from('push_subscriptions').upsert(
        {
          'user_id': userId,
          'endpoint': sub['endpoint'] as String,
          'p256dh': keys['p256dh'] as String,
          'auth_key': keys['auth'] as String,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('WaitlistService.savePushSubscription error: $e');
    }
  }
}
