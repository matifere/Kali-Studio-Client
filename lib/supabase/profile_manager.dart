import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String uuid;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> patologias;
  final String? institutionId;

  const Profile({
    required this.uuid,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.avatarUrl,
    this.patologias = const [],
    this.institutionId,
  });
}

String? _cachedInstitutionId;
bool _institutionIdCached = false;
Future<String?>? _institutionIdFuture;

Future<String?> getInstitutionId() {
  if (_institutionIdCached) return Future.value(_cachedInstitutionId);
  _institutionIdFuture ??= _fetchInstitutionId();
  return _institutionIdFuture!;
}

Future<String?> _fetchInstitutionId() async {
  final userId = Supabase.instance.client.auth.currentSession?.user.id;
  if (userId == null) return null;
  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('institution_id')
        .eq('id', userId)
        .maybeSingle();
    _cachedInstitutionId = data?['institution_id'] as String?;
    _institutionIdCached = true;
    return _cachedInstitutionId;
  } catch (_) {
    return null;
  } finally {
    _institutionIdFuture = null;
  }
}

void clearProfileCache() {
  _cachedInstitutionId = null;
  _institutionIdCached = false;
  _institutionIdFuture = null;
}

Future<Profile?> obtenerPerfil() async {
  final userId =
      Supabase.instance.client.auth.currentSession?.user.id;
  if (userId == null) return null;

  try {
    final userData = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, phone, avatar_url, role, is_active, created_at, updated_at, patologias, institution_id')
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) return null;

    final rawPatologias = userData['patologias'];
    final patologias = rawPatologias is List
        ? rawPatologias.map((e) => e.toString()).toList()
        : <String>[];

    return Profile(
      uuid: userData['id'] as String,
      fullName: userData['full_name'] as String? ?? '',
      role: userData['role'] as String? ?? 'client',
      isActive: userData['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(userData['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(userData['updated_at'] as String? ?? '') ?? DateTime.now(),
      phone: userData['phone'] as String?,
      avatarUrl: userData['avatar_url'] as String?,
      patologias: patologias,
      institutionId: userData['institution_id'] as String?,
    );
  } catch (e) {
    return null;
  }
}
