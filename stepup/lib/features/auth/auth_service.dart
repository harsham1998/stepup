import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<void> sendOtp(String phone) async {
    await ApiClient.instance.post('/auth/otp/send', {'phone': phone});
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final response = await ApiClient.instance.post(
      '/auth/otp/verify',
      {'phone': phone, 'otp': otp},
    ) as Map<String, dynamic>;
    final session = response['session'] as Map<String, dynamic>;
    await _supabase.auth.setSession(
      session['refresh_token'] as String,
      accessToken: session['access_token'] as String,
    );
    return response['isNewUser'] as bool? ?? true;
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> saveProfile({
    required String name,
    required String city,
    required String language,
    required String goalTier,
  }) async {
    await ApiClient.instance.put('/auth/profile', {
      'name': name,
      'city': city,
      'language': language,
      'goal_tier': goalTier,
    });
  }

  bool get isLoggedIn => _supabase.auth.currentSession != null;
  Future<void> signOut() async => _supabase.auth.signOut();
}
