import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/format.dart';
import '../models/device_registration_model.dart';

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
  debugPrint(
    '[FCM Background Isolate] Pesan diterima ID: ${message.messageId}',
  );
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
  final DateTime Function() _clock;
  final bool allowMockFallback;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

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
    DateTime Function()? clock,
    this.allowMockFallback = true,
  }) : _customMessaging = messaging,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
       _storage = storage ?? const FlutterSecureStorage(),
       _clock = clock ?? DateTime.now;

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
      // [PERBEDAAN OS]: Android 13+ vs iOS
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint(
        '[PushService] Status izin notifikasi: ${settings.authorizationStatus}',
      );
    }

    // Setup Local Notifications untuk Heads-Up banner di foreground
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
        debugPrint(
          '[LocalNotif Click] Banner diklik dengan payload: $payloadRoute',
        );
        if (payloadRoute != null && payloadRoute.isNotEmpty) {
          _navigateCallback?.call(payloadRoute);
        }
      },
    );

    // Daftarkan Channel khusus Android
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
    final token = await msg.getToken();
    if (token != null) {
      // [KEAMANAN LOG]: Hanya menampilkan masked 12 karakter pertama di log
      final masked = token.length > 12 ? '${token.substring(0, 12)}...' : token;
      debugPrint('[PushService] Token FCM saat ini: $masked');
    }
    return token;
  }

  /// Stream listener ketika token FCM di-refresh
  Stream<String> get onTokenRefresh {
    final msg = _messaging();
    return msg?.onTokenRefresh ?? const Stream.empty();
  }

  /// Mengirimkan FCM Token ke Endpoint Backend POST /devices
  Future<DeviceRegistrationModel> syncTokenToBackend(String token) async {
    // Storage errors are operational failures, not a successful mock POST.
    await _storage.write(key: 'fcm_device_token', value: token);
    try {
      // Keamanan: Simpan token secara terenkripsi ke FlutterSecureStorage

      // [KEAMANAN LOG]: Hanya mencetak 12 karakter pertama (masked), BUKAN token utuh!
      final masked = token.length > 12 ? '${token.substring(0, 12)}...' : token;
      debugPrint(
        '[PushService] Mengirim token ($masked) ke endpoint POST /devices',
      );

      if (dio != null) {
        await dio!.post(
          '/devices',
          data: DeviceRegistrationModel(
            token: token,
            isSynced: false,
            updatedAt: _clock(),
            platform: defaultTargetPlatform.name,
          ).toMap(),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      if (!allowMockFallback) rethrow;
      debugPrint('[PushService] Mock fallback POST /devices ($e)');
    }
    return DeviceRegistrationModel(
      token: token,
      isSynced: true,
      updatedAt: _clock(),
      platform: defaultTargetPlatform.name,
    );
  }

  // --------------------------------------------------------------------------
  // STATE 1 & 2: FOREGROUND & BACKGROUND LISTENER
  // --------------------------------------------------------------------------

  void listenForegroundAndBackground(void Function(String route) go) {
    _navigateCallback = go;
    final msg = _messaging();
    if (msg == null) return;
    if (_foregroundSub != null) return;

    // --- STATE 1: FOREGROUND (onMessage) ---
    // Sistem Android TIDAK memunculkan banner otomatis saat app aktif di layar.
    // Tampilkan banner manual via flutter_local_notifications.
    _foregroundSub = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      // Menggunakan pure function routeFromMessage untuk mengekstrak rute
      final targetRoute = routeFromMessage(message.data);
      debugPrint('[FCM Foreground] Pesan masuk untuk rute: $targetRoute');

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
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      final targetRoute = routeFromMessage(message.data);
      debugPrint(
        '[FCM Background Click] Notifikasi diklik, navigasi ke: $targetRoute',
      );
      _navigateCallback?.call(targetRoute);
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
      final targetRoute = routeFromMessage(initialMessage.data);
      debugPrint('[FCM Terminated Click] Membuka deep link: $targetRoute');
      navigate?.call(targetRoute);
    }
  }

  // --------------------------------------------------------------------------
  // TOPIC MESSAGING (pengumuman-kampus)
  // --------------------------------------------------------------------------

  Future<void> subscribeToTopic(String topic) async {
    final msg = _messaging();
    if (msg == null) throw Exception('FCM unavailable');
    await msg.subscribeToTopic(topic);
    debugPrint('[FCM Topic] Berhasil berlangganan ke topik: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final msg = _messaging();
    if (msg == null) throw Exception('FCM unavailable');
    await msg.unsubscribeFromTopic(topic);
    debugPrint('[FCM Topic] Berhasil berhenti dari topik: $topic');
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

  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _navigateCallback = null;
  }
}
