import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/theme.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});
  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  bool _showMy = false;
  int _cadenceTab = 0;
  late final _pageCtrl = PageController();

  static const _cadenceTabs = ['DAILY', 'WEEKLY', 'MONTHLY', 'SEASONAL'];
  static const _cadenceKeys = ['daily', 'weekly', 'monthly', 'seasonal'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    final myChallengesAsync = ref.watch(myChallengesProvider);

    final myActive = myChallengesAsync.whenOrNull(
            data: (list) => list.where((c) => c.isLive).toList()) ??
        [];
    final myDone = myChallengesAsync.whenOrNull(
            data: (list) => list.where((c) => !c.isLive).toList()) ??
        [];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_showMy ? 'My Challenges' : 'Challenges',
                    style: AppTheme.bigNum(28)),
                Row(children: [
                  _TabToggle(
                    leftLabel: 'MY',
                    rightLabel: 'DISCOVER',
                    leftActive: _showMy,
                    onToggle: (v) => setState(() => _showMy = v),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: AppTheme.ink2, size: 16),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_showMy)
            Expanded(
              child: _MyChallengesView(
                active: myActive,
                done: myDone,
                isLoading: myChallengesAsync.isLoading,
              ),
            )
          else ...[
            _CadenceTabs(
              selected: _cadenceTab,
              tabs: _cadenceTabs,
              onSelect: (i) {
                setState(() => _cadenceTab = i);
                _pageCtrl.animateToPage(i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _cadenceTab = i),
                itemCount: _cadenceTabs.length,
                itemBuilder: (_, tabIdx) {
                  final cadenceKey = _cadenceKeys[tabIdx];
                  final myIds = myChallengesAsync.whenOrNull(
                          data: (list) => list.map((c) => c.id).toSet()) ??
                      {};
                  return challengesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.voltLime)),
                    error: (e, _) => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: AppTheme.ink3, size: 40),
                        const SizedBox(height: 8),
                        Text('$e',
                            style: AppTheme.label(12, color: AppTheme.ink2),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    data: (all) {
                      final filtered = all
                          .where((c) => c.cadence == cadenceKey)
                          .toList();

                      Challenge? featured;
                      final rest = <Challenge>[];
                      for (final c in filtered) {
                        if (featured == null &&
                            c.isLive &&
                            !myIds.contains(c.id)) {
                          featured = c;
                        } else {
                          rest.add(c);
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          if (featured != null) ...[
                            _FeaturedHero(
                              challenge: featured,
                              onTap: () =>
                                  context.push('/challenges/${featured!.id}'),
                            ),
                            const SizedBox(height: 16),
                          ],
                          GestureDetector(
                            onTap: () =>
                                context.push('/challenges/custom/new'),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.voltLime.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppTheme.voltLime
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('+ Create your own challenge',
                                            style: AppTheme.label(14,
                                                    color: Colors.white)
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                            'Invite friends · system sets reward',
                                            style: AppTheme.label(11,
                                                color: AppTheme.ink2)),
                                      ]),
                                ),
                                Text('→',
                                    style: AppTheme.bigNum(20,
                                        color: AppTheme.voltLime)),
                              ]),
                            ),
                          ),
                          if (rest.isNotEmpty) ...[
                            _SectionLabel(
                              label:
                                  '${_cadenceTabs[tabIdx]} CHALLENGES',
                              color: AppTheme.ink2,
                            ),
                            const SizedBox(height: 10),
                          ],
                          ...rest.map((c) => _ChallengeRow(
                                challenge: c,
                                isJoined: myIds.contains(c.id),
                                onTap: () =>
                                    context.push('/challenges/${c.id}'),
                              )),
                          if (filtered.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🏋️',
                                          style: TextStyle(fontSize: 40)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'No ${_cadenceTabs[tabIdx].toLowerCase()} challenges yet',
                                          style: AppTheme.label(13,
                                              color: AppTheme.ink2)),
                                    ]),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Activity Image Asset ───────────────────────────────────────────────────

const _activityImages = <String, List<String>>{
  'running': ['assets/challenges/running_1.jpg', 'assets/challenges/running_2.jpg'],
  'gym':     ['assets/challenges/gym_1.jpg',     'assets/challenges/gym_2.jpg'],
  'cycling': ['assets/challenges/cycling_1.jpg', 'assets/challenges/cycling_2.jpg'],
  'outdoor': ['assets/challenges/outdoor_1.jpg'],
  'steps':   ['assets/challenges/steps_1.jpg',   'assets/challenges/steps_2.jpg'],
  'walking': ['assets/challenges/steps_2.jpg',   'assets/challenges/walking_2.jpg'],
};

String _activityImageAsset(String activityType, String challengeId) {
  final paths = _activityImages[activityType.toLowerCase()] ?? _activityImages['steps']!;
  if (paths.length == 1) return paths[0];
  return paths[challengeId.codeUnitAt(challengeId.length - 1) % paths.length];
}

// ── Featured Hero Card (Design 6 — full bleed) ────────────────────────────

