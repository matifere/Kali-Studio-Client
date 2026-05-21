class PushNotificationService {
  static bool get isSupported => false;
  static Future<bool> requestPermission() async => false;
  static Future<String?> subscribe() async => null;
  static Future<String?> getExistingSubscription() async => null;
}
