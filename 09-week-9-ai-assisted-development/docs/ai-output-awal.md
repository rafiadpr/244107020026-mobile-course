**1. Asumsi dan daftar file**

Asumsi:

- Pencarian memakai pencocokan sebagian judul (`contains`).
- Data lokal tersedia secara sinkron sehingga tidak memerlukan state loading.
- Item membuka halaman detail contoh berdasarkan ID yang sudah tersedia. Konten detail tetap berupa contoh lama.
- Query dipertahankan selama `ProviderScope` aktif, termasuk ketika kembali dari detail.
- Tidak ada perubahan dependencies, auth, FCM, atau Firebase.

Semua path berikut relatif terhadap folder proyek **Week 9** tersebut.

| Status | File |
|---|---|
| Baru | `lib/features/announcements/domain/entities/announcement.dart` |
| Baru | `lib/features/announcements/domain/repositories/announcement_list_repository.dart` |
| Baru | `lib/features/announcements/domain/usecases/search_announcements.dart` |
| Baru | `lib/features/announcements/data/repositories/local_announcement_list_repository.dart` |
| Baru | `lib/features/announcements/presentation/providers/announcement_list_provider.dart` |
| Baru | `lib/features/announcements/presentation/pages/announcement_list_page.dart` |
| Ubah sebagian | `lib/core/format.dart` |
| Ubah sebagian | `lib/routes.dart` |
| Ubah sebagian | `lib/pages/home_page.dart` |
| Ubah sebagian | `lib/features/announcements/presentation/pages/announcement_page.dart` |
| Baru | `test/search_announcements_test.dart` |
| Baru | `test/announcement_list_provider_test.dart` |
| Baru | `test/announcement_list_page_test.dart` |

**2. Kode per file**

Untuk file baru, gunakan seluruh kode. Untuk file lama, terapkan hanya potongan perubahan yang ditunjukkan.

**`lib/features/announcements/domain/entities/announcement.dart`**

Entity hanya menyimpan informasi yang diperlukan daftar.

```dart
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}
```

**`lib/features/announcements/domain/repositories/announcement_list_repository.dart`**

Kontrak baru ini terpisah dari `AnnouncementRepository` milik FCM.

```dart
import '../entities/announcement.dart';

abstract class AnnouncementListRepository {
  List<Announcement> getAnnouncements();
}
```

**`lib/features/announcements/domain/usecases/search_announcements.dart`**

Seluruh aturan pencarian berada di domain. Hasil selalu berupa daftar baru yang tidak dapat dimodifikasi.

```dart
import '../entities/announcement.dart';
import '../repositories/announcement_list_repository.dart';

class SearchAnnouncements {
  const SearchAnnouncements(this._repository);

  final AnnouncementListRepository _repository;

  List<Announcement> call(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final source = _repository.getAnnouncements();

    if (normalizedQuery.isEmpty) {
      return List<Announcement>.unmodifiable(source);
    }

    return List<Announcement>.unmodifiable(
      source.where(
        (announcement) =>
            announcement.title.toLowerCase().contains(normalizedQuery),
      ),
    );
  }
}
```

Pencarian selalu membaca sumber utuh, bukan memfilter hasil pencarian sebelumnya. Karena itu, menghapus query dapat memulihkan seluruh daftar.

**`lib/features/announcements/data/repositories/local_announcement_list_repository.dart`**

Untuk tiga data tetap, implementasi repository dapat langsung menyimpan contoh lokal tanpa menambah datasource atau model yang belum diperlukan.

```dart
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_list_repository.dart';

class LocalAnnouncementListRepository
    implements AnnouncementListRepository {
  const LocalAnnouncementListRepository();

  static const List<Announcement> _announcements = [
    Announcement(
      id: '42',
      title: 'Jadwal Ujian Tengah Semester',
    ),
    Announcement(
      id: '43',
      title: 'Pendaftaran Beasiswa Kampus',
    ),
    Announcement(
      id: '44',
      title: 'Seminar Teknologi Informasi',
    ),
  ];

  @override
  List<Announcement> getAnnouncements() => _announcements;
}
```

