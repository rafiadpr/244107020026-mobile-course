const offlineFaq = <String, String>{
  'pengumuman':
      'Pengumuman dapat dibuka melalui tombol pengumuman di halaman utama.',
  'notifikasi': 'Aktifkan izin notifikasi pada pengaturan perangkat agar pemberitahuan dapat masuk.',
  'jadwal': 'Jadwal resmi dapat dilihat melalui sistem akademik atau ditanyakan ke bagian akademik.',
  'beasiswa': 'Informasi beasiswa dapat ditanyakan ke bagian kemahasiswaan.',
};

String offlineAnswer(String question) {
  final query = question.toLowerCase();
  for (final entry in offlineFaq.entries) {
    if (query.contains(entry.key)) return entry.value;
  }
  return 'Informasi belum tersedia di FAQ offline. Hubungi bagian akademik untuk informasi resmi.';
}