class _FeaturedHero extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;
  const _FeaturedHero({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: cfg.colorA.withValues(alpha: 0.2)),
              Image.asset(
                _activityImageAsset(challenge.activityType, challenge.id),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const SizedBox(),
              ),
              Container(color: Colors.black.withValues(alpha: 0.48)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      cfg.colorA.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _CardBadge(
                        label: '★ FEATURED',
                        bgColor: AppTheme.voltLime,
                        textColor: AppTheme.bg,
                      ),
                      const SizedBox(width: 8),
                      _CardBadge(
                        label: cfg.label.toUpperCase(),
                        bgColor: cfg.colorA.withValues(alpha: 0.85),
                        textColor: Colors.white,
                      ),
                    ]),
                    const Spacer(),
                    Text(
                      challenge.title,
                      style: AppTheme.bigNum(24)
                          .copyWith(fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.goalLabel,
                      style: AppTheme.label(11,
                          color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _HeroStat(
                        label: 'REWARD',
                        value: challenge.prizePoolCoins,
                        color: AppTheme.amber,
                      ),
                      const _StatDot(),
                      _HeroStat(
                        label: 'PLAYERS',
                        value: '${challenge.participantCount}',
                      ),
                      const _StatDot(),
                      _HeroStat(
                        label: 'DURATION',
                        value: challenge.durationLabel,
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.voltLime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFF050510), size: 16),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Challenge Row (Design 6 — full bleed) ─────────────────────────────────

class _ChallengeRow extends StatelessWidget {
  final Challenge challenge;
  final bool isJoined;
  final VoidCallback onTap;
  const _ChallengeRow(
      {required this.challenge, required this.isJoined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: cfg.colorA.withValues(alpha: 0.2)),
                Image.asset(
                  _activityImageAsset(challenge.activityType, challenge.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox(),
                ),
                Container(color: Colors.black.withValues(alpha: 0.48)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [
                        Colors.transparent,
                        cfg.colorA.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _CardBadge(
                          label: cfg.label.toUpperCase(),
                          bgColor: cfg.colorA.withValues(alpha: 0.85),
                          textColor: Colors.white,
                        ),
                        const Spacer(),
                        if (isJoined)
                          _CardBadge(
                            label: '✓ JOINED',
                            bgColor: AppTheme.voltLime.withValues(alpha: 0.9),
                            textColor: AppTheme.bg,
                          ),
                      ]),
                      const Spacer(),
                      Text(
                        challenge.title,
                        style: AppTheme.bigNum(18)
                            .copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        _RowStat(
                          label: 'REWARD',
                          value: challenge.prizePoolCoins,
                          color: AppTheme.amber,
                        ),
                        const SizedBox(width: 16),
                        _RowStat(
                          label: 'PLAYERS',
                          value: '${challenge.participantCount}',
                        ),
                        const SizedBox(width: 16),
                        _RowStat(
                          label: 'ENTRY',
                          value: challenge.entryFeeCoins,
                        ),
                        const Spacer(),
                        if (!isJoined)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: challenge.isPaid
                                  ? AppTheme.amber
                                  : AppTheme.voltLime,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Join →',
                              style: AppTheme.label(11, color: AppTheme.bg)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card Badge ─────────────────────────────────────────────────────────────

class _CardBadge extends StatelessWidget {
  final String label;
  final Color bgColor, textColor;
  const _CardBadge(
      {required this.label, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.label(9, color: textColor)
              .copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
      );
}

// ── Hero Stat ──────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _HeroStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.label(8,
                      color: Colors.white.withValues(alpha: 0.55))
                  .copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTheme.bigNum(14, color: color ?? Colors.white)
                  .copyWith(fontWeight: FontWeight.w900)),
        ],
      );
}

class _StatDot extends StatelessWidget {
  const _StatDot();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      );
}

// ── Row Stat ───────────────────────────────────────────────────────────────

class _RowStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _RowStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.label(8,
                      color: Colors.white.withValues(alpha: 0.55))
                  .copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 1),
          Text(value,
              style: AppTheme.label(12, color: color ?? Colors.white)
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      );
}

// ── Cadence Tabs ───────────────────────────────────────────────────────────

class _CadenceTabs extends StatelessWidget {
  final int selected;
  final List<String> tabs;
  final ValueChanged<int> onSelect;
  const _CadenceTabs(
      {required this.selected, required this.tabs, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tabs.length,
          itemBuilder: (_, i) {
            final sel = selected == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.voltLime : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppTheme.voltLime : AppTheme.border,
                  ),
                ),
                child: Text(tabs[i],
                    style: AppTheme.label(11).copyWith(
                        color: sel ? AppTheme.bg : AppTheme.ink2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
            );
          },
        ),
      );
}

// ── My Challenges View ─────────────────────────────────────────────────────

class _MyChallengesView extends StatefulWidget {
  final List<Challenge> active, done;
  final bool isLoading;
  const _MyChallengesView(
      {required this.active, required this.done, required this.isLoading});

  @override
  State<_MyChallengesView> createState() => _MyChallengesViewState();
}