**`lib/features/announcements/presentation/providers/announcement_list_provider.dart`**

Provider merangkai dependencies. Notifier menyimpan query dan hasil, lalu meminta use case melakukan pencarian.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_announcement_list_repository.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_list_repository.dart';
import '../../domain/usecases/search_announcements.dart';

final announcementListRepositoryProvider =
    Provider<AnnouncementListRepository>(
      (ref) => const LocalAnnouncementListRepository(),
    );

final searchAnnouncementsProvider = Provider<SearchAnnouncements>(
  (ref) => SearchAnnouncements(
    ref.watch(announcementListRepositoryProvider),
  ),
);

class AnnouncementListState {
  AnnouncementListState({
    required this.query,
    required List<Announcement> items,
  }) : items = List<Announcement>.unmodifiable(items);

  final String query;
  final List<Announcement> items;
}

final announcementListProvider =
    NotifierProvider<AnnouncementListNotifier, AnnouncementListState>(
      AnnouncementListNotifier.new,
    );

class AnnouncementListNotifier extends Notifier<AnnouncementListState> {
  @override
  AnnouncementListState build() {
    final search = ref.watch(searchAnnouncementsProvider);

    return AnnouncementListState(
      query: '',
      items: search(''),
    );
  }

  void setQuery(String query) {
    final search = ref.read(searchAnnouncementsProvider);

    state = AnnouncementListState(
      query: query,
      items: search(query),
    );
  }
}
```

Query pada state tetap menyimpan input asli. Normalisasi untuk pencarian hanya dilakukan use case.

**`lib/features/announcements/presentation/pages/announcement_list_page.dart`**

Widget menangani input, tombol hapus, daftar, empty state, dan navigasi. Pemisahan widget menjaga fungsi `build` tetap pendek.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_list_provider.dart';

class AnnouncementListPage extends ConsumerStatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  ConsumerState<AnnouncementListPage> createState() =>
      _AnnouncementListPageState();
}

class _AnnouncementListPageState
    extends ConsumerState<AnnouncementListPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(announcementListProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String query) {
    ref.read(announcementListProvider.notifier).setQuery(query);
  }

  void _clearQuery() {
    _controller.clear();
    _setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengumuman')),
      body: Column(
        children: [
          _SearchField(
            controller: _controller,
            hasQuery: state.query.isNotEmpty,
            onChanged: _setQuery,
            onClear: _clearQuery,
          ),
          Expanded(
            child: _AnnouncementResults(items: state.items),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: 'Cari judul pengumuman',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
      ),
    );
  }
}

class _AnnouncementResults extends StatelessWidget {
  const _AnnouncementResults({required this.items});

  final List<Announcement> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Pengumuman tidak ditemukan'),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final announcement = items[index];

        return ListTile(
          title: Text(announcement.title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(
            AppRoutes.announcementDetail(announcement.id),
          ),
        );
      },
    );
  }
}
```

`TextEditingController` dibersihkan secara eksplisit bersama state karena `controller.clear()` tidak memanggil `onChanged`.

**`lib/core/format.dart` — tambah konstanta**

Tambahkan di dalam `AppRoutes`:

```dart
static const String announcements = '/announcements';
```

Konstanta dan fungsi lain tetap seperti sekarang, termasuk `announcementDetail()` dan `routeFromMessage()`.

**`lib/routes.dart` — tambah import dan route**

Tambahkan import:

```dart
import 'features/announcements/presentation/pages/announcement_list_page.dart';
```

Tambahkan satu `GoRoute` dalam daftar `routes`, misalnya setelah route home:

```dart
GoRoute(
  path: AppRoutes.announcements,
  builder: (context, state) => const AnnouncementListPage(),
),
```

Route detail `/announcement/:id` dan `/pengumuman/:id` tetap tersedia. Route daftar menggunakan auth guard yang sudah ada.

**`lib/pages/home_page.dart` — ubah tombol pengumuman**

Tambahkan import:

```dart
import '../core/format.dart';
```

Ganti tombol `Buka Pengumuman #42` dengan:

