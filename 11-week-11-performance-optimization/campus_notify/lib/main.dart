import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/announcements/presentation/providers/fcm_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
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
      final repository = ref.read(announcementRepositoryProvider);
      final router = ref.read(routerProvider);

      void navigate(String route) {
        debugPrint('[FCM Navigation] Berpindah ke rute: $route');
        router.go(route);
      }

      // Handler Foreground & Background
      final listening = repository.listenNotifications(navigate);
      if (listening.failure != null) debugPrint(listening.failure!.message);

      // Handler Terminated (cold-start)
      repository.handleInitialNotification(navigate).then((result) {
        if (result.failure != null) debugPrint(result.failure!.message);
      });
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
