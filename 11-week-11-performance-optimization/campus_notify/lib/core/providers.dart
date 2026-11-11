import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/datasources/token_store.dart';

// Dependency lintas fitur. Wiring repository/use case auth berada di fitur auth.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
