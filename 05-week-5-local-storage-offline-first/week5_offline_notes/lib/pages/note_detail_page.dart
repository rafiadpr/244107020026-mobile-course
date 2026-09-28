import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

final noteDetailProvider = FutureProvider.family<String, int>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  final notes = await repo.fetchNotes();
  final note = notes.firstWhere((n) => n.id == id);
  return note.body;
});

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(noteDetailProvider(noteId));
    
    return Scaffold(
      appBar: AppBar(title: Text('Note Detail $noteId')),
      body: bodyAsync.when(
        data: (body) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(body),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
