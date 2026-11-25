import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _key = TextEditingController();
  bool _saving = false;
  String _message = '';

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save({bool delete = false}) async {
    setState(() => _saving = true);
    try {
      final service = ref.read(aiServiceProvider);
      if (delete) {
        await service.deleteApiKey();
      } else {
        await service.saveApiKey(_key.text);
      }
      if (!mounted) return;
      _key.clear();
      setState(
        () => _message = delete ? 'API key dihapus.' : 'API key tersimpan.',
      );
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _message = 'Gagal menyimpan pengaturan. Isi API key yang valid.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(aiServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Masukkan API key Gemini. Kunci disimpan di secure storage perangkat dan tidak ditampilkan kembali.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'API key Gemini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Simpan'),
          ),
          TextButton(
            onPressed: _saving ? null : () => _save(delete: true),
            child: const Text('Hapus API key'),
          ),
          if (_saving) const LinearProgressIndicator(),
          Text(_message),
        ],
      ),
    );
  }
}
