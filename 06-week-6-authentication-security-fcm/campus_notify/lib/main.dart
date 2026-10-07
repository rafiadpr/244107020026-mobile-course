import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/debug_token_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/fcm_provider.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AsyncValue<bool>>(ref.read(authStateProvider));
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
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.pengumuman,
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi listener navigasi FCM setelah frame UI pertama siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pushService = ref.read(pushServiceProvider);
      final router = ref.read(routerProvider);

      void navigate(String route) {
        debugPrint('[FCM Navigation] Berpindah ke rute: $route');
        router.go(route);
      }

      // Handler Foreground & Background
      pushService.listenForegroundAndBackground(navigate);

      // Handler Terminated (cold-start)
      pushService.handleTerminated(navigate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
