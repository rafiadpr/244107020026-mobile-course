import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/task_service.dart';

import 'fakes/fake_task_repository.dart';

void main() {
  group('TaskService.loadTasks', () {
    test('meneruskan data dari repository', () async {
      final service = TaskService(
        FakeTaskRepository(tasks: ['Baca materi', 'Kerjakan latihan']),
      );

      final result = await service.loadTasks();

      expect(result, ['Baca materi', 'Kerjakan latihan']);
    });

    test('mengembalikan daftar kosong jika belum ada tugas', () async {
      final service = TaskService(FakeTaskRepository());

      final result = await service.loadTasks();

      expect(result, isEmpty);
    });

    test('meneruskan error tanpa mengubahnya menjadi daftar kosong', () async {
      final error = Exception('Gagal memuat tugas');
      final service = TaskService(FakeTaskRepository(error: error));

      final result = service.loadTasks();

      await expectLater(result, throwsA(same(error)));
    });
  });

  group('TaskService.addTask', () {
    test('meneruskan judul tugas ke repository', () async {
      final repository = FakeTaskRepository();
      final service = TaskService(repository);

      await service.addTask('Baca materi');

      expect(repository.addedTasks, ['Baca materi']);
    });

    test('meneruskan error penyimpanan tanpa mencatat tugas baru', () async {
      final error = Exception('Gagal menyimpan tugas');
      final repository = FakeTaskRepository(saveError: error);
      final service = TaskService(repository);

      final result = service.addTask('Baca materi');

      await expectLater(result, throwsA(same(error)));
      expect(repository.addedTasks, isEmpty);
    });
  });
}
