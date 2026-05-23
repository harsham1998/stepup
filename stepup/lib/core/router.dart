import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Stubs — replaced by real screens in Tasks 5-7
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Splash')));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login')));
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding')));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home')));
}

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Battles')));
}

class ChallengeDetailScreen extends StatelessWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Challenge $id')));
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Rankings')));
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Wallet')));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile')));
}

final router = GoRouter(
  initialLocation: '/',
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
