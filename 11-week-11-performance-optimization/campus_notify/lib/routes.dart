import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/format.dart';
export 'core/format.dart' show AppRoutes, routeFromMessage;

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/announcements/presentation/pages/debug_token_page.dart';
import 'pages/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AsyncValue<bool>>(
    ref.read(authStateProvider),
  );
  ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Jangan redirect dulu selama inisialisasi awal pembacaan secure storage
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == AppRoutes.login;

      // Guard 1: Jika belum login dan berada di luar /login, lempar ke /login
      if (!isLoggedIn && !goingLogin) return AppRoutes.login;

      // Guard 2: Jika sudah login dan mencoba ke /login, lempar kembali ke home
      if (isLoggedIn && goingLogin) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.debug,
        builder: (context, state) => const DebugTokenPage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.pengumuman,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});
