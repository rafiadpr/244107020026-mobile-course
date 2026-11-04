import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../ai/ai_service.dart';

class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key});

  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  File? _audio;
  File? _image;
  String _mimeType = 'image/jpeg';
  bool _recording = false;
  bool _busy = false;
  String _result = '';
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    final audio = _audio;
    unawaited(
      _recorder.dispose().then((_) async {
        if (audio != null && await audio.exists()) await audio.delete();
      }),
    );
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;
      final extension = picked.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        throw const AiException('Gunakan gambar JPG, PNG, atau WebP.');
      }
      setState(() {
        _image = File(picked.path);
        _mimeType = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
        _result = '';
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AiException
              ? e.message
              : 'Gambar tidak dapat dibuka. Periksa izin kamera atau galeri.',
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_recording) {
        _timer?.cancel();
        await _recorder.stop();
        if (mounted) setState(() => _recording = false);
        return;
      }
      if (!await _recorder.hasPermission()) {
        throw const AiException('Izin mikrofon belum diberikan.');
      }
      final directory = await getTemporaryDirectory();
      final previous = _audio;
      if (previous != null && await previous.exists()) await previous.delete();
      final file = File(
        '${directory.path}/campus_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      _audio = file;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: file.path,
      );
      if (!mounted) {
        await _recorder.stop();
        if (await file.exists()) await file.delete();
        return;
      }
      setState(() {
        _recording = true;
        _error = null;
        _result = '';
      });
      _timer = Timer(const Duration(seconds: 15), () => _toggleRecording());
    } catch (e) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = e is AiException
              ? e.message
              : 'Rekaman gagal. Periksa izin mikrofon.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _process(String task) async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim ke Gemini?'),
        content: const Text(
          'File akan dikirim ke Google untuk diproses. Pastikan file tidak berisi identitas, wajah pribadi, alamat, atau percakapan rahasia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (allowed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = '';
    });
    try {
      final service = ref.read(aiServiceProvider);
      final result = switch (task) {
        'ocr' => await service.recognizeText(_image!, _mimeType),
        'image' => await service.describeImage(_image!, _mimeType),
        _ => await service.speechToText(_audio!),
      };
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AiException ? e.message : 'File gagal diproses. Coba lagi nanti. Input teks tetap tersedia di chat.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(aiServiceProvider);
    final disabled = _busy || _recording;
    return Scaffold(
      appBar: AppBar(title: const Text('OCR, Suara, dan Gambar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pilih foto papan pengumuman atau benda tanpa data pribadi. Ukuran file maksimal 5 MB.',
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: disabled
                    ? null
                    : () => _pickImage(ImageSource.camera),
                child: const Text('Kamera'),
              ),
              OutlinedButton(
                onPressed: disabled
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                child: const Text('Galeri'),
              ),
            ],
          ),
          if (_image != null)
            Image.file(_image!, height: 180, fit: BoxFit.contain),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: disabled || _image == null
                    ? null
                    : () => _process('ocr'),
                child: const Text('Baca teks (OCR)'),
              ),
              FilledButton(
                onPressed: disabled || _image == null
                    ? null
                    : () => _process('image'),
                child: const Text('Deskripsikan gambar'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Rekam ucapan singkat, maksimal 15 detik. Rekaman baru dikirim setelah menekan Transkripsikan dan menyetujui pengiriman.',
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _toggleRecording,
            icon: Icon(_recording ? Icons.stop : Icons.mic),
            label: Text(_recording ? 'Hentikan rekaman' : 'Rekam suara'),
          ),
          if (_recording) const Text('Sedang merekam...'),
          FilledButton(
            onPressed: disabled || _audio == null
                ? null
                : () => _process('audio'),
            child: const Text('Transkripsikan'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          SelectableText(
            _result.isEmpty ? 'Hasil akan tampil di sini.' : _result,
          ),
        ],
      ),
    );
  }
}
