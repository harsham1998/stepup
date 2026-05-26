import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _tab = 0; // 0=All, 1=Challenges, 2=Friends, 3=Coins

  static const _tabs = ['All', 'Challenges', 'Friends', 'Coins'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header: "Activity" + "Mark all read"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activity', style: AppTheme.bigNum(28)),
                  GestureDetector(
                    onTap: () {},
                    child: Text('Mark all read',
                        style: AppTheme.label(12, color: AppTheme.ink2)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter chips
              Row(children: List.generate(_tabs.length, (i) {
                final active = _tab == i;
                return GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.voltLime : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppTheme.voltLime : AppTheme.border,
                      ),
                    ),
                    child: Text(_tabs[i],
                        style: AppTheme.label(12).copyWith(
                          color: active ? AppTheme.bg : AppTheme.ink2,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                );
              })),
            ]),
          ),
          Expanded(
            child: ref.watch(notificationsProvider).when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => const _MockNotifList(),
              data: (list) => list.isEmpty
                  ? const _MockNotifList()
                  : _NotifList(notifications: list, tab: _tab),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final int tab;
  const _NotifList({required this.notifications, required this.tab});

  @override
  Widget build(BuildContext context) {
    final filtered = tab == 0
        ? notifications
        : notifications.where((n) {
            final type = n['type'] as String? ?? '';
            final tabType = ['all', 'challenge', 'friend', 'coin'][tab];
            return type.contains(tabType);
          }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final n = filtered[i];
        final read = n['read'] as bool? ?? false;
        final title = n['title'] as String? ?? '';
        final body = n['body'] as String? ?? '';
        final createdAt = n['created_at'] as String? ?? '';
        return _NotifRow(
          title: title,
          body: body,
          time: _fmtTime(createdAt),
          isUnread: !read,
          coinAmount: null,
        );
      },
    );
  }

  static String _fmtTime(String s) {
    try {
      final d = DateTime.parse(s);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yest.';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recently';
    }
  }
}

class _NotifRow extends StatelessWidget {
  final String title, body, time;
  final bool isUnread;
  final String? coinAmount;
  final IconData? icon;
  const _NotifRow({
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    this.coinAmount,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ic = icon ?? Icons.notifications_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUnread
            ? AppTheme.voltLime.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isUnread
                ? AppTheme.voltLime.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ic,
              size: 18,
              color: isUnread ? AppTheme.voltLime : AppTheme.ink2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: AppTheme.label(13, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(time, style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        if (coinAmount != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
            ),
            child: Text(coinAmount!,
                style: AppTheme.label(11, color: AppTheme.amber)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
    );
  }
}

class _MockNotifList extends StatelessWidget {
  const _MockNotifList();

  static const _items = [
    ['You finished "10k Steps" — top 50%!', 'Just now', '+150 ¢', true, Icons.emoji_events_rounded],
    ['You hit a 12-day streak!', '1h ago', '+20 ¢', true, Icons.local_fire_department_rounded],
    ['Time to log your gym session', '3h ago', null, false, Icons.fitness_center_rounded],
    ['Priya joined "7-day Gym Consistency"', 'Yest.', null, false, Icons.person_rounded],
    ['Aarav passed you on the leaderboard', 'Yest.', null, false, Icons.bar_chart_rounded],
    ['500 coins added — referred Megha', '2d ago', '+500 ¢', false, Icons.monetization_on_rounded],
    ['New gift card: Cult.fit ₹250 added', '3d ago', null, false, Icons.card_giftcard_rounded],
  ];

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _NotifRow(
            title: item[0] as String,
            body: '',
            time: item[1] as String,
            coinAmount: item[2] as String?,
            isUnread: item[3] as bool,
            icon: item[4] as IconData,
          );
        },
      );
}
