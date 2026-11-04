import 'dart:convert';
import 'dart:io';

import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/ai/offline_faq.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String responseText(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
      'finishReason': 'STOP',
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key'});
  });

  AiService serviceWithStatus(int status) => AiService(
    client: MockClient(
      (_) async => http.Response(status == 200 ? '{}' : 'error', status),
    ),
  );

  test('API key disimpan, dihapus, dan tidak muncul di URL', () async {
    final service = AiService(
      client: MockClient((request) async {
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        expect(request.headers['x-goog-api-key'], 'new-key');
        return http.Response('data: ${responseText('Jawaban')}\n\n', 200);
      }),
    );
    addTearDown(service.close);
    await service.saveApiKey(' new-key ');
    expect(await service.ask('Notifikasi?'), 'Jawaban');
    await service.deleteApiKey();
    await expectLater(service.ask('Pengumuman?'), throwsA(isA<AiException>()));
  });

  test('API key kosong tidak disimpan', () async {
    final service = serviceWithStatus(200);
    addTearDown(service.close);
    await expectLater(service.saveApiKey('  '), throwsA(isA<AiException>()));
  });

  test('Streaming menggabungkan potongan dan mengirim prompt sistem', () async {
    final service = AiService(
      client: MockClient((request) async {
        expect(request.url.path, contains(':streamGenerateContent'));
        expect(request.url.queryParameters['alt'], 'sse');
        final body = jsonDecode(request.body);
        expect(
          body['systemInstruction']['parts'][0]['text'],
          AiService.systemPrompt,
        );
        expect(body['contents'][0]['parts'][0]['text'], 'Pengumuman?');
        return http.Response(
          ': heartbeat\n\ndata: ${responseText('Buka ')}\n\n'
          'data: ${responseText('pengumuman.')}\n\ndata: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.close);
    expect(await service.askStream(' Pengumuman? ').toList(), [
      'Buka ',
      'pengumuman.',
    ]);
  });

  test('Query berulang memakai cache tanpa request baru', () async {
    var calls = 0;
    final service = AiService(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          'data: ${responseText('Buka pengumuman.')}\n\n',
          200,
        );
      }),
    );
    addTearDown(service.close);
    await service.ask('Pengumuman?');
    await service.ask(' Pengumuman? ');
    expect(calls, 1);
  });

  test('Batas sesi menolak request ke-21 sebelum menghubungi API', () async {
    var calls = 0;
    final service = AiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('data: ${responseText('Jawaban')}\n\n', 200);
      }),
    );
    addTearDown(service.close);
    for (var i = 0; i < 20; i++) {
      await service.ask('Pertanyaan $i');
    }
    await expectLater(
      service.ask('Pertanyaan lain'),
      throwsA(isA<AiException>()),
    );
    expect(calls, 20);
  });

  test('Pertanyaan sensitif ditolak sebelum menghubungi API', () async {
    var calls = 0;
    final service = AiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    addTearDown(service.close);
    for (final question in [
      'NIK 1234567890123456',
      'Telepon 081234567890',
      'Email andre@example.com',
    ]) {
      await expectLater(service.ask(question), throwsA(isA<AiException>()));
    }
    expect(calls, 0);
  });

  test('Input kosong dan terlalu panjang ditolak', () {
    for (final question in ['', '   ', 'a' * 1001]) {
      expect(
        () => AiService.validateQuestion(question),
        throwsA(isA<AiException>()),
      );
    }
  });

  for (final status in [400, 403, 404, 429, 500]) {
    test('Status $status memberikan pesan ramah', () async {
      final service = serviceWithStatus(status);
      addTearDown(service.close);
      await expectLater(
        service.ask('Pengumuman?'),
        throwsA(
          isA<AiException>().having(
            (error) => error.message,
            'status HTTP',
            contains('HTTP $status'),
          ),
        ),
      );
    });
  }

  test('Respons kosong ditolak dan tidak masuk cache', () async {
    final service = serviceWithStatus(200);
    addTearDown(service.close);
    await expectLater(service.ask('Pengumuman?'), throwsA(isA<AiException>()));
  });

  test('Respons terpotong ditolak', () async {
    final service = AiService(
      client: MockClient(
        (_) async => http.Response(
          'data: {"candidates":[{"finishReason":"MAX_TOKENS"}]}\n\n',
          200,
        ),
      ),
    );
    addTearDown(service.close);
    await expectLater(service.ask('Pengumuman?'), throwsA(isA<AiException>()));
  });

  test('Respons yang diblokir tidak ditampilkan', () async {
    final service = AiService(
      client: MockClient(
        (_) async => http.Response(
          'data: {"candidates":[{"finishReason":"SAFETY"}]}\n\n',
          200,
        ),
      ),
    );
    addTearDown(service.close);
    await expectLater(service.ask('Pengumuman?'), throwsA(isA<AiException>()));
  });

  test(
    'OCR, deskripsi, dan transkripsi mengirim MIME serta data file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'campus_ai_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/sample');
      await file.writeAsBytes([1, 2, 3]);
      final prompts = <String>[];
      final types = <String>[];
      final service = AiService(
        client: MockClient((request) async {
          expect(request.url.path, contains(':generateContent'));
          final parts = jsonDecode(request.body)['contents'][0]['parts'];
          prompts.add(parts[0]['text'] as String);
          types.add(parts[1]['inline_data']['mime_type'] as String);
          expect(parts[1]['inline_data']['data'], base64Encode([1, 2, 3]));
          return http.Response(responseText('Hasil'), 200);
        }),
      );
      addTearDown(service.close);
      expect(await service.recognizeText(file, 'image/png'), 'Hasil');
      expect(await service.describeImage(file, 'image/jpeg'), 'Hasil');
      expect(await service.speechToText(file), 'Hasil');
      expect(types, ['image/png', 'image/jpeg', 'audio/wav']);
      expect(prompts[0], contains('Salin semua teks'));
      expect(prompts[1], contains('Jelaskan isi gambar'));
      expect(prompts[2], contains('Transkripsikan'));
    },
  );

  test('File lebih dari 5 MB ditolak tanpa request', () async {
    final directory = await Directory.systemTemp.createTemp('campus_ai_large_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/large');
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(5 * 1024 * 1024 + 1);
    await handle.close();
    var called = false;
    final service = AiService(
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.recognizeText(file, 'image/png'),
      throwsA(isA<AiException>()),
    );
    expect(called, isFalse);
  });

  test('FAQ offline mencari kata kunci dan memiliki jawaban cadangan', () {
    expect(offlineAnswer('Bagaimana NOTIFIKASI?'), contains('izin notifikasi'));
    expect(offlineAnswer('Jadwal kuliah?'), contains('bagian akademik'));
    expect(offlineAnswer('Pertanyaan lain'), contains('belum tersedia'));
  });
}
