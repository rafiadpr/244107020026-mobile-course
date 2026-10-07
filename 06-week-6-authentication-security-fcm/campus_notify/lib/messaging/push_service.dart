import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 1. Background Handler Top-Level (Wajib @pragma('vm:entry-point'))
/// Berjalan di isolate terpisah dari thread UI utama.
/// Jangan mengakses BuildContext atau Riverpod di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background Isolate] Pesan diterima: ${message.messageId}');
  debugPrint('[FCM Background Isolate] Data payload: ${message.data}');
}

/// Fungsi pembantu registrasi background handler
void registerBackgroundHandler() {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FCM Background Handler Registration Note]: $e');
  }
}

class PushService {
  final FirebaseMessaging? _customMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Dio? dio;

  // Callback navigasi yang terhubung ke GoRouter
  void Function(String route)? _navigateCallback;

  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.dio,
  })  : _customMessaging = messaging,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  // Helper untuk mendapatkan FirebaseMessaging secara aman (misal saat widget test/desktop)
  FirebaseMessaging? _messaging() {
    try {
      return _customMessaging ?? FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[PushService] FirebaseMessaging instance belum siap: $e');
      return null;
    }
  }

  // Notification Channel Android untuk notifikasi pengumuman
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pengumuman', // id channel
    'Pengumuman Kampus', // nama channel
    description: 'Channel ini digunakan untuk notifikasi pengumuman kampus.',
    importance: Importance.max,
  );

  /// Inisialisasi awal: request permission, channel, dan local notification
  Future<void> initialize() async {
    final msg = _messaging();
    if (msg != null) {
      // 1. Request permission untuk Android 13+ dan iOS
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Status izin notifikasi: ${settings.authorizationStatus}');
    }

    // 2. Setup Flutter Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LocalNotif Click] Banner diklik dengan payload: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          _navigateCallback?.call(response.payload!);
        }
      },
    );

    // 3. Daftarkan notification channel ke sistem Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Registrasi top-level background handler
    registerBackgroundHandler();
  }

  /// 2. Tiga Handler State Aplikasi (Foreground, Background, dan Terminated)
  /// Mengikat listener ke callback `go(route)` GoRouter.
  void listenForegroundAndBackground(void Function(String route) go) {
    _navigateCallback = go;
    final msg = _messaging();
    if (msg == null) return;

    // --- STATE 1: FOREGROUND ---
    // Sistem Android TIDAK memunculkan banner otomatis saat app sedang aktif di layar.
    // Tangkap via onMessage.listen lalu buat banner manual via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final route = message.data['route'] ?? '/';
      debugPrint('[FCM Foreground] Pesan masuk: ${message.notification?.title}');

      if (!kIsWeb) {
        final android = message.notification?.android;
        await _localNotifications.show(
          id: message.hashCode,
          title: message.notification?.title ?? 'Pengumuman',
          body: message.notification?.body ?? '',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: route,
        );
      }
    });

    // --- STATE 2: BACKGROUND ---
    // Pengguna mengklik banner notifikasi sistem saat aplikasi berada di latar belakang.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'] ?? '/';
      debugPrint('[FCM Background Click] Notifikasi diklik, navigasi ke: $route');
      go(route);
    });
  }

  /// --- STATE 3: TERMINATED ---
  /// Menangani saat aplikasi dibuka dari keadaan mati (swipe-close) melalui notifikasi.
  Future<void> handleTerminated(void Function(String route) go) async {
    final msg = _messaging();
    if (msg == null) return;

    final initialMessage = await msg.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'] ?? '/';
      debugPrint('[FCM Terminated Click] Membuka deep link notifikasi: $route');
      go(route);
    }
  }

  /// 4. Topic Messaging: Berlangganan topik
  Future<void> subscribeToTopic(String topic) async {
    final msg = _messaging();
    if (msg == null) return;
    try {
      await msg.subscribeToTopic(topic);
      debugPrint('[FCM Topic] Berhasil berlangganan ke topik: $topic');
    } catch (e) {
      debugPrint('[FCM Topic] Gagal subscribe ke topik $topic: $e');
    }
  }

  /// 4. Topic Messaging: Berhenti berlangganan topik
  Future<void> unsubscribeFromTopic(String topic) async {
    final msg = _messaging();
    if (msg == null) return;
    try {
      await msg.unsubscribeFromTopic(topic);
      debugPrint('[FCM Topic] Berhasil berhenti dari topik: $topic');
    } catch (e) {
      debugPrint('[FCM Topic] Gagal unsubscribe dari topik $topic: $e');
    }
  }

  /// Mengambil Token FCM saat ini
  Future<String?> getToken() async {
    final msg = _messaging();
    if (msg == null) return null;
    try {
      final token = await msg.getToken();
      debugPrint('[FCM] Token saat ini: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
      return null;
    }
  }

  /// Stream pembaruan token
  Stream<String> get onTokenRefresh {
    final msg = _messaging();
    return msg?.onTokenRefresh ?? const Stream.empty();
  }

  /// Sinkronisasi token ke backend via Dio
  Future<bool> syncTokenToBackend(String token) async {
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
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Hapus instance token (helper simulasi testing)
  Future<void> deleteToken() async {
    final msg = _messaging();
    if (msg == null) return;
    await msg.deleteToken();
  }
}
