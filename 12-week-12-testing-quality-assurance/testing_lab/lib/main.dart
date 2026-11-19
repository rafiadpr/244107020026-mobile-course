import 'package:flutter/material.dart';

import 'memory_task_repository.dart';
import 'task_page.dart';
import 'task_service.dart';

void main() {
  runApp(MyApp(service: TaskService(MemoryTaskRepository())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.service});

  final TaskService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Lab',
      home: TaskPage(service: service),
    );
  }
}
