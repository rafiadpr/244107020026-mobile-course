import 'package:testing_lab/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.tasks = const [], this.error, this.saveError});

  final List<String> tasks;
  Exception? error;
  Exception? saveError;
  final List<String> addedTasks = [];

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return tasks;
  }

  @override
  Future<void> addTask(String title) async {
    if (saveError != null) throw saveError!;
    addedTasks.add(title);
  }
}
