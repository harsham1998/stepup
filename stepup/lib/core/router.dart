import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/challenges/screens/challenges_screen.dart';
import '../features/challenges/screens/challenge_detail_screen.dart';
import '../features/challenges/screens/custom_challenge_screen.dart';
import '../features/challenges/screens/invite_friends_screen.dart';
import '../features/challenges/screens/challenge_checkin_screen.dart';
import '../features/challenges/screens/consistency_calendar_screen.dart';
import '../features/challenges/screens/upgrade_prompt_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/league/screens/league_hub_screen.dart';
import '../features/league/screens/league_standings_screen.dart';
import '../features/coins/screens/coins_screen.dart';
import '../features/rewards/screens/rewards_screen.dart';
import '../features/battlepass/screens/battlepass_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/profile_edit_screen.dart';
import '../features/profile/screens/reputation_screen.dart';
import '../features/profile/screens/xp_level_screen.dart';
import '../features/profile/screens/achievements_screen.dart';
import '../features/subscriptions/screens/subscription_screen.dart';
import '../features/missions/screens/missions_screen.dart';
import '../features/rivals/screens/rivals_screen.dart';
import '../features/rivals/screens/battle_detail_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/community/screens/create_post_screen.dart';
import '../features/streaks/screens/streak_screen.dart';
import '../features/activities/screens/activities_screen.dart';
import '../features/activities/screens/log_session_screen.dart';
import '../features/activities/screens/stats_grid_screen.dart';
import '../features/activities/screens/activity_feed_screen.dart';
import '../features/activities/screens/workout_detail_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/devices/screens/devices_screen.dart';
import '../features/seasons/screens/season_rewards_screen.dart';
import '../features/water/screens/water_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('preview')) return null;
    }
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final isOnAuthRoute = state.matchedLocation == '/' ||
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/onboard';
    if (!isLoggedIn && !isOnAuthRoute) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/',        builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',   builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/onboard', builder: (_, __) => const OnboardingScreen()),
    ShellRoute(
      builder: (_, state, child) => AppShell(child: child, location: state.matchedLocation),
      routes: [
        GoRoute(path: '/home',           builder: (_, __) => const HomeScreen()),

        // Challenges
        GoRoute(path: '/challenges',     builder: (_, __) => const ChallengesScreen()),
        GoRoute(path: '/challenges/custom/new', builder: (_, __) => const CustomChallengeScreen()),
        GoRoute(path: '/challenges/custom/:code/invite', builder: (_, s) => InviteFriendsScreen(challengeId: s.pathParameters['code']!)),
        GoRoute(path: '/challenges/upgrade', builder: (_, __) => const UpgradePromptScreen()),
        GoRoute(path: '/challenges/:id', builder: (_, s) => ChallengeDetailScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/challenges/:id/checkin', builder: (_, s) => ChallengeCheckinScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/consistency', builder: (_, __) => const ConsistencyCalendarScreen()),

        // Leaderboard
        GoRoute(path: '/leaderboard',    builder: (_, __) => const LeaderboardScreen()),
        GoRoute(path: '/leaderboard/league', builder: (_, __) => const LeagueHubScreen()),
        GoRoute(path: '/leaderboard/standings', builder: (_, __) => const LeagueStandingsScreen()),

        // Coins
        GoRoute(path: '/coins',          builder: (_, __) => const CoinsScreen()),
        GoRoute(path: '/coins/rewards',  builder: (_, __) => const RewardsScreen()),
        GoRoute(path: '/coins/battlepass', builder: (_, __) => const BattlePassScreen()),

        // Profile
        GoRoute(path: '/profile',        builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/profile/edit',   builder: (_, __) => const ProfileEditScreen()),
        GoRoute(path: '/profile/subscription', builder: (_, __) => const SubscriptionScreen()),
        GoRoute(path: '/profile/reputation', builder: (_, __) => const ReputationScreen()),
        GoRoute(path: '/profile/xp',     builder: (_, __) => const XpLevelScreen()),
        GoRoute(path: '/profile/achievements', builder: (_, __) => const AchievementsScreen()),
        GoRoute(path: '/profile/devices', builder: (_, __) => const DevicesScreen()),

        // Other
        GoRoute(path: '/missions',       builder: (_, __) => const MissionsScreen()),
        GoRoute(path: '/water',          builder: (_, __) => const WaterScreen()),
        GoRoute(path: '/rivals',         builder: (_, __) => const RivalsScreen()),
        GoRoute(path: '/rivals/battle/:id', builder: (_, s) => BattleDetailScreen(battleId: s.pathParameters['id']!)),
        GoRoute(
          path: '/community',
          builder: (_, __) => const CommunityScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (_, __) => const CreatePostScreen(),
            ),
          ],
        ),
        GoRoute(path: '/streaks',        builder: (_, __) => const StreakScreen()),
        GoRoute(path: '/activities',     builder: (_, __) => const ActivitiesScreen()),
        GoRoute(path: '/activities/stats', builder: (_, __) => const StatsGridScreen()),
        GoRoute(path: '/activities/feed', builder: (_, __) => const ActivityFeedScreen()),
        GoRoute(path: '/activities/workout', builder: (_, __) => const WorkoutDetailScreen()),
        GoRoute(path: '/activities/log', builder: (_, s) => LogSessionScreen(initialType: s.uri.queryParameters['type'])),
        GoRoute(path: '/notifications',  builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/season-rewards', builder: (_, __) => const SeasonRewardsScreen()),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({required this.child, required this.location, super.key});

  int get _index {
    if (location.startsWith('/challenges')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          const routes = ['/home', '/challenges', '/leaderboard', '/community', '/profile'];
          context.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Chal'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Lead'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Me'),
        ],
      ),
    );
  }
}
