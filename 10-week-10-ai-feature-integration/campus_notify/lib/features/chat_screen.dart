import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';
import '../ai/offline_faq.dart';
import 'ai_settings_screen.dart';
import 'media_screen.dart';

class ChatMessage {
  ChatMessage(this.text, {this.isUser = false});
  String text;
  final bool isUser;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _loading = false;
  bool _offline = false;
  String? _error;
  String _lastQuestion = '';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send({String? retry}) async {
    final question = (retry ?? _input.text).trim();
    if (_loading || question.isEmpty) return;
    try {
      AiService.validateQuestion(question);
    } on AiException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    final reply = ChatMessage('');
    setState(() {
      _messages.addAll([ChatMessage(question, isUser: true), reply]);
      _loading = true;
      _error = null;
      _lastQuestion = question;
    });
    _input.clear();
    _scrollDown();
    try {
      if (_offline) {
        reply.text = 'FAQ offline: ${offlineAnswer(question)}';
      } else {
        await for (final chunk
            in ref.read(aiServiceProvider).askStream(question)) {
          if (!mounted) return;
          setState(() => reply.text += chunk);
          _scrollDown();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AiException
            ? e.message
            : e is TimeoutException
            ? 'Koneksi terlalu lama. Coba lagi nanti.'
            : 'Tidak dapat terhubung ke AI. Coba lagi atau gunakan FAQ offline.';
        reply.text = _error!;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollDown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(aiServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus'),
        actions: [
          IconButton(
            tooltip: 'OCR, suara, dan gambar',
            icon: const Icon(Icons.perm_media),
            onPressed: _loading
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const MediaScreen(),
                    ),
                  ),
          ),
          IconButton(
            tooltip: 'Pengaturan AI',
            icon: const Icon(Icons.settings),
            onPressed: _loading
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AiSettingsScreen(),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Pertanyaan dikirim ke Google Gemini. Jangan kirim NIK, nomor telepon, alamat, atau data pribadi. Jawaban AI dapat keliru.',
              ),
            ),
            SwitchListTile(
              title: const Text('FAQ offline'),
              subtitle: const Text('Jawaban lokal tanpa mengirim data ke AI'),
              value: _offline,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _offline = value),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Tanyakan tentang pengumuman atau notifikasi.',
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _bubble(_messages[index]),
                    ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_lastQuestion.isNotEmpty)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _send(retry: _lastQuestion),
                            child: const Text('Coba lagi'),
                          ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() => _offline = true);
                                  if (_lastQuestion.isNotEmpty) {
                                    _send(retry: _lastQuestion);
                                  }
                                },
                          child: const Text('Gunakan FAQ offline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_loading,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Pertanyaan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kirim',
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage message) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: message.isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message.text.isEmpty ? 'Menunggu jawaban...' : message.text),
    ),
  );
}
