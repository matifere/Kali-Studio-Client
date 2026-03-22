import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String uuid;
  final String fullName;
  late String? phone;
  late String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile(
      {required this.uuid,
      required this.fullName,
      required this.role,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
}

Future<Profile?> obtenerPerfil() async {
  final session = Supabase.instance.client.auth.currentSession;
  final String? userId = session?.user.id;

  if (userId != null) {
    try {
      final Map<String, dynamic> userData = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      final res = Profile(
          uuid: userData['id'],
          fullName: userData['full_name'],
          role: userData['role'],
          isActive: userData['is_active'],
          createdAt: DateTime.parse(userData['created_at']),
          updatedAt: DateTime.parse(userData['updated_at']));
      res.phone = userData['phone'];
      res.avatarUrl = userData['avatar_url'];
      return res;
    } catch (e) {
      //error
      print(e);
    }
  } else {
    return null;
  }
  return null;
}