class _MyChallengesViewState extends State<_MyChallengesView> {
  int _tab = 0; // 0=Active, 1=Done, 2=Saved

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.voltLime));
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _TabPill(
              label: 'ACTIVE',
              count: widget.active.length,
              active: _tab == 0,
              onTap: () => setState(() => _tab = 0)),
          const SizedBox(width: 8),
          _TabPill(
              label: 'DONE',
              count: widget.done.length,
              active: _tab == 1,
              onTap: () => setState(() => _tab = 1)),
          const SizedBox(width: 8),
          _TabPill(
              label: 'SAVED',
              count: 0,
              active: _tab == 2,
              onTap: () => setState(() => _tab = 2)),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(child: Builder(builder: (context) {
        if (_tab == 2) {
          return const _EmptyState(
              message: 'No saved challenges',
              sub: 'Bookmark challenges to save them');
        }
        final items = _tab == 0 ? widget.active : widget.done;
        if (items.isEmpty) {
          return _EmptyState(
            message: _tab == 0 ? 'No active challenges' : 'No completed yet',
            sub: _tab == 0
                ? 'Switch to Discover to join one'
                : 'Finish your active ones!',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children:
              items.map((c) => _MyChallengeTile(challenge: c, highlight: _tab == 0)).toList(),
        );
      })),
    ]);
  }
}

class _MyChallengeTile extends ConsumerWidget {
  final Challenge challenge;
  final bool highlight;
  const _MyChallengeTile({required this.challenge, required this.highlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(challengeProgressProvider(challenge.id));
    final cfg = challenge.activity;

    final days = challenge.endTime.difference(challenge.startTime).inDays.clamp(1, 9999);
    final daysPassed = DateTime.now().difference(challenge.startTime).inDays.clamp(0, days);

    final double pct = progressAsync.whenOrNull(
          data: (p) => p?.percent,
        ) ??
        (daysPassed / days).clamp(0.0, 1.0);

    final String progressLabel = progressAsync.whenOrNull(
          data: (p) {
            if (p == null) return 'Day $daysPassed/$days';
            if (['gym', 'cycling', 'outdoor'].contains(p.activityType)) {
              return '${p.current}/${p.goal} sessions · Day $daysPassed/$days';
            }
            final cur = p.current >= 1000
                ? '${(p.current / 1000).toStringAsFixed(1)}k'
                : '${p.current}';
            final goal = p.goal >= 1000
                ? '${(p.goal / 1000).toStringAsFixed(0)}k'
                : '${p.goal}';
            return '$cur/$goal steps · Day $daysPassed/$days';
          },
        ) ??
        'Day $daysPassed/$days';

    return GestureDetector(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: cfg.colorA.withValues(alpha: 0.2)),
                Image.asset(
                  _activityImageAsset(challenge.activityType, challenge.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox(),
                ),
                Container(color: Colors.black.withValues(alpha: 0.52)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [
                        Colors.transparent,
                        cfg.colorA.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _CardBadge(
                          label: cfg.label.toUpperCase(),
                          bgColor: cfg.colorA.withValues(alpha: 0.85),
                          textColor: Colors.white,
                        ),
                        const Spacer(),
                        _CardBadge(
                          label: '${(pct * 100).round()}%',
                          bgColor: pct >= 1.0
                              ? AppTheme.voltLime
                              : Colors.white.withValues(alpha: 0.2),
                          textColor: pct >= 1.0 ? AppTheme.bg : Colors.white,
                        ),
                      ]),
                      const Spacer(),
                      Text(
                        challenge.title,
                        style: AppTheme.bigNum(17).copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(progressLabel,
                            style: AppTheme.label(10,
                                color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(width: 8),
                        Text(challenge.prizePoolCoins,
                            style: AppTheme.label(10, color: AppTheme.amber)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Shared widgets ─────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabPill(
      {required this.label,
      required this.count,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.voltLime.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppTheme.voltLime.withValues(alpha: 0.5)
                  : AppTheme.border,
            ),
          ),
          child: Text(
            count > 0 ? '$label · $count' : label,
            style: AppTheme.label(11,
                    color: active ? AppTheme.voltLime : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      );
}

class _TabToggle extends StatelessWidget {
  final String leftLabel, rightLabel;
  final bool leftActive;
  final ValueChanged<bool> onToggle;
  const _TabToggle(
      {required this.leftLabel,
      required this.rightLabel,
      required this.leftActive,
      required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Pill(
              label: leftLabel,
              active: leftActive,
              onTap: () => onToggle(true)),
          _Pill(
              label: rightLabel,
              active: !leftActive,
              onTap: () => onToggle(false)),
        ]),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppTheme.voltLime : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: AppTheme.label(10,
                      color: active ? AppTheme.bg : AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w900)),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTheme.label(10, color: color)
          .copyWith(letterSpacing: 0.7, fontWeight: FontWeight.w800));
}

class _EmptyState extends StatelessWidget {
  final String message, sub;
  const _EmptyState({required this.message, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(message,
              style: AppTheme.label(14, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub,
              style: AppTheme.label(12, color: AppTheme.ink2),
              textAlign: TextAlign.center),
        ]),
      );
}
