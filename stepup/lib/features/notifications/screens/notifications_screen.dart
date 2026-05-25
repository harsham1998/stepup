import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(data as List);
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('Notifications', style: AppTheme.bigNum(24)),
            ]),
          ),
          TabBar(
            controller: _tab,
            labelColor: AppTheme.bg,
            unselectedLabelColor: AppTheme.ink3,
            labelStyle: AppTheme.label(11)
                .copyWith(fontWeight: FontWeight.w700),
            indicator: BoxDecoration(
              color: AppTheme.voltLime,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Challenges'),
              Tab(text: 'Friends'),
              Tab(text: 'Coins'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ref.watch(notificationsProvider).when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => _MockNotificationsList(),
              data: (list) => list.isEmpty
                  ? _MockNotificationsList()
                  : _NotificationsList(notifications: list),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  const _NotificationsList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.06), height: 1),
      itemBuilder: (_, i) {
        final n = notifications[i];
        final read = n['read'] as bool? ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: read
              ? Colors.transparent
              : AppTheme.voltLime.withValues(alpha: 0.03),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: AppTheme.ink2, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['title'] as String,
                      style: AppTheme.label(13, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(n['body'] as String,
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                ],
              ),
            ),
            if (!read)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppTheme.voltLime, shape: BoxShape.circle),
              ),
          ]),
        );
      },
    );
  }
}

class _MockNotificationsList extends StatelessWidget {
  static const _items = [
    ['Challenge started!', 'Your "7-Day Gym Consistency" starts tomorrow.', true, Icons.emoji_events_rounded, false],
    ['Goal achieved 🎉', 'You hit 10,000 steps today. Keep it up!', true, Icons.directions_walk_rounded, false],
    ['Coin reward', 'You earned +200¢ for finishing top 50%.', false, Icons.monetization_on_rounded, true],
    ['Friend joined', 'Priya S joined your "Sunrise Squad" challenge.', true, Icons.person_rounded, false],
    ['Streak alert 🔥', 'Don\'t break your 12-day streak today!', true, Icons.local_fire_department_rounded, true],
    ['New rival match', 'You\'ve been matched with Aarav M for a weekly battle.', false, Icons.sports_mma_rounded, false],
    ['Mission complete', 'Walk 8,000 steps mission done · +15¢ added.', false, Icons.check_circle_rounded, false],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.06), height: 1),
      itemBuilder: (_, i) {
        final item = _items[i];
        final isCoins = item[3] == Icons.monetization_on_rounded;
        final unread = item[4] as bool;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: unread
              ? AppTheme.voltLime.withValues(alpha: 0.03)
              : Colors.transparent,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCoins
                    ? AppTheme.amber.withValues(alpha: 0.12)
                    : AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isCoins
                        ? AppTheme.amber.withValues(alpha: 0.3)
                        : AppTheme.border),
              ),
              child: Icon(item[3] as IconData,
                  color: isCoins ? AppTheme.amber : AppTheme.ink2, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item[0] as String,
                      style: AppTheme.label(13, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item[1] as String,
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppTheme.voltLime, shape: BoxShape.circle),
              ),
          ]),
        );
      },
    );
  }
}
