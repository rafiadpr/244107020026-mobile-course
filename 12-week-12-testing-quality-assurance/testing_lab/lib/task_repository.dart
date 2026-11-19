abstract interface class TaskRepository {
  Future<List<String>> getTasks();
}
