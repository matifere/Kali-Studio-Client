import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_manager.dart';

class Studio {
  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? phone;
  final String? logoUrl;
  final String? themeId;
  final int cancellationHours;
  final String? consentPdfUrl;

  const Studio({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.phone,
    this.logoUrl,
    this.themeId,
    this.cancellationHours = 2,
    this.consentPdfUrl,
  });

  factory Studio.fromMap(Map<String, dynamic> m) => Studio(
        id: m['id'] as String,
        name: m['name'] as String,
        slug: m['slug'] as String,
        address: m['address'] as String?,
        phone: m['phone'] as String?,
        logoUrl: m['logo_url'] as String?,
        themeId: m['theme_id'] as String?,
        cancellationHours: m['cancellation_hours'] as int? ?? 2,
        consentPdfUrl: m['consent_pdf_url'] as String?,
      );
}

class StudioService {
  static final _supabase = Supabase.instance.client;

  static Studio? _cachedInstitution;

  static void clearCache() => _cachedInstitution = null;

  static Future<Studio?> fetchCurrentInstitution() async {
    if (_cachedInstitution != null) return _cachedInstitution;
    final institutionId = await getInstitutionId();
    if (institutionId == null) return null;
    try {
      final data = await _supabase
          .from('institutions')
          .select('id, name, slug, address, phone, logo_url, theme_id, cancellation_hours, consent_pdf_url')
          .eq('id', institutionId)
          .maybeSingle();
      if (data == null) return null;
      _cachedInstitution = Studio.fromMap(data);
      return _cachedInstitution;
    } catch (e) {
      debugPrint('StudioService.fetchCurrentInstitution error: $e');
      return null;
    }
  }

  static Future<List<Studio>> fetchStudios() async {
    try {
      final Object raw = await _supabase
          .from('institutions')
          .select('id, name, slug, address, phone, logo_url, theme_id, cancellation_hours')
          .eq('is_active', true)
          .order('name');
      if (raw is! List) return [];
      return raw
          .map((e) => Studio.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('StudioService.fetchStudios error: $e');
      return [];
    }
  }
}
