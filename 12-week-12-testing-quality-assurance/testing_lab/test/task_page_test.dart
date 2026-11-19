import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/main.dart';
import 'package:testing_lab/task_service.dart';

import 'fakes/fake_task_repository.dart';

class PendingTaskRepository extends FakeTaskRepository {
  final loadCompleter = Completer<List<String>>();
  final saveCompleter = Completer<void>();

  @override
  Future<List<String>> getTasks() => loadCompleter.future;

  @override
  Future<void> addTask(String title) async {
    await saveCompleter.future;
    await super.addTask(title);
  }
}

void main() {
  const emptyMessage = 'Belum ada tugas. Isi judul lalu tekan Simpan tugas.';
  final titleField = find.byKey(const Key('task-title-field'));
  final saveButton = find.byKey(const Key('save-task-button'));

  group('Halaman daftar tugas', () {
    testWidgets('menampilkan judul, form, dan pesan daftar kosong', (
      tester,
    ) async {
      final repository = FakeTaskRepository();
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      expect(find.text('Daftar tugas'), findsOneWidget);
      expect(find.text('Judul tugas'), findsOneWidget);
      expect(titleField, findsOneWidget);
      expect(find.text('Simpan tugas'), findsOneWidget);
      expect(find.text(emptyMessage), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('menampilkan data tugas dari repository', (tester) async {
      final repository = FakeTaskRepository(
        tasks: ['Baca materi', 'Kerjakan latihan'],
      );
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Kerjakan latihan'), findsOneWidget);
      expect(find.text(emptyMessage), findsNothing);
    });

    testWidgets('menolak judul kosong dan hanya spasi', (tester) async {
      final repository = FakeTaskRepository();
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
      expect(repository.addedTasks, isEmpty);

      await tester.enterText(titleField, '   ');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(repository.addedTasks, isEmpty);
    });

    testWidgets('menyimpan judul dan membersihkan kolom input', (tester) async {
      final repository = FakeTaskRepository(tasks: ['Kerjakan latihan']);
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      await tester.enterText(titleField, '  Baca materi  ');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Kerjakan latihan'), findsOneWidget);
      expect(repository.addedTasks, ['Baca materi']);
      expect(
        tester.widget<TextFormField>(titleField).controller!.text,
        isEmpty,
      );
      expect(find.text(emptyMessage), findsNothing);
    });

    testWidgets(
      'regresi: input kosong setelah menyimpan tidak menambah tugas',
      (tester) async {
        final repository = FakeTaskRepository();
        await tester.pumpWidget(MyApp(service: TaskService(repository)));
        await tester.pumpAndSettle();

        await tester.enterText(titleField, 'Baca materi');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(
          tester.widget<TextFormField>(titleField).controller!.text,
          isEmpty,
        );
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
        expect(repository.addedTasks, ['Baca materi']);

        await tester.enterText(titleField, '   ');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
        expect(repository.addedTasks, ['Baca materi']);
        expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      },
    );

    testWidgets('menampilkan loading dan mencegah penyimpanan ganda', (
      tester,
    ) async {
      final repository = PendingTaskRepository();
      await tester.pumpWidget(MyApp(service: TaskService(repository)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(titleField, findsNothing);

      repository.loadCompleter.complete([]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.enterText(titleField, 'Baca materi');
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Menyimpan...'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      expect(tester.widget<TextFormField>(titleField).enabled, isFalse);
      expect(find.byType(ListTile), findsNothing);

      await tester.tap(saveButton);
      repository.saveCompleter.complete();
      await tester.pumpAndSettle();

      expect(repository.addedTasks, ['Baca materi']);
      expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });

    testWidgets('menampilkan kegagalan memuat tugas dan bisa mencoba lagi', (
      tester,
    ) async {
      final repository = FakeTaskRepository(
        tasks: ['Baca materi'],
        error: Exception('Gagal memuat tugas'),
      );
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      expect(find.text('Tugas gagal dimuat. Tekan Coba lagi.'), findsOneWidget);
      expect(find.text(emptyMessage), findsNothing);
      expect(titleField, findsNothing);

      repository.error = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
      expect(titleField, findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('mempertahankan input saat gagal menyimpan dan bisa diulang', (
      tester,
    ) async {
      final repository = FakeTaskRepository(
        saveError: Exception('Gagal menyimpan tugas'),
      );
      await tester.pumpWidget(MyApp(service: TaskService(repository)));
      await tester.pumpAndSettle();

      await tester.enterText(titleField, 'Baca materi');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tugas gagal disimpan. Tekan Simpan tugas untuk mencoba lagi.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(titleField).controller!.text,
        'Baca materi',
      );
      expect(find.byType(ListTile), findsNothing);
      expect(repository.addedTasks, isEmpty);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

      repository.saveError = null;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
      expect(repository.addedTasks, ['Baca materi']);
      expect(
        tester.widget<TextFormField>(titleField).controller!.text,
        isEmpty,
      );
      expect(
        find.text(
          'Tugas gagal disimpan. Tekan Simpan tugas untuk mencoba lagi.',
        ),
        findsNothing,
      );
    });
  });
}
