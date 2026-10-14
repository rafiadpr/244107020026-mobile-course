import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/presentation/formatters/date_labels.dart';

// Halaman contoh lama hanya membutuhkan label tanggal, tanpa API/repository baru.
final announcementDateLabelProvider = Provider.autoDispose<String>((ref) {
  return publicationDateLabel(ref.watch(clockProvider)());
});
