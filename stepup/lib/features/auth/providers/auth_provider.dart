import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_service.dart';

final authServiceProvider = Provider((_) => AuthService());

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn;
});
