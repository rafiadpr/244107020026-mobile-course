import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../../../core/providers.dart';
import '../../../../messaging/providers.dart';
import '../../data/datasources/push_service.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/register_device.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    dio: ref.watch(apiClientProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(service: ref.watch(pushServiceProvider)),
);
final registerDeviceProvider = Provider<RegisterDevice>(
  (ref) => RegisterDevice(ref.watch(announcementRepositoryProvider)),
);

class FcmState {
  const FcmState({
    this.token,
    this.isSynced = false,
    this.isLoading = false,
    this.isSubscribedToTopic = false,
    this.errorMessage,
    this.lastUpdatedAt,
  });
  final String? token;
  final bool isSynced;
  final bool isLoading;
  final bool isSubscribedToTopic;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;

  String get maskedToken {
    if (token == null || token!.isEmpty) return 'Belum tersedia';
    if (token!.length <= 12) return token!;
    return '${token!.substring(0, 12)}... (Total: ${token!.length} chars)';
  }

  String? get lastUpdatedLabel =>
      lastUpdatedAt == null ? null : localTimestampLabel(lastUpdatedAt!);

  FcmState copyWith({
    String? token,
    bool? isSynced,
    bool? isLoading,
    bool? isSubscribedToTopic,
    String? errorMessage,
    DateTime? lastUpdatedAt,
  }) => FcmState(
    token: token ?? this.token,
    isSynced: isSynced ?? this.isSynced,
    isLoading: isLoading ?? this.isLoading,
    isSubscribedToTopic: isSubscribedToTopic ?? this.isSubscribedToTopic,
    errorMessage: errorMessage,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
}

final fcmStateProvider = NotifierProvider<FcmNotifier, FcmState>(
  FcmNotifier.new,
);

class FcmNotifier extends Notifier<FcmState> {
  StreamSubscription<DeviceTokenResult>? _tokenRefreshSub;
  @override
  FcmState build() {
    ref.onDispose(() => _tokenRefreshSub?.cancel());
    _initPush();
    return const FcmState(isLoading: true);
  }

  Future<void> _initPush() async {
    final repository = ref.read(announcementRepositoryProvider);
    final initialized = await repository.initialize();
    if (!ref.mounted) return;
    if (initialized.failure != null) {
      state = FcmState(errorMessage: initialized.failure!.message);
      return;
    }
    _apply(await ref.read(registerDeviceProvider)());
    if (!ref.mounted) return;
    _tokenRefreshSub = repository.tokenRefreshes.listen((event) async {
      if (!ref.mounted) return;
      if (event.failure != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: event.failure!.message,
        );
        return;
      }
      if (event.token == null) return;
      state = state.copyWith(isLoading: true);
      _apply(await ref.read(registerDeviceProvider)(token: event.token));
    });
  }

  void _apply(DeviceRegistrationResult result) {
    if (!ref.mounted) return;
    final registration = result.registration;
    if (result.failure != null || registration == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure?.message ?? 'Token gagal diperbarui.',
      );
    } else {
      state = state.copyWith(
        token: registration.token,
        isSynced: registration.isSynced,
        lastUpdatedAt: registration.updatedAt,
        isLoading: false,
      );
    }
  }

  Future<void> toggleCampusTopic(bool subscribe) async {
    state = state.copyWith(isLoading: true);
    final result = await ref
        .read(announcementRepositoryProvider)
        .changeCampusTopic(subscribe);
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: false,
      isSubscribedToTopic: result.failure == null
          ? subscribe
          : state.isSubscribedToTopic,
      errorMessage: result.failure?.message,
    );
  }

  Future<void> forceRefreshToken() async {
    state = state.copyWith(isLoading: true);
    _apply(await ref.read(registerDeviceProvider)(forceRefresh: true));
  }
}
