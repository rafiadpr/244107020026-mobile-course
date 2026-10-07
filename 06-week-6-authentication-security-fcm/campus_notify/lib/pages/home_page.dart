import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug FCM Token',
            onPressed: () => context.go('/debug'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Selamat Datang!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda berhasil login dan berada di halaman yang aman.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.announcement),
                  label: const Text('Buka Pengumuman #42'),
                  onPressed: () => context.go('/announcement/42'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Buka Halaman Debug FCM Token'),
                  onPressed: () => context.go('/debug'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}