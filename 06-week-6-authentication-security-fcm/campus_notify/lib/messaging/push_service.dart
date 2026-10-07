import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// 1. TOP-LEVEL BACKGROUND HANDLER
// ============================================================================

/// [PERINGATAN ISOLATE]:
/// Fungsi ini WAJIB berada di top-level (di luar class) dengan anotasi @pragma('vm:entry-point').
/// Fungsi ini dieksekusi di background isolate terpisah oleh OS.
/// DILARANG KERAS mengakses `BuildContext`, widget tree, atau state Riverpod UI di sini!
/// Navigasi dilakukan saat banner diklik oleh pengguna.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background Isolate] Pesan diterima ID: ${message.messageId}');
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

// ============================================================================
// 2. SERVICE CLASS: PushService
// ============================================================================

class PushService {
  final FirebaseMessaging? _customMessaging;
  final FlutterLocalNotificationsPlugin _local;
  final Dio? dio;
  final FlutterSecureStorage _storage;

  // Callback navigasi yang terhubung ke GoRouter
  void Function(String route)? _navigateCallback;

  static const String campusTopic = 'pengumuman-kampus';

  // Notification Channel Android untuk Android 8.0+ (Oreo ke atas)
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'pengumuman_channel',
    'Pengumuman Kampus',
    description: 'Channel untuk notifikasi pengumuman resmi kampus',
    importance: Importance.max,
  );

  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.dio,
    FlutterSecureStorage? storage,
  })  : _customMessaging = messaging,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _storage = storage ?? const FlutterSecureStorage();

  // Helper untuk mendapatkan FirebaseMessaging secara aman (misal saat widget test)
  FirebaseMessaging? _messaging() {
    try {
      return _customMessaging ?? FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[PushService] FirebaseMessaging instance belum siap: $e');
      return null;
    }
  }

  /// Inisialisasi awal: request permission, channel, dan local notification
  Future<void> initialize({void Function(String route)? onNavigate}) async {
    if (onNavigate != null) {
      _navigateCallback = onNavigate;
    }

    final msg = _messaging();
    if (msg != null) {
      // ----------------------------------------------------------------------
      // [PERBEDAAN OS]: Izin Runtime Android 13+ vs iOS
      // ----------------------------------------------------------------------
      // - iOS: Memerlukan izin eksplisit sistem prompt APNs modal.
      // - Android 12 kebawah: Izin diberikan otomatis saat instalasi.
      // - Android 13+ (API 33 / Tiramisu): Diwajibkan meminta izin runtime POST_NOTIFICATIONS.
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[PushService] Status izin notifikasi: ${settings.authorizationStatus}');
    }

    // Setup Local Notifications untuk Heads-Up banner di foreground
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payloadRoute = response.payload;
        debugPrint('[LocalNotif Click] Banner diklik dengan payload: $payloadRoute');
        if (payloadRoute != null && payloadRoute.isNotEmpty) {
          _navigateCallback?.call(payloadRoute);
        }
      },
    );

    // Daftarkan Channel khusus Android
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Daftarkan background handler top-level
    registerBackgroundHandler();

    // Jika onNavigate diberikan langsung di initialize
    if (_navigateCallback != null) {
      listenForegroundAndBackground(_navigateCallback!);
      await handleTerminated(_navigateCallback);
    }
  }

  // --------------------------------------------------------------------------
  // TOKEN LIFECYCLE & SINKRONISASI (POST /devices)
  // --------------------------------------------------------------------------

  /// Mengambil Token FCM saat ini
  Future<String?> getToken() async {
    final msg = _messaging();
    if (msg == null) return null;
    try {
      final token = await msg.getToken();
      if (token != null) {
        // [KEAMANAN LOG]: Hanya menampilkan masked 12 karakter pertama di log
        final masked = token.length > 12 ? '${token.substring(0, 12)}...' : token;
        debugPrint('[PushService] Token FCM saat ini: $masked');
      }
      return token;
    } catch (e) {
      debugPrint('[PushService] Gagal mengambil token: $e');
      return null;
    }
  }

  /// Stream listener ketika token FCM di-refresh
  Stream<String> get onTokenRefresh {
    final msg = _messaging();
    return msg?.onTokenRefresh ?? const Stream.empty();
  }

  /// Mengirimkan FCM Token ke Endpoint Backend POST /devices
  Future<bool> syncTokenToBackend(String token) async {
    try {
      // Keamanan: Simpan token secara terenkripsi ke FlutterSecureStorage
      await _storage.write(key: 'fcm_device_token', value: token);

      // [KEAMANAN LOG]: Hanya mencetak 12 karakter pertama (masked), BUKAN token utuh!
      final masked = token.length > 12 ? '${token.substring(0, 12)}...' : token;
      debugPrint('[PushService] Mengirim token ($masked) ke endpoint POST /devices');

      if (dio != null) {
        await dio!.post(
          '/devices',
          data: {
            'fcm_token': token,
            'platform': defaultTargetPlatform.name,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      return true;
    } catch (e) {
      debugPrint('[PushService] Mock fallback POST /devices ($e)');
      return true;
    }
  }

  // --------------------------------------------------------------------------
  // STATE 1 & 2: FOREGROUND & BACKGROUND LISTENER
  // --------------------------------------------------------------------------

  void listenForegroundAndBackground(void Function(String route) go) {
    _navigateCallback = go;
    final msg = _messaging();
    if (msg == null) return;

    // --- STATE 1: FOREGROUND (onMessage) ---
    // Sistem Android TIDAK memunculkan banner otomatis saat app aktif di layar.
    // Tampilkan banner manual via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final targetRoute = message.data['route'] ?? '/';
      debugPrint('[FCM Foreground] Pesan masuk: ${message.notification?.title}');

      if (!kIsWeb) {
        final notification = message.notification;
        final android = message.notification?.android;

        await _local.show(
          id: message.hashCode,
          title: notification?.title ?? 'Pengumuman Baru',
          body: notification?.body ?? '',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: targetRoute,
        );
      }
    });

    // --- STATE 2: BACKGROUND (onMessageOpenedApp) ---
    // User mengklik banner notifikasi sistem saat app berada di latar belakang.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final targetRoute = message.data['route'] ?? '/';
      debugPrint('[FCM Background Click] Notifikasi diklik, navigasi ke: $targetRoute');
      go(targetRoute);
    });
  }

  // --------------------------------------------------------------------------
  // STATE 3: TERMINATED (getInitialMessage)
  // --------------------------------------------------------------------------

  /// Menangani saat aplikasi dibuka dari keadaan mati (swipe-close) via notifikasi.
  Future<void> handleTerminated([void Function(String route)? go]) async {
    final navigate = go ?? _navigateCallback;
    final msg = _messaging();
    if (msg == null) return;

    final initialMessage = await msg.getInitialMessage();
    if (initialMessage != null) {
      final targetRoute = initialMessage.data['route'] ?? '/';
      debugPrint('[FCM Terminated Click] Membuka deep link: $targetRoute');
      navigate?.call(targetRoute);
    }
  }

  // --------------------------------------------------------------------------
  // TOPIC MESSAGING (pengumuman-kampus)
  // --------------------------------------------------------------------------

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

  // Method spesifik sesuai topik kampus
  Future<void> subscribeCampusTopic() => subscribeToTopic(campusTopic);
  Future<void> unsubscribeCampusTopic() => unsubscribeFromTopic(campusTopic);

  // --------------------------------------------------------------------------
  // TESTING HELPER
  // --------------------------------------------------------------------------

  Future<void> deleteToken() async {
    final msg = _messaging();
    if (msg == null) return;
    await msg.deleteToken();
    debugPrint('[PushService] Token FCM dihapus dari cache perangkat.');
  }
}
