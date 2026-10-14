import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/announcements/presentation/pages/announcement_page.dart';
import 'pages/debug_token_page.dart';
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

/// Definisi konstanta rute terpusat untuk Campus Notify
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String debug = '/debug';
  static const String announcement = '/announcement/:id';
  static const String pengumuman = '/pengumuman/:id';

  /// Helper untuk membangun rute detail pengumuman spesifik
  static String announcementDetail(String id) => '/pengumuman/$id';
}

/// Pure function untuk mengekstrak string route dari payload notifikasi FCM.
///
/// Logika:
/// 1. Jika data kosong/null -> fallback ke default ('/')
/// 2. Jika key 'route' ada:
///    - Jika belum memiliki slash di depan (misal "pengumuman/3"), tambahkan '/'
///    - Jika string kosong, fallback ke '/'
/// 3. Jika key 'route' tidak ada namun ada key 'id':
///    - Format otomatis menjadi '/pengumuman/{id}'
/// 4. Fallback default ke '/'
String routeFromMessage(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return AppRoutes.home;
  }

  // 1. Cek explicit key 'route'
  final rawRoute = data['route']?.toString().trim();
  if (rawRoute != null && rawRoute.isNotEmpty) {
    // Memperbaiki slash di awal jika hilang (misal: "pengumuman/3" -> "/pengumuman/3")
    return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
  }

  // 2. Cek payload spesifik pengumuman dengan key 'id'
  final id = data['id']?.toString().trim();
  if (id != null && id.isNotEmpty) {
    return AppRoutes.announcementDetail(id);
  }

  // 3. Fallback jika tidak ada data rute yang valid
  return AppRoutes.home;
}
