import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle', () {
    test('menerima judul yang berisi teks', () {
      const title = 'Belajar Flutter';

      final result = isValidTaskTitle(title);

      expect(result, isTrue);
    });

    test('menerima judul dengan spasi di awal dan akhir', () {
      const title = '  Baca materi  ';

      final result = isValidTaskTitle(title);

      expect(result, isTrue);
    });

    test('menerima judul dengan satu karakter', () {
      const title = 'A';

      final result = isValidTaskTitle(title);

      expect(result, isTrue);
    });

    test('menolak teks kosong', () {
      const title = '';

      final result = isValidTaskTitle(title);

      expect(result, isFalse);
    });

    test('menolak judul yang hanya berisi spasi', () {
      const title = '   ';

      final result = isValidTaskTitle(title);

      expect(result, isFalse);
    });

    test('menolak judul yang hanya berisi tab dan baris baru', () {
      const title = '\t\n';

      final result = isValidTaskTitle(title);

      expect(result, isFalse);
    });
  });
}
