import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/theme.dart';

class StepUpApp extends ConsumerStatefulWidget {
  const StepUpApp({super.key});

  @override
  ConsumerState<StepUpApp> createState() => _StepUpAppState();
}

class _StepUpAppState extends ConsumerState<StepUpApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Navigate to home after any sign-in (OTP, Google, etc.)
        router.go('/home');
      } else if (event == AuthChangeEvent.signedOut) {
        router.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StepUp',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.15),
        ),
        child: child!,
      ),
    );
  }
}
