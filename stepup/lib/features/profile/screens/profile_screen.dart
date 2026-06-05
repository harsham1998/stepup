import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../league/providers/league_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/xp_level_provider.dart';
import '../providers/reputation_provider.dart';
import '../providers/body_vitals_provider.dart';
import '../../../shared/models/xp_level.dart';
import '../../../shared/models/reputation.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(profileSummaryProvider);
    final leagueAsync = ref.watch(leagueStatusProvider);
    final subAsync = ref.watch(mySubscriptionProvider);
    final xpAsync = ref.watch(xpLevelProvider);
    final repAsync = ref.watch(reputationProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const _ProfileSkeleton(),
          error: (e, _) => _ProfileBody(
            summary: const {},
            leagueAsync: leagueAsync,
            subAsync: subAsync,
            xpAsync: xpAsync,
            repAsync: repAsync,
          ),
          data: (summary) => _ProfileBody(
            summary: summary,
            leagueAsync: leagueAsync,
            subAsync: subAsync,
            xpAsync: xpAsync,
            repAsync: repAsync,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final Map<String, dynamic> summary;
  final AsyncValue<dynamic> leagueAsync;
  final AsyncValue<dynamic> subAsync;
  final AsyncValue<XpLevel> xpAsync;
  final AsyncValue<Reputation> repAsync;

  const _ProfileBody({
    required this.summary,
    required this.leagueAsync,
    required this.subAsync,
    required this.xpAsync,
    required this.repAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Name: trim and fall back to phone if empty
    final rawName = (summary['name'] as String? ?? '').trim();
    final name = rawName.isNotEmpty ? rawName : (summary['phone'] as String? ?? 'You');
    final streakDays = summary['streak_days'] as int? ?? 0;
    final xp = summary['xp'] as int? ?? 0;
    final coinBalance = summary['coin_balance'] as int? ?? 0;
    final league = summary['league'] as String? ?? 'bronze';
    final missions = summary['missions_today'] as Map<String, dynamic>?;
    final rivalsCount = summary['rivals_count'] as int? ?? 0;
    final challengesActive = summary['challenges_active'] as int? ?? 0;
    final achievementsEarned = summary['achievements_earned'] as int? ?? 0;
    final weekSteps = (summary['week_steps'] as List<dynamic>?) ?? [];
    final createdAt = summary['created_at'] as String?;
    final missionsCompleted = missions?['completed'] as int? ?? 0;
    final missionsTotal = missions?['total'] as int? ?? 0;

    final joinedLabel = _joinedLabel(createdAt);
    final city = (summary['city'] as String? ?? '').trim();

    final realLevel = xpAsync.whenOrNull(data: (x) => x.level);
    final repScore = repAsync.whenOrNull(data: (r) => r.score);
    final vitalsAsync = ref.watch(bodyVitalsSummaryProvider);
    final latestWeight = vitalsAsync.whenOrNull(
      data: (v) => v.latest?.weightKg != null
          ? '${v.latest!.weightKg!.toStringAsFixed(1)} kg'
          : null,
    );

    // Streak ring: cap at 30-day cycle
    final streakProgress = (streakDays % 30) / 30.0;
    // Mission ring
    final missionProgress = missionsTotal > 0 ? missionsCompleted / missionsTotal : 0.0;

    final summaryAvatarUrl = summary['avatar_url'] as String?;
    final avatarState = ref.watch(avatarUploadProvider);
    // Keep avatarUploadProvider in sync for upload interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(avatarUploadProvider.notifier).seedUrl(summaryAvatarUrl);
    });

    // Show error snackbar once if upload failed
    if (avatarState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(avatarState.error!),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      });
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Avatar + info + action buttons ───────────────────
              _AvatarHeader(
                name: name,
                city: city,
                joinedLabel: joinedLabel,
                avatarState: avatarState,
                summaryAvatarUrl: summaryAvatarUrl,
                streakProgress: streakProgress,
                missionProgress: missionProgress,
                league: league,
                xp: xp,
                subAsync: subAsync,
                leagueAsync: leagueAsync,
                realLevel: realLevel,
              ),
              const SizedBox(height: 16),

              // ── 4-stat bar ────────────────────────────────────
              _StatBar(
                streakDays: streakDays,
                xp: xp,
                challengesActive: challengesActive,
                coinBalance: coinBalance,
              ),
              const SizedBox(height: 16),

              // ── Weekly day rings ──────────────────────────────
              _WeekRings(weekSteps: weekSteps),
              const SizedBox(height: 24),

              // ── PROGRESS section ──────────────────────────────
              _SectionLabel('PROGRESS'),
              const SizedBox(height: 8),
              _GroupedCard(children: [
                _MenuRow(
                  icon: Icons.bar_chart_rounded,
                  iconBg: const Color(0xFF0F2A0F),
                  iconColor: AppTheme.voltLime,
                  label: 'Fitness Reputation',
                  value: repScore != null ? '$repScore' : '—',
                  valueSuffix: repScore != null ? ' / 900' : '',
                  onTap: () => context.push('/profile/reputation'),
                ),
                _MenuRow(
                  icon: Icons.bolt_rounded,
                  iconBg: const Color(0xFF1A0F2A),
                  iconColor: const Color(0xFFA78BFA),
                  label: 'XP & Level',
                  value: realLevel != null ? 'LV $realLevel' : 'LV ${_xpToLevel(xp)}',
                  onTap: () => context.push('/profile/xp'),
                ),
                _MenuRow(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFF2A0F0F),
                  iconColor: const Color(0xFFFF8080),
                  label: 'Streak & Shield',
                  value: '$streakDays 🔥',
                  onTap: () => context.push('/streaks'),
                ),
                _MenuRow(
                  icon: Icons.emoji_events_rounded,
                  iconBg: const Color(0xFF1A1400),
                  iconColor: AppTheme.amber,
                  label: 'Achievements',
                  value: '$achievementsEarned earned',
                  onTap: () => context.push('/profile/achievements'),
                ),
                _MenuRow(
                  icon: Icons.monitor_weight_outlined,
                  iconBg: const Color(0xFF0F1A0F),
                  iconColor: AppTheme.voltLime,
                  label: 'Body Vitals',
                  value: latestWeight ?? 'Track →',
                  onTap: () => context.push('/profile/body-vitals'),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 20),

              // ── COMPETE section ───────────────────────────────
              _SectionLabel('COMPETE'),
              const SizedBox(height: 8),
              _GroupedCard(children: [
                _MenuRow(
                  icon: Icons.checklist_rounded,
                  iconBg: const Color(0xFF0F1A2A),
                  iconColor: const Color(0xFF63B4FF),
                  label: 'Daily Missions',
                  value: missionsTotal > 0 ? '$missionsCompleted/$missionsTotal done' : '—',
                  onTap: () => context.push('/missions'),
                ),
                _MenuRow(
                  icon: Icons.sports_kabaddi_rounded,
                  iconBg: const Color(0xFF1A0F1A),
                  iconColor: const Color(0xFFF472B6),
                  label: 'Rivals',
                  value: rivalsCount > 0 ? '$rivalsCount active' : 'None yet',
                  onTap: () => context.push('/rivals'),
                ),
                _MenuRow(
                  icon: Icons.military_tech_rounded,
                  iconBg: const Color(0xFF1A1400),
                  iconColor: AppTheme.amber,
                  label: 'League',
                  value: _leagueLabel(league),
                  onTap: () => context.push('/leaderboard/league'),
                ),
                _MenuRow(
                  icon: Icons.flag_rounded,
                  iconBg: const Color(0xFF0F1F1F),
                  iconColor: AppTheme.voltLime,
                  label: 'Challenges',
                  value: challengesActive > 0 ? '$challengesActive active' : 'Browse',
                  onTap: () => context.push('/challenges'),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 20),

              // ── ACCOUNT section ───────────────────────────────
              _SectionLabel('ACCOUNT'),
              const SizedBox(height: 8),
              _GroupedCard(children: [
                _MenuRow(
                  icon: Icons.monetization_on_rounded,
                  iconBg: const Color(0xFF1A1200),
                  iconColor: AppTheme.amber,
                  label: 'Coins & Rewards',
                  value: _formatCoins(coinBalance),
                  onTap: () => context.push('/coins'),
                ),
                _MenuRow(
                  icon: Icons.credit_card_rounded,
                  iconBg: const Color(0xFF0F0F1A),
                  iconColor: const Color(0xFFA78BFA),
                  label: 'Plan & Billing',
                  onTap: () => context.push('/profile/subscription'),
                ),
                _MenuRow(
                  icon: Icons.watch_rounded,
                  iconBg: const Color(0xFF0F1A1A),
                  iconColor: const Color(0xFF63B4FF),
                  label: 'Watch & Devices',
                  onTap: () => context.push('/profile/devices'),
                ),
                _MenuRow(
                  icon: Icons.notifications_none_rounded,
                  iconBg: const Color(0xFF1A0F0F),
                  iconColor: const Color(0xFFFF8080),
                  label: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuRow(
                  icon: Icons.history_rounded,
                  iconBg: const Color(0xFF0F1A0F),
                  iconColor: AppTheme.voltLime,
                  label: 'Activity History',
                  onTap: () => context.push('/activities'),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 20),

              // ── Sign out ──────────────────────────────────────
              _SignOutButton(),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }

  String _joinedLabel(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Joined ${months[dt.month - 1]} ${dt.year}';
  }

  String _leagueLabel(String slug) {
    const map = {
      'bronze': 'Bronze',
      'silver': 'Silver',
      'gold': 'Gold',
      'platinum': 'Platinum',
      'diamond': 'Diamond',
      'elite': 'Elite',
    };
    return map[slug] ?? slug;
  }

  String _formatCoins(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static int _xpToLevel(int xp) => (xp / 500).floor() + 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Header
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarHeader extends ConsumerWidget {
  final String name;
  final String city;
  final String joinedLabel;
  final AvatarState avatarState;
  final String? summaryAvatarUrl;
  final double streakProgress;
  final double missionProgress;
  final String league;
  final int xp;
  final AsyncValue<dynamic> subAsync;
  final AsyncValue<dynamic> leagueAsync;
  final int? realLevel;

  const _AvatarHeader({
    required this.name,
    required this.city,
    required this.joinedLabel,
    required this.avatarState,
    this.summaryAvatarUrl,
    required this.streakProgress,
    required this.missionProgress,
    required this.league,
    required this.xp,
    required this.subAsync,
    required this.leagueAsync,
    this.realLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = avatarState.isUploading;
    // avatarUploadProvider tracks uploads in-session; fall back to DB value so
    // the photo shows immediately without waiting for seedUrl to propagate.
    final avatarUrl = avatarState.url ?? summaryAvatarUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with dual rings
        GestureDetector(
          onTap: isUploading
              ? null
              : () => ref.read(avatarUploadProvider.notifier).pickAndUpload(),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _DualRingPainter(
                    outerProgress: streakProgress,
                    innerProgress: missionProgress,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.voltLime.withValues(alpha: 0.1),
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: AppTheme.bigNum(22, color: AppTheme.voltLime),
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bg, width: 2),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF050510),
                            ),
                          )
                        : const Icon(Icons.add, size: 12, color: Color(0xFF050510)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name + chips — fills remaining space
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.bigNum(20)),
              const SizedBox(height: 3),
              if (joinedLabel.isNotEmpty || city.isNotEmpty)
                Text(
                  [if (joinedLabel.isNotEmpty) joinedLabel, if (city.isNotEmpty) city].join(' · '),
                  style: AppTheme.label(11, color: AppTheme.ink2),
                ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                subAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => _Chip(label: 'Free', color: AppTheme.voltLime),
                  data: (sub) {
                    final isPaid = sub?.isPaid as bool? ?? false;
                    final plan = sub?.planSlug as String? ?? 'free';
                    return _Chip(
                      label: isPaid ? plan[0].toUpperCase() + plan.substring(1) : 'Free',
                      color: AppTheme.voltLime,
                    );
                  },
                ),
                _Chip(label: _leagueLabel(league), color: AppTheme.amber),
                _Chip(label: 'LV ${realLevel ?? _xpToLevel(xp)}', color: const Color(0xFFA78BFA)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Action buttons — top-aligned beside the avatar
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: () => context.push('/community'),
                ),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.settings_rounded, onTap: () => context.push('/profile/edit')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _leagueLabel(String slug) {
    const map = {
      'bronze': 'Bronze',
      'silver': 'Silver',
      'gold': 'Gold',
      'platinum': 'Platinum',
      'diamond': 'Diamond',
      'elite': 'Elite',
    };
    return map[slug] ?? slug;
  }

  static int _xpToLevel(int xp) => (xp / 500).floor() + 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dual ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _DualRingPainter extends CustomPainter {
  final double outerProgress; // streak
  final double innerProgress; // missions

  const _DualRingPainter({required this.outerProgress, required this.innerProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sweepAngle = 2 * math.pi;

    // Track paints
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer ring (streak) — radius ~37
    const outerR = 37.0;
    trackPaint.color = AppTheme.voltLime.withValues(alpha: 0.1);
    trackPaint.strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), outerR, trackPaint);

    if (outerProgress > 0) {
      trackPaint.color = AppTheme.voltLime;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
        -math.pi / 2,
        sweepAngle * outerProgress.clamp(0.0, 1.0),
        false,
        trackPaint,
      );
    }

    // Inner ring (missions) — radius ~30
    const innerR = 30.0;
    trackPaint.color = AppTheme.amber.withValues(alpha: 0.1);
    trackPaint.strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), innerR, trackPaint);

    if (innerProgress > 0) {
      trackPaint.color = AppTheme.amber;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
        -math.pi / 2,
        sweepAngle * innerProgress.clamp(0.0, 1.0),
        false,
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DualRingPainter old) =>
      old.outerProgress != outerProgress || old.innerProgress != innerProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4-stat bar
// ─────────────────────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  final int streakDays;
  final int xp;
  final int challengesActive;
  final int coinBalance;

  const _StatBar({
    required this.streakDays,
    required this.xp,
    required this.challengesActive,
    required this.coinBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _StatCell(value: '$streakDays 🔥', label: 'Streak', color: AppTheme.voltLime),
        _divider(),
        _StatCell(value: '$xp', label: 'XP', color: Colors.white),
        _divider(),
        _StatCell(value: '$challengesActive', label: 'Challenges', color: Colors.white),
        _divider(),
        _StatCell(
          value: coinBalance >= 1000
              ? '${(coinBalance / 1000).toStringAsFixed(1)}K'
              : '$coinBalance',
          label: 'Coins',
          color: AppTheme.amber,
        ),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppTheme.border);
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCell({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Text(value, style: AppTheme.bigNum(18, color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.label(9, color: AppTheme.ink2)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Week streak row  (🔥 = active, 🪦 = missed, future = dimmed)
// ─────────────────────────────────────────────────────────────────────────────

class _WeekRings extends StatelessWidget {
  final List<dynamic> weekSteps;

  const _WeekRings({required this.weekSteps});

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _minSteps = 1000; // threshold to count as streak maintained

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This week',
                style: AppTheme.label(11, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '🔥',
                style: AppTheme.label(10, color: AppTheme.ink2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayData = i < weekSteps.length
                  ? weekSteps[i] as Map<String, dynamic>
                  : <String, dynamic>{};
              final steps = dayData['steps'] as int? ?? 0;
              final date = dayData['date'] as String? ?? '';
              final isToday = date == todayStr;
              final isFuture = date.isNotEmpty && date.compareTo(todayStr) > 0;
              final maintained = !isFuture && steps >= _minSteps;

              return _DayStreakCell(
                label: _dayLabels[i],
                maintained: maintained,
                isToday: isToday,
                isFuture: isFuture,
                steps: steps,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayStreakCell extends StatelessWidget {
  final String label;
  final bool maintained;
  final bool isToday;
  final bool isFuture;
  final int steps;

  const _DayStreakCell({
    required this.label,
    required this.maintained,
    required this.isToday,
    required this.isFuture,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji indicator
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: maintained
                ? AppTheme.voltLime.withValues(alpha: 0.08)
                : isFuture
                    ? Colors.transparent
                    : const Color(0xFF1A0A0A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? AppTheme.voltLime.withValues(alpha: 0.5)
                  : AppTheme.border,
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              isFuture ? '·' : (maintained ? '🔥' : '🪦'),
              style: TextStyle(
                fontSize: isFuture ? 18 : 18,
                color: isFuture ? AppTheme.ink3 : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTheme.label(8,
              color: isToday ? AppTheme.voltLime : AppTheme.ink3)
              .copyWith(fontWeight: isToday ? FontWeight.w700 : FontWeight.w400),
        ),
        const SizedBox(height: 2),
        // Step count (non-zero, non-future days)
        if (!isFuture && steps > 0)
          Text(
            steps >= 1000 ? '${(steps / 1000).toStringAsFixed(1)}k' : '$steps',
            style: AppTheme.label(7, color: AppTheme.ink3),
          )
        else
          const SizedBox(height: 9),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped section card + rows
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.label(10, color: AppTheme.ink3)
            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
      );
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: children),
      );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? value;
  final String? valueSuffix;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.value,
    this.valueSuffix,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.border),
                  ),
                ),
          child: Row(children: [
            // Icon box
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                label,
                style: AppTheme.label(13, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),

            // Value
            if (value != null) ...[
              Text(
                value! + (valueSuffix ?? ''),
                style: AppTheme.label(12, color: AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
            ],

            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.ink3, size: 12),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign out
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
        onTap: () async {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) context.go('/login');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text(
              'Sign Out',
              style: AppTheme.label(14, color: const Color(0xFFEF4444))
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: AppTheme.label(10, color: color).copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, color: AppTheme.ink2, size: 16),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _Bone(w: 80, h: 80, r: 40),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Bone(w: 120, h: 20),
                const SizedBox(height: 6),
                _Bone(w: 80, h: 14),
                const SizedBox(height: 8),
                _Bone(w: 140, h: 22),
              ]),
            ]),
            const SizedBox(height: 16),
            _Bone(w: double.infinity, h: 60, r: 14),
            const SizedBox(height: 16),
            _Bone(w: double.infinity, h: 50, r: 12),
          ],
        ),
      );
}

class _Bone extends StatelessWidget {
  final double w;
  final double h;
  final double r;

  const _Bone({required this.w, required this.h, this.r = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}
