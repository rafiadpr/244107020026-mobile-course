import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/local/note.dart' as note_model;

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider).value ?? 0;
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Tombol Sync dengan badge jumlah dirty
          IconButton(
            icon: Badge(
              label: Text(dirtyCount.toString()),
              isLabelVisible: dirtyCount > 0,
              child: const Icon(Icons.sync),
            ),
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);
              final syncService = ref.read(syncServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing notes...')),
              );
              await syncService.syncNotes(repo);
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync complete!')),
                );
              }
            },
          ),
          // Tombol Posts
          IconButton(
            icon: const Icon(Icons.article),
            onPressed: () => context.push('/posts'),
          ),
          // Tombol Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Force Offline + Dirty Notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Force Offline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 8),
                Text(
                  isOffline ? 'Simulasi offline aktif' : 'Simulasi online aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOffline ? Colors.red : Colors.green,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isOffline,
                  onChanged: (val) {
                    ref.read(forceOfflineProvider.notifier).setOffline(val);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Dirty Notes: $dirtyCount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(),
          // Daftar catatan
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada catatan. Tambah dulu!'));
                }
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return NoteTile(note: notes[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Isi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isNotEmpty) {
                final repo = ref.read(noteRepositoryProvider);
                await repo.addNote(title: title, body: body);
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

class NoteTile extends ConsumerWidget {
  const NoteTile({super.key, required this.note});

  final note_model.Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.body.isEmpty ? '(tidak ada isi)' : note.body),
      onTap: () {
        if (note.id != null) context.push('/note/${note.id}');
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cloud off = belum sync, cloud done = sudah sync
          Icon(
            note.dirty ? Icons.cloud_off : Icons.cloud_done,
            color: note.dirty ? Colors.orange : Colors.green,
            size: 22,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);
              if (note.id != null) {
                await repo.deleteNote(note.id!);
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}
