import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class VersionService {
  static final VersionService _instance = VersionService._internal();
  static VersionService get instance => _instance;

  String? _currentVersion;
  Timer? _timer;

  VersionService._internal();

  /// Inicializa el chequeo de versión.
  /// Si estamos en web, lee la versión inicial y luego arranca un timer.
  void init() {
    if (!kIsWeb) return;
    
    // Hacemos el primer chequeo para guardar la versión base sin recargar
    _checkVersion(isInit: true);

    // Luego chequeamos cada 1 minuto si hay una nueva versión
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion({bool isInit = false}) async {
    if (!kIsWeb) return;

    try {
      // Agregamos un timestamp para asegurarnos que el navegador no cachee la petición del JSON
      final uri = Uri.parse('/version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedVersion = data['version'] as String?;

        if (fetchedVersion != null) {
          if (isInit || _currentVersion == null) {
            // Guardamos la versión actual
            _currentVersion = fetchedVersion;
          } else if (_currentVersion != fetchedVersion) {
            // ¡Hay una versión nueva! Forzamos la recarga de la página.
            // Esto actualizará los assets cacheados sin desloguear al usuario.
            html.window.location.reload();
          }
        }
      }
    } catch (e) {
      // Ignorar errores de red silenciosamente, puede estar sin internet
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
