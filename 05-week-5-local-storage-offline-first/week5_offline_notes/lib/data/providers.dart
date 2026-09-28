import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'repositories/note_repository.dart';
import 'sync.dart';
import 'local/note.dart';
import 'local/post.dart';
import 'prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOffline(bool value) {
    state = value;
  }
}


final noteRepositoryProvider = Provider((ref) => NoteRepository());

final syncServiceProvider = Provider((ref) => SyncService(
      dio: Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com')),
    ));

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.countDirty();
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  final isOffline = ref.watch(forceOfflineProvider);
  
  if (isOffline) {
    // If offline, only read from cache
    return syncService.readCachedPosts();
  } else {
    // If online, perform cache-first read and refresh
    return syncService.loadPostsCacheFirst();
  }
});

