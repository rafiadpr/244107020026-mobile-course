import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../messaging/push_service.dart';
import 'auth_provider.dart';

class FcmState {
  final String? token;
  final bool isSynced;
  final bool isLoading;
  final bool isSubscribedToTopic;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;

  const FcmState({
    this.token,
    this.isSynced = false,
    this.isLoading = false,
    this.isSubscribedToTopic = false,
    this.errorMessage,
    this.lastUpdatedAt,
  });

  /// Token terpotong 12 karakter pertama sesuai ketentuan praktikum
  String get maskedToken {
    if (token == null || token!.isEmpty) return 'Belum tersedia';
    if (token!.length <= 12) return token!;
    return '${token!.substring(0, 12)}... (Total: ${token!.length} chars)';
  }

  FcmState copyWith({
    String? token,
    bool? isSynced,
    bool? isLoading,
    bool? isSubscribedToTopic,
    String? errorMessage,
    DateTime? lastUpdatedAt,
  }) {
    return FcmState(
      token: token ?? this.token,
      isSynced: isSynced ?? this.isSynced,
      isLoading: isLoading ?? this.isLoading,
      isSubscribedToTopic: isSubscribedToTopic ?? this.isSubscribedToTopic,
      errorMessage: errorMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

// Provider untuk Service FCM
final pushServiceProvider = Provider<PushService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PushService(dio: dio);
});

// NotifierProvider untuk state token FCM
final fcmStateProvider = NotifierProvider<FcmNotifier, FcmState>(FcmNotifier.new);

class FcmNotifier extends Notifier<FcmState> {
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  FcmState build() {
    ref.onDispose(() {
      _tokenRefreshSub?.cancel();
    });

    _initPush();
    return const FcmState(isLoading: true);
  }

  Future<void> _initPush() async {
    final pushService = ref.read(pushServiceProvider);

    try {
      await pushService.initialize();
      final initialToken = await pushService.getToken();

      if (initialToken != null) {
        final synced = await pushService.syncTokenToBackend(initialToken);
        state = FcmState(
          token: initialToken,
          isSynced: synced,
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
      } else {
        state = const FcmState(
          isLoading: false,
          errorMessage: 'Token FCM belum tersedia (Pastikan Firebase sudah dikonfigurasi).',
        );
      }

      // Monitor event onTokenRefresh
      _tokenRefreshSub = pushService.onTokenRefresh.listen((newToken) async {
        debugPrint('[Riverpod] Event onTokenRefresh terpicu: $newToken');
        state = state.copyWith(isLoading: true);

        final synced = await pushService.syncTokenToBackend(newToken);
        state = state.copyWith(
          token: newToken,
          isSynced: synced,
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
      });
    } catch (e) {
      state = FcmState(
        isLoading: false,
        errorMessage: 'Gagal inisialisasi FCM: $e',
      );
    }
  }

  /// Berlangganan atau berhenti berlangganan topik pengumuman kampus
  Future<void> toggleCampusTopic(bool subscribe) async {
    final pushService = ref.read(pushServiceProvider);
    state = state.copyWith(isLoading: true);
    try {
      if (subscribe) {
        await pushService.subscribeToTopic('pengumuman-kampus');
      } else {
        await pushService.unsubscribeFromTopic('pengumuman-kampus');
      }
      state = state.copyWith(
        isLoading: false,
        isSubscribedToTopic: subscribe,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah topik: $e',
      );
    }
  }

  /// Memaksa regenerasi token baru untuk simulasi praktikum
  Future<void> forceRefreshToken() async {
    final pushService = ref.read(pushServiceProvider);
    state = state.copyWith(isLoading: true);
    try {
      await pushService.deleteToken();
      final freshToken = await pushService.getToken();
      if (freshToken != null) {
        final synced = await pushService.syncTokenToBackend(freshToken);
        state = state.copyWith(
          token: freshToken,
          isSynced: synced,
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Token gagal diperbarui.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error refresh token: $e',
      );
    }
  }
}
