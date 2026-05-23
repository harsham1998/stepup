import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/challenges/screens/challenges_screen.dart';
import '../features/challenges/screens/challenge_detail_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final isOnAuthRoute = state.matchedLocation == '/' ||
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/onboard';
    if (!isLoggedIn && !isOnAuthRoute) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/',        builder: (context, _) => const SplashScreen()),
    GoRoute(path: '/login',   builder: (context, _) => const LoginScreen()),
    GoRoute(path: '/onboard', builder: (context, _) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home',        builder: (context, _) => const HomeScreen()),
        GoRoute(path: '/challenges',  builder: (context, _) => const ChallengesScreen()),
        GoRoute(
          path: '/challenges/:id',
          builder: (_, state) => ChallengeDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(path: '/leaderboard', builder: (context, _) => const LeaderboardScreen()),
        GoRoute(path: '/wallet',      builder: (context, _) => const WalletScreen()),
        GoRoute(path: '/profile',     builder: (context, _) => const ProfileScreen()),
      ],
    ),
  ],
);

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _tabs = ['/home', '/challenges', '/leaderboard', '/wallet', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_martial_arts), label: 'Battle'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Rank'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Me'),
        ],
      ),
    );
  }
}
