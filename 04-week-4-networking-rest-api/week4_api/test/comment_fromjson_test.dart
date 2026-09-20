// Unit test untuk Comment.fromJson
//
// Jalankan dengan:
//   flutter test test/comment_fromjson_test.dart
//
// Test ini bersifat murni (pure unit test): tidak membutuhkan Flutter
// engine, tidak ada HTTP, tidak ada widget — hanya logika parsing JSON.

import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  // ─── Grup: parsing data lengkap ───────────────────────────────────────────
  group('Comment.fromJson — data lengkap', () {
    test('semua field terbaca dengan benar', () {
      // Arrange: JSON persis seperti yang dikirim JSONPlaceholder.
      const json = {
        'postId': 1,
        'id': 5,
        'name': 'vero eaque aliquid doloribus et culpa',
        'email': 'Hayden@althea.biz',
        'body': 'harum non quasi et ratione\n...',
      };

      // Act: parse JSON menjadi objek Comment.
      final comment = Comment.fromJson(json);

      // Assert: setiap field harus sesuai nilai JSON.
      expect(comment.postId, 1);
      expect(comment.id, 5);
      expect(comment.name, 'vero eaque aliquid doloribus et culpa');
      expect(comment.email, 'Hayden@althea.biz');
      expect(comment.body, 'harum non quasi et ratione\n...');
    });
  });

  // ─── Grup: field yang hilang / null ───────────────────────────────────────
  group('Comment.fromJson — field yang hilang', () {
    test('semua field hilang → nilai default dipakai, tidak crash', () {
      // Arrange: JSON kosong — tidak ada satu pun field.
      // Ini mensimulasikan respons API yang tidak terduga / rusak.
      const json = <String, dynamic>{};

      // Act: parsing seharusnya tidak melempar exception.
      final comment = Comment.fromJson(json);

      // Assert: setiap field menggunakan nilai default yang aman.
      expect(comment.postId, 0,
          reason: 'postId hilang → default 0');
      expect(comment.id, 0,
          reason: 'id hilang → default 0');
      expect(comment.name, '',
          reason: 'name hilang → default string kosong');
      expect(comment.email, '',
          reason: 'email hilang → default string kosong');
      expect(comment.body, '',
          reason: 'body hilang → default string kosong');
    });

    test('hanya postId & email yang ada, sisanya hilang', () {
      // Arrange: JSON parsial — hanya sebagian field tersedia.
      // Ini memvalidasi bahwa setiap field di-handle secara independen.
      const json = <String, dynamic>{
        'postId': 3,
        'email': 'partial@example.com',
      };

      final comment = Comment.fromJson(json);

      // Field yang ada harus terbaca dengan benar.
      expect(comment.postId, 3);
      expect(comment.email, 'partial@example.com');

      // Field yang hilang tetap menggunakan default.
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.body, '');
    });

    test('field numerik bertipe null di JSON → default 0', () {
      // Arrange: field ada dalam JSON tapi nilainya null secara eksplisit.
      // Kasus ini terjadi jika server mengirim {"postId": null, "id": null}.
      const json = <String, dynamic>{
        'postId': null,
        'id': null,
        'name': 'Ada nama',
        'email': null,
        'body': 'Ada body',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);  // null → 0
      expect(comment.id, 0);      // null → 0
      expect(comment.name, 'Ada nama');
      expect(comment.email, ''); // null → ''
      expect(comment.body, 'Ada body');
    });
  });

  // ─── Grup: round-trip (toJson → fromJson) ─────────────────────────────────
  group('Comment.toJson → fromJson round-trip', () {
    test('objek asli sama dengan hasil parse ulang', () {
      const original = Comment(
        postId: 7,
        id: 42,
        name: 'Test User',
        email: 'test@example.com',
        body: 'Isi komentar.',
      );

      // Serialisasi lalu parse kembali.
      final decoded = Comment.fromJson(original.toJson());

      expect(decoded.postId, original.postId);
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.email, original.email);
      expect(decoded.body, original.body);
    });
  });
}
