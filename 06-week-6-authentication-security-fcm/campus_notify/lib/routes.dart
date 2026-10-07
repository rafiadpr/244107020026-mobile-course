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
