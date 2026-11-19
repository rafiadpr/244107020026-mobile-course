import 'package:flutter/material.dart';

import 'is_valid_task_title.dart';
import 'task_service.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.service});

  final TaskService service;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  List<String> _tasks = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final tasks = await widget.service.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Tugas gagal dimuat. Tekan Coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.service.addTask(title);
      if (!mounted) return;
      setState(() {
        _tasks = [..._tasks, title];
        _titleController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError =
            'Tugas gagal disimpan. Tekan Simpan tugas untuk mencoba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat tugas'),
      );
    } else if (_loadError != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadTasks, child: const Text('Coba lagi')),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                key: const Key('task-title-field'),
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Judul tugas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => isValidTaskTitle(value ?? '')
                    ? null
                    : 'Judul tugas wajib diisi.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-task-button'),
              onPressed: _isSaving ? null : _saveTask,
              child: Text(_isSaving ? 'Menyimpan...' : 'Simpan tugas'),
            ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(liveRegion: true, child: Text(_saveError!)),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada tugas. Isi judul lalu tekan Simpan tugas.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) =>
                          ListTile(title: Text(_tasks[index])),
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar tugas')),
      body: SafeArea(child: body),
    );
  }
}
