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
    final dirtyCountAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text(dirtyCountAsync.value?.toString() ?? '0'),
              isLabelVisible: (dirtyCountAsync.value ?? 0) > 0,
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
          IconButton(
            icon: const Icon(Icons.article),
            onPressed: () {
              context.push('/posts');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),

        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes. Add one!'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(note: note);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text;
              final body = bodyController.text;
              if (title.isNotEmpty) {
                final repo = ref.read(noteRepositoryProvider);
                await repo.addNote(title: title, body: body);
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
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
      subtitle: Text(note.body),
      onTap: () {
        if (note.id != null) {
          context.push('/note/${note.id}');
        }
      },
      trailing: Row(

        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty)
            const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
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

