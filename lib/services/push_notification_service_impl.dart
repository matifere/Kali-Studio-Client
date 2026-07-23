import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('kaliPush.requestPermission')
external JSPromise<JSString> _jsRequestPermission();

@JS('kaliPush.subscribe')
external JSPromise<JSAny?> _jsSubscribe(String vapidKey);

@JS('kaliPush.getSubscription')
external JSPromise<JSAny?> _jsGetSubscription();

class PushNotificationService {
  static const _vapidKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  static bool get isSupported => kIsWeb;

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final result = await _jsRequestPermission().toDart;
      return result.toDart == 'granted';
    } catch (e) {
      return false;
    }
  }

  static Future<String?> subscribe() async {
    if (!isSupported || _vapidKey.isEmpty) return null;
    try {
      final result = await _jsSubscribe(_vapidKey).toDart;
      return (result as JSString?)?.toDart;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getExistingSubscription() async {
    if (!isSupported) return null;
    try {
      final result = await _jsGetSubscription().toDart;
      return (result as JSString?)?.toDart;
    } catch (e) {
      return null;
    }
  }
}
