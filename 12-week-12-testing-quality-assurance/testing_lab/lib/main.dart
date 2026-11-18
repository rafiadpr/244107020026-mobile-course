import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Lab',
      home: Scaffold(
        appBar: AppBar(title: const Text('Daftar tugas')),
        body: const Center(child: Text('Belum ada tugas')),
      ),
    );
  }
}
