import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<void> sendOtp(String phone) async {
    await ApiClient.instance.post('/auth/otp/send', {'phone': phone});
  }

  /// Returns a map with:
  ///   isNewUser            – true if no users row exists yet
  ///   onboardingCompleted  – true if the user has finished onboarding
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await ApiClient.instance.post(
      '/auth/otp/verify',
      {'phone': phone, 'otp': otp},
    ) as Map<String, dynamic>;

    final session = response['session'] as Map<String, dynamic>;
    await _supabase.auth.setSession(
      session['refresh_token'] as String,
      accessToken: session['access_token'] as String,
    );

    return {
      'isNewUser': response['isNewUser'] as bool? ?? true,
      'onboardingCompleted': response['onboardingCompleted'] as bool? ?? false,
    };
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  /// Onboarding save — creates the users row on first call.
  Future<void> saveProfile({
    required String name,
    String city = '',
    required String language,
    required String goalTier,
  }) async {
    await ApiClient.instance.put('/auth/profile', {
      'name': name,
      'city': city,
      'language': language,
      'goal_tier': goalTier,
      'onboarding_completed': true,
    });
  }

  /// Profile edit screen save — partial update, all fields optional.
  Future<void> saveFullProfile(Map<String, dynamic> fields) async {
    await ApiClient.instance.patch('/auth/profile', fields);
  }

  bool get isLoggedIn => _supabase.auth.currentSession != null;
  Future<void> signOut() async => _supabase.auth.signOut();
}
