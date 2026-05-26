import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api_client.dart';

// ── Profile summary (all data the profile screen needs in one call) ───────────

final profileSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final data = await ApiClient.instance.get('/auth/profile/summary');
    return (data as Map<String, dynamic>?) ?? {};
  } catch (_) {
    return {};
  }
});

// Full editable profile for the edit screen (includes phone + email from auth).
// Falls back to summary data when the edit endpoint is unavailable so the form
// loads immediately from cache instead of spinning until timeout.
final editProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final data = await ApiClient.instance.get('/auth/profile/edit');
    return (data as Map<String, dynamic>?) ?? {};
  } catch (_) {
    return await ref.read(profileSummaryProvider.future);
  }
});

// Keep for screens that still call /auth/profile directly
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final data = await ApiClient.instance.get('/auth/profile');
    return (data as Map<String, dynamic>?) ?? {};
  } catch (_) {
    return {};
  }
});

// ── Avatar upload ─────────────────────────────────────────────────────────────

class AvatarState {
  final String? url;
  final bool isUploading;
  final String? error;

  const AvatarState({this.url, this.isUploading = false, this.error});

  AvatarState copyWith({String? url, bool? isUploading, String? error}) =>
      AvatarState(
        url: url ?? this.url,
        isUploading: isUploading ?? this.isUploading,
        error: error,
      );
}

class AvatarUploadNotifier extends Notifier<AvatarState> {
  @override
  AvatarState build() => const AvatarState();

  /// Seed the URL from the profile summary. Safe to call multiple times —
  /// once a URL is set (either from DB or a fresh upload) it won't be
  /// overwritten by an older DB value.
  void seedUrl(String? url) {
    if (url != null && state.url == null) {
      state = AvatarState(url: url);
    }
  }

  Future<void> pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    state = state.copyWith(isUploading: true, error: null);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final bytes = await file.readAsBytes();
      final ext = file.path.contains('.')
          ? file.path.split('.').last.toLowerCase()
          : 'jpg';
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      // Always store as avatar.jpg / avatar.png so the path is stable and
      // we don't accumulate orphaned files in storage.
      final storagePath = '$userId/avatar.$ext';

      try {
        await supabase.storage.createBucket(
          'avatars',
          const BucketOptions(public: true, fileSizeLimit: '5MB'),
        );
      } catch (_) {
        // Bucket already exists
      }

      await supabase.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);

      // Save clean URL to DB via API (upsert so it works even before onboarding row exists)
      await ApiClient.instance.patch('/auth/profile/avatar', {'avatar_url': publicUrl});

      // Cache-bust only in memory so the image widget reloads the new photo
      final bust = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      state = AvatarState(url: bust, isUploading: false);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed · ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}

final avatarUploadProvider =
    NotifierProvider<AvatarUploadNotifier, AvatarState>(AvatarUploadNotifier.new);
