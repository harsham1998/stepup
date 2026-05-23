import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  final data = await Supabase.instance.client
      .from('users')
      .select()
      .eq('id', userId)
      .single();
  return data;
});
