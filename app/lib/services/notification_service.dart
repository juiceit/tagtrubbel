import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static const _deviceIdKey = 'device_id';
  final ApiService _api;

  NotificationService(this._api);

  Future<String?> registerDevice() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }

    final token = await messaging.getToken();
    if (token == null) return null;

    final platform = Platform.isIOS ? 'ios' : 'android';
    final deviceId = await _api.registerDevice(
      fcmToken: token,
      platform: platform,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);

    messaging.onTokenRefresh.listen((newToken) async {
      await _api.registerDevice(fcmToken: newToken, platform: platform);
    });

    return deviceId;
  }

  static Future<String?> getStoredDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static Future<void> clearStoredDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}
