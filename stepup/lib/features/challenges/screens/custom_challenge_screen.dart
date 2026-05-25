import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class CustomChallengeScreen extends StatefulWidget {
  const CustomChallengeScreen({super.key});

  @override
  State<CustomChallengeScreen> createState() =>
      _CustomChallengeScreenState();
}

class _CustomChallengeScreenState
    extends State<CustomChallengeScreen> {
  final _titleCtrl = TextEditingController();
  String _activity = 'walk';
  String _difficulty = 'medium';
  int _duration = 7;
  String _frequency = '';
  bool _loading = false;

  static const _activities = [
    'walk', 'gym', 'yoga', 'run', 'cycle', 'sport'
  ];
  static const _activityLabels = {
    'walk': 'Walk',
    'gym': 'Gym',
    'yoga': 'Yoga',
    'run': 'Run',
    'cycle': 'Cycle',
    'sport': 'Sport',
  };
  static const _difficulties = {
    'easy': 60,
    'medium': 200,
    'hard': 500,
  };
  static const _durations = [3, 7, 14, 21, 30];

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a challenge title')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.post(
        '/challenges/custom',
        {
          'title': _titleCtrl.text.trim(),
          'activity': _activity,
          'difficulty': _difficulty,
          'duration_days': _duration,
          'frequency': _frequency,
        },
      ) as Map<String, dynamic>;
      if (!mounted) return;
      context.pushReplacement(
          '/challenges/custom/${res['id']}/invite');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinReward = _difficulties[_difficulty] ?? 200;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    Text('Create Challenge',
                        style: AppTheme.bigNum(24)),
                  ]),
                  const SizedBox(height: 20),

                  _Label('Challenge Name'),
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        hintText: 'e.g. Morning Walk Warrior'),
                  ),
                  const SizedBox(height: 20),

                  _Label('Activity'),
                  Wrap(
                    spacing: 8,
                    children: _activities
                        .map((a) => _Chip(
                              label: _activityLabels[a]!,
                              selected: _activity == a,
                              onTap: () =>
                                  setState(() => _activity = a),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  _Label('Difficulty'),
                  Row(
                    children: _difficulties.keys
                        .map((d) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _difficulty = d),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _difficulty == d
                                          ? AppTheme.voltLime
                                              .withOpacity(0.1)
                                          : AppTheme.surface,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _difficulty == d
                                            ? AppTheme.voltLime
                                            : AppTheme.border,
                                      ),
                                    ),
                                    child: Column(children: [
                                      Text(
                                        d[0].toUpperCase() +
                                            d.substring(1),
                                        style: AppTheme.label(13,
                                                color: _difficulty ==
                                                        d
                                                    ? AppTheme
                                                        .voltLime
                                                    : Colors.white)
                                            .copyWith(
                                                fontWeight:
                                                    FontWeight.w600),
                                      ),
                                      Text(
                                        '+${_difficulties[d]}¢',
                                        style: AppTheme.label(11,
                                            color: AppTheme.amber),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  _Label('Duration'),
                  Wrap(
                    spacing: 8,
                    children: _durations
                        .map((d) => _Chip(
                              label: '${d}d',
                              selected: _duration == d,
                              onTap: () =>
                                  setState(() => _duration = d),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  _Label('Frequency (optional)'),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => _frequency = v,
                    decoration: const InputDecoration(
                        hintText: 'e.g. 4 sessions / week'),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.amber.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Coin reward (system-generated)',
                            style: AppTheme.label(13)),
                        Text('+$coinReward¢',
                            style: AppTheme.bigNum(18,
                                color: AppTheme.amber)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _create,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.bg),
                            )
                          : const Text(
                              'Next — Invite Friends'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
              letterSpacing: 1.0, fontWeight: FontWeight.w700),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.voltLime.withOpacity(0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.voltLime
                  : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.label(13,
                    color: selected
                        ? AppTheme.voltLime
                        : AppTheme.ink2)
                .copyWith(
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.normal),
          ),
        ),
      );
}
