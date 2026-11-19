import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/memory_task_repository.dart';

void main() {
  test(
    'menyimpan tugas tanpa mengubah daftar hasil pembacaan sebelumnya',
    () async {
      final repository = MemoryTaskRepository();
      final initialTasks = await repository.getTasks();
      expect(initialTasks, isEmpty);

      await repository.addTask('Baca materi');
      await repository.addTask('Kerjakan latihan');
      final tasks = await repository.getTasks();

      expect(tasks, ['Baca materi', 'Kerjakan latihan']);
      expect(initialTasks, isEmpty);
      tasks.clear();
      expect(await repository.getTasks(), ['Baca materi', 'Kerjakan latihan']);
    },
  );
}
