import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

class LogSessionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  const LogSessionScreen({this.initialType, super.key});

  @override
  ConsumerState<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends ConsumerState<LogSessionScreen> {
  String _activityType = 'gym';
  int _durationMinutes = 45;
  int _intensityIndex = 2; // 0=Low, 1=Medium, 2=High
  final _notesController = TextEditingController();
  bool _saving = false;

  static const _types = [
    ['Gym', 'G', 'gym'],
    ['Yoga', 'Y', 'yoga'],
    ['Sport', 'S', 'sport'],
    ['Run', 'R', 'run'],
    ['Cycle', 'C', 'cycle'],
  ];

  static const _durations = [15, 30, 45, 60, 90];
  static const _intensityLabels = ['Low', 'Medium', 'High'];
  static const _intensityCalMult = [4, 6, 8];

  int get _estimatedCalories =>
      (_durationMinutes * _intensityCalMult[_intensityIndex]).round();

  String get _intensityLabel => _intensityLabels[_intensityIndex];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) _activityType = widget.initialType!;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await Supabase.instance.client.from('activities').insert({
        'user_id': userId,
        'activity_type': _activityType,
        'duration_minutes': _durationMinutes,
        'intensity': _intensityLabel.toLowerCase(),
        'calories_burned': _estimatedCalories,
        'notes':
            _notesController.text.isEmpty ? null : _notesController.text,
        'date': today,
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text('Log session',
                      style: AppTheme.label(14, color: Colors.white)),
                ]),
                GestureDetector(
                  onTap: _save,
                  child: Text('Save',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _types.map((t) {
                          final isSelected = _activityType == t[2];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _activityType = t[2]),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.voltLime
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.voltLime
                                      : AppTheme.border,
                                ),
                              ),
                              child: Text(
                                '${t[1]} ${t[0]}',
                                style: AppTheme.label(12).copyWith(
                                  color: isSelected
                                      ? AppTheme.bg
                                      : AppTheme.ink2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Duration box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Duration',
                              style:
                                  AppTheme.label(11, color: AppTheme.ink2)),
                          Text('$_durationMinutes Min',
                              style:
                                  AppTheme.bigNum(44, color: AppTheme.voltLime)
                                      .copyWith(height: 1.1)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _durations.map((d) {
                              final isSelected = _durationMinutes == d;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _durationMinutes = d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.voltLime
                                            .withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.voltLime
                                          : AppTheme.border,
                                    ),
                                  ),
                                  child: Text('${d}m',
                                      style: AppTheme.label(12).copyWith(
                                        color: isSelected
                                            ? AppTheme.voltLime
                                            : AppTheme.ink2,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Intensity + Calories row
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() =>
                              _intensityIndex =
                                  (_intensityIndex + 1) % 3),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Intensity',
                                    style: AppTheme.label(11,
                                        color: AppTheme.ink2)),
                                const SizedBox(height: 2),
                                Text(
                                  '$_intensityLabel ★',
                                  style: AppTheme.label(14, color: Colors.white)
                                      .copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Calories',
                                  style: AppTheme.label(11,
                                      color: AppTheme.ink2)),
                              const SizedBox(height: 2),
                              Text('~ $_estimatedCalories',
                                  style:
                                      AppTheme.label(14, color: Colors.white)
                                          .copyWith(
                                              fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Notes
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes (optional)',
                              style: AppTheme.label(11, color: AppTheme.ink2)),
                          TextField(
                            controller: _notesController,
                            style: AppTheme.bigNum(16),
                            maxLines: 2,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Chest + triceps · felt strong',
                              hintStyle: TextStyle(
                                color: AppTheme.ink3,
                                fontFamily: 'BigShouldersDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.only(top: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Challenge link box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.voltLime.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Earns toward "Gym 4x/week" challenge',
                            style: AppTheme.label(12, color: AppTheme.ink2),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.voltLime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('+40 ¢',
                                style: AppTheme.bigNum(11,
                                    color: AppTheme.voltLime)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.amber.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.amber),
                        )
                      : Text(
                          'Save session →',
                          style: AppTheme.label(14, color: AppTheme.amber)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