```dart
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.announcement),
    label: const Text('Buka Daftar Pengumuman'),
    onPressed: () => context.push(AppRoutes.announcements),
  ),
),
```

**`lib/features/announcements/presentation/pages/announcement_page.dart` — sesuaikan tombol kembali**

Pada `leading` di AppBar, ganti callback `onPressed` menjadi:

```dart
onPressed: () {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go('/');
},
```

Dari daftar, `pop()` kembali ke daftar dan query sebelumnya. Ketika detail dibuka langsung lewat notifikasi tanpa halaman sebelumnya, fallback tetap ke home. Tombol **Kembali ke Halaman Utama** di bagian bawah tetap seperti sekarang.

**3. Unit test perilaku pencarian**

**`test/search_announcements_test.dart`**

Fake repository sengaja menggunakan daftar mutable agar test dapat mendeteksi jika use case mengubah sumber.

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_list_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/search_announcements.dart';

class FakeAnnouncementListRepository
    implements AnnouncementListRepository {
  FakeAnnouncementListRepository(this.items);

  final List<Announcement> items;

  @override
  List<Announcement> getAnnouncements() => items;
}

void main() {
  late List<Announcement> source;
  late SearchAnnouncements search;

  setUp(() {
    source = [
      const Announcement(
        id: '42',
        title: 'Jadwal Ujian Tengah Semester',
      ),
      const Announcement(
        id: '43',
        title: 'Pendaftaran Beasiswa Kampus',
      ),
      const Announcement(
        id: '44',
        title: 'Seminar Teknologi Informasi',
      ),
    ];

    search = SearchAnnouncements(
      FakeAnnouncementListRepository(source),
    );
  });

  List<String> ids(List<Announcement> items) =>
      items.map((item) => item.id).toList();

  test('Query kosong menampilkan seluruh data sesuai urutan sumber', () {
    expect(ids(search('')), ['42', '43', '44']);
  });

  test('Query berisi spasi saja menampilkan seluruh data', () {
    expect(ids(search('   ')), ['42', '43', '44']);
  });

  test('Pencarian mencocokkan sebagian judul tanpa membedakan kapital', () {
    expect(ids(search('uJiAn')), ['42']);
    expect(ids(search('BEASISWA')), ['43']);
  });

  test('Spasi awal dan akhir query diabaikan', () {
    expect(ids(search('  beasiswa  ')), ['43']);
  });

  test('Pencarian tidak mencocokkan ID', () {
    expect(search('42'), isEmpty);
  });

  test('Query tidak cocok menghasilkan daftar kosong', () {
    expect(search('judul tidak tersedia'), isEmpty);
  });

  test('Menghapus query memulihkan seluruh daftar', () {
    expect(ids(search('seminar')), ['44']);
    expect(ids(search('')), ['42', '43', '44']);
  });

  test('Pencarian tidak mengubah isi atau urutan daftar sumber', () {
    final original = List<Announcement>.of(source);

    search('beasiswa');
    search('tidak tersedia');
    search('');

    expect(source, orderedEquals(original));
    expect(ids(source), ['42', '43', '44']);
  });

  test('Hasil merupakan salinan yang tidak dapat dimodifikasi', () {
    for (final query in ['', 'ujian']) {
      final result = search(query);

      expect(identical(result, source), isFalse);
      expect(
        () => result.clear(),
        throwsUnsupportedError,
      );
    }

    expect(source, hasLength(3));
  });
}
```

Tambahan test Notifier memastikan perubahan input benar-benar memperbarui state dan pemulihan daftar.

**`test/announcement_list_provider_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcements/presentation/providers/announcement_list_provider.dart';

