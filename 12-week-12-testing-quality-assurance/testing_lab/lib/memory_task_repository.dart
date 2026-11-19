import 'task_repository.dart';

class MemoryTaskRepository implements TaskRepository {
  // shortcut: data hilang saat aplikasi ditutup, gunakan penyimpanan lokal jika perlu disimpan permanen.
  final List<String> _tasks = [];

  @override
  Future<List<String>> getTasks() async {
    return List.of(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    _tasks.add(title);
  }
}
