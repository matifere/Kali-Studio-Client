import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final url = dotenv.env['URL']!;
  final anon = dotenv.env['ANON']!;
  
  final client = SupabaseClient(url, anon);

  try {
    final res = await client.from('class_sessions').select('*').limit(1);
    print('class_sessions schema: ${res.isNotEmpty ? res.first.keys : "empty"}');
  } catch (e) {
    print('Error class_sessions: $e');
  }

  try {
    final res = await client.from('schedule_templates').select('*').limit(1);
    print('schedule_templates schema: ${res.isNotEmpty ? res.first.keys : "empty"}');
  } catch (e) {
    print('Error schedule_templates: $e');
  }

  try {
    final res = await client.from('sessions_with_availability').select('*').limit(1);
    print('sessions_with_availability schema: ${res.isNotEmpty ? res.first.keys : "empty"}');
  } catch (e) {
    print('Error sessions_with_availability: $e');
  }
}
