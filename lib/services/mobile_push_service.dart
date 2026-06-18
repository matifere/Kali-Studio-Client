import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';

/// Handler de mensajes recibidos con la app en background o cerrada.
/// Debe ser una función top-level anotada con vm:entry-point porque corre en
/// un isolate separado. No mostramos nada acá: el sistema ya muestra la
/// notificación (viene con bloque `notification`); este handler existe para que
/// FCM entregue también el `data` y no descarte el mensaje.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Push para Android/iOS vía Firebase Cloud Messaging. El push web vive aparte
/// en push_notification_service_impl.dart (VAPID); esto es solo móvil.
///
/// Ciclo de vida:
///  - [init] una vez al arrancar (tras Firebase.initializeApp): permisos,
///    canal local, listeners de foreground/tap y onTokenRefresh.
///  - [syncToken] al loguear: guarda/actualiza el token FCM del dispositivo
///    en la tabla mobile_push_tokens para el usuario actual.
///  - [removeToken] al cerrar sesión: borra el token de este dispositivo.
class MobilePushService {
  MobilePushService._();
  static final MobilePushService instance = MobilePushService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal Android para notificaciones en foreground.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kali_default',
    'Notificaciones',
    description: 'Avisos de reservas, lista de espera y pagos.',
    importance: Importance.high,
  );

  bool _initialized = false;

  SupabaseClient get _client => Supabase.instance.client;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // Permiso de notificaciones (iOS muestra el prompt; Android 13+ también).
    await messaging.requestPermission();

    // Notificaciones locales (para mostrar mensajes en foreground).
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // En foreground FCM no muestra la notificación: la dibujamos nosotros.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Token rotado → reflejarlo en la tabla.
    messaging.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    if (_client.auth.currentSession != null) {
      await syncToken();
    }
  }

  /// Obtiene el token FCM y lo guarda para el usuario logueado. Llamar al
  /// iniciar sesión y desde [init] si ya hay sesión.
  Future<void> syncToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('MobilePushService.syncToken error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('mobile_push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': _platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,platform',
      );
    } catch (e) {
      debugPrint('MobilePushService._saveToken error: $e');
    }
  }

  /// Borra el token de este dispositivo. Llamar al cerrar sesión para que el
  /// próximo usuario del teléfono no reciba notificaciones ajenas.
  Future<void> removeToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _client.from('mobile_push_tokens').delete().eq('token', token);
    } catch (e) {
      debugPrint('MobilePushService.removeToken error: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
