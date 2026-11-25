import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/format.dart';

void main() {
  test('Tanggal publikasi mempertahankan format lama', () {
    expect(
      publicationDateLabel(DateTime(2026, 10, 15)),
      'Dipublikasikan: 15/10/2026',
    );
  });
  test('Timestamp lokal mempertahankan representasi lama', () {
    final local = DateTime(2026, 10, 15, 1, 2, 3);
    expect(localTimestampLabel(local), '2026-10-15 01:02:03.000');
  });
  test('Payload kosong dan whitespace memakai fallback', () {
    expect(routeFromMessage(null), '/');
    expect(routeFromMessage({}), '/');
    expect(routeFromMessage({'route': '   ', 'id': '  '}), '/');
  });
  test('Route eksplisit prioritas atas ID dan dipangkas', () {
    expect(
      routeFromMessage({'route': ' pengumuman/3 ', 'id': '42'}),
      '/pengumuman/3',
    );
    expect(routeFromMessage({'route': '/announcement/42'}), '/announcement/42');
  });
  test('ID numerik dan route kosong mempertahankan helper lama', () {
    expect(routeFromMessage({'route': '', 'id': 42}), '/pengumuman/42');
    expect(AppRoutes.announcementDetail('3'), '/pengumuman/3');
  });
}
