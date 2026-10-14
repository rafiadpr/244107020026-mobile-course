import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fcm_provider.dart';

class DebugTokenPage extends ConsumerWidget {
  const DebugTokenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmState = ref.watch(fcmStateProvider);
    final fcmNotifier = ref.read(fcmStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM & Token Lifecycle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Status Token
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.token, color: Colors.indigo),
                        const SizedBox(width: 8),
                        const Text(
                          'FCM Token Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (fcmState.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Tampilan Token Terpotong (Syarat Wajib Praktikum: 12 Karakter)
                    const Text(
                      'FCM Token (12 Karakter Pertama):',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        fcmState.maskedToken,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Copy Full Token Button
                    if (fcmState.token != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin Token Penuh untuk Firebase Console'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: fcmState.token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token FCM penuh berhasil disalin ke clipboard!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // Status Sinkronisasi Backend
                    Row(
                      children: [
                        const Text(
                          'Sinkronisasi Backend:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: Icon(
                            fcmState.isSynced ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            fcmState.isSynced ? 'TERHUBUNG (OK)' : 'BELUM SINKRON',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: fcmState.isSynced ? Colors.green : Colors.red,
                        ),
                      ],
                    ),

                    if (fcmState.lastUpdatedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pembaruan Terakhir: ${fcmState.lastUpdatedAt!.toLocal()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],

                    if (fcmState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fcmState.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card Topic Messaging (Praktikum 3: Topic)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                secondary: const Icon(Icons.campaign, color: Colors.deepPurple),
                title: const Text('Topik: pengumuman-kampus'),
                subtitle: Text(
                  fcmState.isSubscribedToTopic
                      ? 'Status: Berlangganan (Akan menerima broadcast)'
                      : 'Status: Tidak berlangganan',
                  style: TextStyle(
                    color: fcmState.isSubscribedToTopic ? Colors.green : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                value: fcmState.isSubscribedToTopic,
                onChanged: fcmState.isLoading
                    ? null
                    : (val) async {
                        await fcmNotifier.toggleCampusTopic(val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val
                                  ? 'Berhasil subscribe ke topik pengumuman-kampus!'
                                  : 'Berhenti berlangganan dari pengumuman-kampus.'),
                            ),
                          );
                        }
                      },
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Trigger Refresh Token Langsung (Testing Helper)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Simulasi Trigger onTokenRefresh (Hapus & Buat Baru)'),
                onPressed: fcmState.isLoading
                    ? null
                    : () async {
                        await fcmNotifier.forceRefreshToken();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Permintaan refresh token telah dikirim!'),
                            ),
                          );
                        }
                      },
              ),
            ),

            const SizedBox(height: 24),

            // Petunjuk Pengujian Praktikum 3
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Matriks Pengujian Praktikum 3',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Foreground: Aplikasi terbuka, kirim pesan -> Banner lokal muncul -> Klik banner membuka /pengumuman/3.\n\n'
                      '2. Background: Tekan tombol Home, kirim pesan -> Banner sistem muncul -> Klik banner membuka /pengumuman/3.\n\n'
                      '3. Terminated: Swipe-close / kill aplikasi, kirim pesan -> Klik banner membuka aplikasi langsung ke /pengumuman/3.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
