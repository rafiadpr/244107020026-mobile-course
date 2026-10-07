import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman #$id'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.campaign, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengumuman Resmi Kampus #$id',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dipublikasikan: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Pemberitahuan Penting Mahasiswa:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ini adalah contoh detail isi pengumuman kampus yang berhasil diakses '
                      'melalui rute terproteksi /announcement/:id. Halaman ini hanya dapat diakses '
                      'jika sesi pengguna telah terotentikasi.',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Halaman Utama'),
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
