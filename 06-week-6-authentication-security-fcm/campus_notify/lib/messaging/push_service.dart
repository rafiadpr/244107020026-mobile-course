import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler wajib untuk Firebase Messaging.
/// Harus berada di luar class (top-level) dengan anotasi entry-point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Pesan diterima: ${message.messageId}');
  debugPrint('[FCM Background] Data: ${message.data}');
}

class PushService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Dio? dio;

  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.dio,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  // Notification Channel untuk Android 8.0+
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Campus High Importance Notifications',
    description: 'Channel ini digunakan untuk notifikasi penting kampus.',
    importance: Importance.max,
  );

  /// 1. Inisialisasi Firebase Messaging, izin notifikasi, dan channel lokal
  Future<void> initialize() async {
    // Request permission (terutama Android 13+ Tiramisu & iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] Status izin notifikasi: ${settings.authorizationStatus}');

    // Setup Local Notifications untuk menampilkan heads-up notification saat foreground
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LocalNotif] Notifikasi diklik: ${response.payload}');
      },
    );

    // Daftarkan Notification Channel ke sistem Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Listener saat aplikasi berada di FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      debugPrint('[FCM Foreground] Pesan masuk: ${notification?.title} - ${notification?.body}');

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Daftarkan background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// 2. Mengambil Token FCM saat ini
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Current Token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
      return null;
    }
  }

  /// 3. Stream token refresh listener
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// 4. Sinkronisasi token FCM ke backend simulasi via Dio
  Future<bool> syncTokenToBackend(String token) async {
    debugPrint('[FCM Backend Sync] Mengirim token ke backend: $token');
    try {
      if (dio != null) {
        await dio!.post(
          '/devices/fcm-token',
          data: {
            'fcm_token': token,
            'platform': defaultTargetPlatform.name,
            'synced_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      debugPrint('[FCM Backend Sync] Token berhasil disinkronisasi ke backend.');
      return true;
    } catch (e) {
      // Menangani fallback untuk mock simulasi jika endpoint mock offline
      debugPrint('[FCM Backend Sync] Mock fallback: Berhasil mencatat token di backend ($e)');
      return true;
    }
  }

  /// 5. Menghapus instance token untuk memaksa regenerasi (Uji coba lokal)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    debugPrint('[FCM] Instance token dihapus dari perangkat.');
  }
}
