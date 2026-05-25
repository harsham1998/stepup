import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/community_provider.dart';
import '../../../shared/models/community_post.dart';
import '../../../core/theme.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/community/create');
          ref.invalidate(communityFeedProvider);
        },
        backgroundColor: AppTheme.voltLime,
        child: const Icon(Icons.add_rounded, color: Color(0xFF050510)),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STEPUP',
                    style: AppTheme.bigNum(22, color: AppTheme.voltLime)),
                Row(children: [
                  const Icon(Icons.notifications_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 20),
                ]),
              ],
            ),
          ),

          // Stories row
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _StoryAvatar(name: 'You', hasNew: true, isMe: true),
                _StoryAvatar(name: 'Priya', hasNew: true, isMe: false),
                _StoryAvatar(name: 'Aarav', hasNew: true, isMe: false),
                _StoryAvatar(name: 'Megha', hasNew: false, isMe: false),
                _StoryAvatar(name: 'Vikram', hasNew: true, isMe: false),
                _StoryAvatar(name: 'Karthik', hasNew: false, isMe: false),
              ],
            ),
          ),

          Expanded(
            child: feedAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (err, stack) => const _MockFeed(),
              data: (posts) =>
                  posts.isEmpty ? const _MockFeed() : _LiveFeed(posts: posts),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Story Avatar ─────────────────────────────────────────────────────────

class _StoryAvatar extends StatelessWidget {
  final String name;
  final bool hasNew, isMe;
  const _StoryAvatar(
      {required this.name, required this.hasNew, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(children: [
        Stack(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNew
                  ? const SweepGradient(
                      colors: [AppTheme.voltLime, AppTheme.amber, AppTheme.voltLime])
                  : null,
              color: hasNew ? null : Colors.white.withValues(alpha: 0.1),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A26),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTheme.bigNum(18),
                ),
              ),
            ),
          ),
          if (isMe)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.voltLime),
                child: const Icon(Icons.add_rounded,
                    size: 12, color: Color(0xFF0A0A14)),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        Text(name,
            style: AppTheme.label(10, color: Colors.white),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Feeds ────────────────────────────────────────────────────────────────

class _LiveFeed extends StatelessWidget {
  final List<CommunityPost> posts;
  const _LiveFeed({required this.posts});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: posts.length,
        itemBuilder: (_, i) {
          final p = posts[i];
          return _PostCard(
            userName: p.userName,
            league: p.userLeague ?? 'Silver II',
            timeAgo: _timeAgo(p.createdAt),
            activityTitle: _activityTitle(p.type),
            caption: p.content,
            likes: p.likes,
            likedByMe: p.likedByMe,
            postType: p.type,
          );
        },
      );

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String _activityTitle(String type) {
    switch (type) {
      case 'flex':
        return 'Morning Run';
      case 'achievement':
        return 'Challenge Won';
      case 'milestone':
        return 'Milestone Hit';
      default:
        return 'Workout';
    }
  }
}

// ── Post Card ────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final String userName, league, timeAgo, activityTitle, caption, postType;
  final int likes;
  final bool likedByMe;

  const _PostCard({
    required this.userName,
    required this.league,
    required this.timeAgo,
    required this.activityTitle,
    required this.caption,
    required this.likes,
    required this.likedByMe,
    required this.postType,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.likedByMe;
    _likesCount = widget.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
  }

  Color get _typeColor => widget.postType == 'achievement'
      ? AppTheme.amber
      : AppTheme.voltLime;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: AppTheme.bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Author row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(children: [
            // Avatar with gradient ring
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppTheme.voltLime, AppTheme.amber]),
              ),
              padding: const EdgeInsets.all(1.5),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF1A1A26)),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                    style: AppTheme.bigNum(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName,
                        style: AppTheme.label(13, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Row(children: [
                      Text(widget.timeAgo,
                          style:
                              AppTheme.label(11, color: AppTheme.ink2)),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.ink2),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _typeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(widget.league,
                            style:
                                AppTheme.label(9, color: _typeColor)
                                    .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ]),
            ),
            const Icon(Icons.more_horiz_rounded,
                color: AppTheme.ink2, size: 20),
          ]),
        ),

        // ── Activity card (full width, no padding)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            // Title + stats area
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Large italic activity title
                Text(widget.activityTitle,
                    style: AppTheme.bigNum(26)
                        .copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),

                // Stats row: Distance / Time / Pace
                Row(children: [
                  _StatCol(label: 'Distance', value: '—', unit: 'km'),
                  _StatCol(label: 'Time', value: '—', unit: ''),
                  _StatCol(label: 'Pace', value: '—', unit: '/km'),
                ]),
              ]),
            ),

            // Achievement banner
            if (widget.postType == 'achievement')
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Text('🏅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Challenge completed · Top 50%',
                        style: AppTheme.label(12, color: AppTheme.amber)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),

            // Map placeholder
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A0D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.voltLime.withValues(alpha: 0.15)),
              ),
              child: Stack(children: [
                // Lime squiggly route line
                Center(
                  child: CustomPaint(
                    size: const Size(200, 60),
                    painter: _RoutePainter(),
                  ),
                ),
                // Distance pill
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('— km',
                        style: AppTheme.label(10, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ]),
        ),

        // ── Caption
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _CaptionText(text: widget.caption),
        ),

        // ── Actions row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(children: [
            GestureDetector(
              onTap: _toggleLike,
              child: Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _liked ? const Color(0xFFEF4444) : AppTheme.ink2,
                size: 22,
              ),
            ),
            const SizedBox(width: 5),
            Text('$_likesCount',
                style: AppTheme.label(13, color: AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.ink2, size: 22),
            const SizedBox(width: 5),
            Text('0',
                style: AppTheme.label(13, color: AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.share_outlined, color: AppTheme.ink2, size: 22),
            const SizedBox(width: 18),
            const Icon(Icons.bookmark_border_rounded,
                color: AppTheme.ink2, size: 22),
          ]),
        ),

        // Divider
        Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06)),
      ]),
    );
  }
}

