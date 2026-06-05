import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_search_result.dart';
import '../providers/friends_provider.dart';

class FriendsHubScreen extends ConsumerStatefulWidget {
  const FriendsHubScreen({super.key});

  @override
  ConsumerState<FriendsHubScreen> createState() => _FriendsHubScreenState();
}

class _FriendsHubScreenState extends ConsumerState<FriendsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final pendingCount = requestsAsync.whenOrNull(data: (list) => list.length) ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Friends', style: AppTheme.bigNum(20)),
            ]),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _query.isNotEmpty ? AppTheme.voltLime : AppTheme.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: AppTheme.label(14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search @username...',
                  hintStyle: AppTheme.label(14, color: AppTheme.ink3),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ink2, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: const Icon(Icons.close_rounded, color: AppTheme.ink2, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTheme.ink2,
                  indicator: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    const Tab(text: 'My Friends'),
                    Tab(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Requests'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$pendingCount',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 4),

          Expanded(
            child: _query.isNotEmpty
                ? _SearchResults(query: _query, onRequestSent: () {
                    ref.invalidate(friendsListProvider);
                    ref.invalidate(friendRequestsProvider);
                  })
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _FriendsTab(onRemove: () => ref.invalidate(friendsListProvider)),
                      _RequestsTab(onAction: () {
                        ref.invalidate(friendsListProvider);
                        ref.invalidate(friendRequestsProvider);
                      }),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final VoidCallback onRequestSent;
  const _SearchResults({required this.query, required this.onRequestSent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(friendSearchProvider(query));
    return resultsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not search right now'),
      data: (results) {
        if (results.isEmpty) {
          return _EmptyState(text: 'No results for @$query');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _SearchResultRow(
            result: results[i],
            onAction: () {
              ref.invalidate(friendSearchProvider(query));
              onRequestSent();
            },
          ),
        );
      },
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final UserSearchResult result;
  final VoidCallback onAction;
  const _SearchResultRow({required this.result, required this.onAction});

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _loading = false;

  Future<void> _sendRequest() async {
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/friends/requests', {'receiver_id': widget.result.id});
      widget.onAction();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send request')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _Avatar(avatarUrl: r.avatarUrl, name: r.name, radius: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600)),
            if (r.username != null)
              Text('@${r.username}', style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        _leagueBadge(r.leagueSlug),
        const SizedBox(width: 10),
        _StatusButton(status: r.friendshipStatus, loading: _loading, onAdd: _sendRequest),
      ]),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final FriendshipStatus status;
  final bool loading;
  final VoidCallback onAdd;
  const _StatusButton({required this.status, required this.loading, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.voltLime));
    }
    switch (status) {
      case FriendshipStatus.none:
        return GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.voltLime),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+ Add', style: AppTheme.label(12, color: AppTheme.voltLime)
                .copyWith(fontWeight: FontWeight.w700)),
          ),
        );
      case FriendshipStatus.pendingSent:
        return Text('Pending', style: AppTheme.label(12, color: AppTheme.ink2));
      case FriendshipStatus.pendingReceived:
        return Text('Requested you', style: AppTheme.label(12, color: AppTheme.amber));
      case FriendshipStatus.friends:
        return const Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 18);
    }
  }
}

class _FriendsTab extends ConsumerWidget {
  final VoidCallback onRemove;
  const _FriendsTab({required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    return friendsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not load friends'),
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyState(
            text: 'No friends yet',
            subtitle: 'Search by @username above to add people',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _FriendRow(friend: friends[i], onRemove: () async {
            try {
              await ApiClient.instance.delete('/friends/${friends[i].id}');
              ref.invalidate(friendsListProvider);
              onRemove();
            } catch (_) {}
          }),
        );
      },
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final VoidCallback onRemove;
  const _FriendRow({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(friend.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Remove', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Remove ${friend.name}?',
                style: AppTheme.label(16, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
            content: Text('They won\'t be notified.',
                style: AppTheme.label(13, color: AppTheme.ink2)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: AppTheme.label(13, color: AppTheme.ink2))),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: Text('Remove', style: AppTheme.label(13, color: Color(0xFFFF4D4D)))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onRemove(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          _Avatar(avatarUrl: friend.avatarUrl, name: friend.name, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(friend.name, style: AppTheme.label(14, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              if (friend.username != null)
                Text('@${friend.username}', style: AppTheme.label(11, color: AppTheme.ink2)),
            ]),
          ),
          if (friend.streakDays > 0)
            Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text('${friend.streakDays}', style: AppTheme.label(11, color: Colors.white)),
              const SizedBox(width: 8),
            ]),
          _leagueBadge(friend.leagueSlug),
        ]),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final VoidCallback onAction;
  const _RequestsTab({required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    return requestsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not load requests'),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(text: 'You\'re all caught up', subtitle: '');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _RequestRow(
            request: requests[i],
            onAction: (action) async {
              try {
                await ApiClient.instance.patch('/friends/requests/${requests[i].id}', {'action': action});
                if (action == 'accept') HapticFeedback.mediumImpact();
                ref.invalidate(friendRequestsProvider);
                onAction();
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Action failed')));
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  final FriendRequest request;
  final void Function(String action) onAction;
  const _RequestRow({required this.request, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(request.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _Avatar(avatarUrl: request.senderAvatar, name: request.senderName, radius: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(request.senderName, style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600)),
            Text(
              request.senderUsername != null
                  ? '@${request.senderUsername} · $timeAgo'
                  : timeAgo,
              style: AppTheme.label(11, color: AppTheme.ink2),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () => onAction('accept'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.voltLime,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Accept', style: AppTheme.label(12, color: Colors.black)
                .copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onAction('decline'),
          child: Text('Decline', style: AppTheme.label(12, color: AppTheme.ink2)),
        ),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  const _Avatar({this.avatarUrl, required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surface2,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.inter(fontSize: radius * 0.7, fontWeight: FontWeight.w700, color: AppTheme.voltLime),
      ),
    );
  }
}

Widget _leagueBadge(String slug) {
  final color = switch (slug) {
    'gold' => const Color(0xFFF5A623),
    'silver' => const Color(0xFF9E9E9E),
    'platinum' => const Color(0xFF00BCD4),
    _ => AppTheme.ink3,
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      slug[0].toUpperCase() + slug.substring(1),
      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String text;
  final String? subtitle;
  const _EmptyState({required this.text, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: AppTheme.label(14, color: AppTheme.ink2)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.label(12, color: AppTheme.ink3)),
          ],
        ]),
      );
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
