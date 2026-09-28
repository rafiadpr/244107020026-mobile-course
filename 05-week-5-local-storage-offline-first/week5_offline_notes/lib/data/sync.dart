import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/post.dart';
import 'local/db.dart';
import 'repositories/note_repository.dart';

class SyncService {
  SyncService({Future<Database> Function()? openDb, Dio? dio})
      : _openDb = openDb ?? openNotesDb,
        _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

  final Future<Database> Function() _openDb;
  final Dio _dio;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'cached_at DESC', limit: 1);
    if (rows.isEmpty) return [];

    final payload = rows.first['payload'] as String;
    final List<dynamic> jsonList = jsonDecode(payload);
    return jsonList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refreshPostsInBackground() async {
    try {
      final response = await _dio.get('/posts');
      final data = response.data as List<dynamic>;
      final payload = jsonEncode(data);

      final db = await _openDb();
      await db.transaction((txn) async {
        await txn.delete('cached_posts');
        await txn.insert('cached_posts', {
          'payload': payload,
          'cached_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      // Ignore network errors in background
    }
  }

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts();
    // Refresh background
    refreshPostsInBackground();
    return cached;
  }

  Future<int> syncNotes(NoteRepository repo) async {
    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;
    // Simulasi upload: pada project nyata, kirim tiap catatan dirty
    // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
    await Future.delayed(const Duration(seconds: 1));
    await repo.markAllSynced();
    return dirtyCount;
  }
}