void main() {
  test('Notifier memperbarui query, hasil, dan memulihkan daftar', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialItems = container.read(announcementListProvider).items;
    final notifier = container.read(announcementListProvider.notifier);

    expect(initialItems, hasLength(3));

    notifier.setQuery('  BEASISWA  ');

    final filtered = container.read(announcementListProvider);
    expect(filtered.query, '  BEASISWA  ');
    expect(
      filtered.items.map((item) => item.id),
      orderedEquals(['43']),
    );

    notifier.setQuery('tidak tersedia');
    expect(container.read(announcementListProvider).items, isEmpty);

    notifier.setQuery('');

    final restored = container.read(announcementListProvider);
    expect(restored.query, '');
    expect(restored.items, orderedEquals(initialItems));
    expect(initialItems, hasLength(3));
  });
}
```

**4. Satu widget test untuk empty state**

**`test/announcement_list_page_test.dart`**

Test menguji input nyata sampai empty state, lalu tombol hapus sampai daftar pulih. Halaman dirender langsung sehingga test ini tidak menginisialisasi auth maupun Firebase.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcements/presentation/pages/announcement_list_page.dart';

void main() {
  testWidgets(
    'Query tidak cocok menampilkan empty state dan hapus memulihkan daftar',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnnouncementListPage(),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(
        find.text('Pengumuman tidak ditemukan'),
        findsNothing,
      );

      await tester.enterText(
        find.byType(TextField),
        'judul tidak tersedia',
      );
      await tester.pump();

      expect(
        find.text('Pengumuman tidak ditemukan'),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNothing);

      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pump();

      expect(
        find.text('Pengumuman tidak ditemukan'),
        findsNothing,
      );
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );
}
```

**5. Cara menjalankan dan menguji**

Perintah berikut **untuk dijalankan setelah Anda menerapkan kode**. Saya belum menjalankannya.

Masuk ke proyek Week 9:

```powershell
Set-Location 'E:\Code\mob_dev\244107020026-mobile-course\09-week-9-ai-assisted-development\campus_notify'
```

Jalankan tiga file test fitur:

```powershell
flutter test test/search_announcements_test.dart test/announcement_list_provider_test.dart test/announcement_list_page_test.dart
```

Lanjutkan pemeriksaan statis dan regresi:

```powershell
flutter analyze
flutter test
```

Test lama `test/widget_test.dart` menjalankan `MyApp`, yang mengaktifkan listener FCM. Jika test tersebut gagal karena kebutuhan platform/Firebase, kegagalannya perlu diperiksa terpisah; ketiga test baru di atas tidak membutuhkan inisialisasi Firebase.

Jalankan aplikasi:

```powershell
flutter run
```

Pemeriksaan manual yang direncanakan:

| Tindakan | Hasil yang diharapkan |
|---|---|
| Login, buka daftar | Tiga judul tampil |
| Ketik `uJiAn` | Jadwal Ujian Tengah Semester tampil |
| Ketik `  BEASISWA  ` | Pendaftaran Beasiswa Kampus tampil |
| Ketik `tidak tersedia` | `Pengumuman tidak ditemukan` tampil |
| Tekan tombol hapus | Tiga judul kembali |
| Cari `seminar`, buka item, tekan kembali di AppBar | Kembali ke daftar dengan query `seminar` |

Ini merupakan petunjuk pengujian, belum menjadi bukti hasil pengujian.

**6. Alur data dan tanggung jawab layer**

Alur pencarian:

```text
Input pengguna
    → Widget memanggil Notifier.setQuery()
    → Notifier memanggil SearchAnnouncements
    → Use case membaca AnnouncementListRepository
    → Repository lokal menyediakan daftar sumber
    → Use case menormalisasi query dan memfilter judul
    → Notifier menyimpan state baru
    → Widget menampilkan daftar atau empty state
```

- **Domain:** entity, kontrak repository, dan aturan pencarian. Seluruhnya Dart murni.
- **Data:** menyediakan daftar contoh melalui implementasi kontrak domain.
- **Notifier:** mengelola query dan hasil pencarian sebagai state.
- **Widget:** menerima input, menampilkan state, dan membuka detail berdasarkan ID.
- **Provider:** menyambungkan repository, use case, dan Notifier mengikuti pola Riverpod proyek.
- **Navigasi:** Home → daftar → detail menggunakan `push`; kembali dari detail menggunakan `pop`.

Usulan belum diterapkan atau diverifikasi melalui eksekusi. Review AI Challenge, refleksi, dan bukti pengujian tidak dikerjakan pada tahap ini.