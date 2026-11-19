import 'task_repository.dart';

class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }
}
