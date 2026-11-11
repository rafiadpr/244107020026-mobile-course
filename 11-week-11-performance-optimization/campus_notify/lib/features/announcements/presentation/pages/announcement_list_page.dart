import 'package:flutter/material.dart';

class AnnouncementListPage extends StatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  State<AnnouncementListPage> createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  final _refreshCount = ValueNotifier<int>(0);

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) _refreshCount.value++;
  }

  @override
  void dispose() {
    _refreshCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengumuman')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Informasi kegiatan dan akademik kampus'),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _refreshCount,
            builder: (context, count, child) => Text('Pembaruan: $count'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                key: const Key('announcement-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 120,
                itemBuilder: (context, index) => AnnouncementTile(index: index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.index});

  final int index;
  static const _titles = [
    'Jadwal kuliah',
    'Pendaftaran beasiswa',
    'Seminar kampus',
  ];

  @override
  Widget build(BuildContext context) {
    final title = '${_titles[index % _titles.length]} ${index + 1}';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign)),
        title: Text(title),
        subtitle: const Text('Informasi pengumuman kampus'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => AnnouncementDetailPage(title: title),
          ),
        ),
      ),
    );
  }
}

class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Contoh informasi untuk $title.'),
      ),
    );
  }
}