// ── Stat Column ──────────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final String label, value, unit;
  const _StatCol(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: AppTheme.bigNum(22)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: AppTheme.label(11, color: AppTheme.ink2)),
              ),
            ],
          ]),
        ]),
      );
}

// ── Caption text with @mention highlight ────────────────────────────────

class _CaptionText extends StatelessWidget {
  final String text;
  const _CaptionText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isLast = i == words.length - 1;
      if (word.startsWith('@')) {
        spans.add(TextSpan(
          text: word + (isLast ? '' : ' '),
          style: AppTheme.label(13, color: AppTheme.voltLime)
              .copyWith(fontWeight: FontWeight.w600),
        ));
      } else {
        spans.add(TextSpan(
          text: word + (isLast ? '' : ' '),
          style: AppTheme.label(13, color: Colors.white),
        ));
      }
    }
    return Text.rich(TextSpan(children: spans));
  }
}

// ── Route line painter ───────────────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.voltLime
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.cubicTo(
      size.width * 0.2, size.height * 0.1,
      size.width * 0.3, size.height * 0.9,
      size.width * 0.5, size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.65, size.height * 0.05,
      size.width * 0.8, size.height * 0.85,
      size.width, size.height * 0.3,
    );
    canvas.drawPath(path, paint);

    // Start/end dots
    canvas.drawCircle(
        Offset(0, size.height * 0.5), 4,
        Paint()..color = AppTheme.voltLime);
    canvas.drawCircle(
        Offset(size.width, size.height * 0.3), 4,
        Paint()..color = AppTheme.voltLime);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mock Feed ─────────────────────────────────────────────────────────────

class _MockFeed extends StatelessWidget {
  const _MockFeed();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: const [
          _PostCard(
            userName: 'Aarav M',
            league: 'Gold III',
            timeAgo: '2h',
            activityTitle: 'Morning Run',
            caption:
                'First 10K under 45 min! Big shoutout to @priya for pacing 🏃',
            likes: 142,
            likedByMe: false,
            postType: 'flex',
          ),
          _PostCard(
            userName: 'Priya S',
            league: 'Platinum I',
            timeAgo: '5h',
            activityTitle: 'Challenge Won',
            caption:
                '14 days, zero misses. Huge thanks to @aarav and @megha for the support ✦',
            likes: 87,
            likedByMe: true,
            postType: 'achievement',
          ),
          _PostCard(
            userName: 'Vikram K',
            league: 'Silver II',
            timeAgo: '8h',
            activityTitle: 'Evening Walk',
            caption: 'Slow and steady wins the streak 🚶‍♂️ Day 7 done!',
            likes: 34,
            likedByMe: false,
            postType: 'milestone',
          ),
        ],
      );
}
