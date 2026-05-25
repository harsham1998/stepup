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
  String _intensity = 'high';
  final _notesController = TextEditingController();
  bool _saving = false;

  static const _types = [
    ['Gym', 'gym'],
    ['Yoga', 'yoga'],
    ['Sport', 'sport'],
    ['Run', 'run'],
    ['Cycle', 'cycle'],
  ];

  static const _durations = [15, 30, 45, 60, 90];
  static const _intensities = ['low', 'medium', 'high'];

  int get _estimatedCalories {
    const base = {'low': 4, 'medium': 6, 'high': 8};
    return (_durationMinutes * (base[_intensity] ?? 6)).round();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _activityType = widget.initialType!;
    }
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
        'intensity': _intensity,
        'calories_burned': _estimatedCalories,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
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
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text('Log session', style: AppTheme.label(16, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600)),
                ]),
                GestureDetector(
                  onTap: _save,
                  child: Text('Save',
                      style: AppTheme.label(14, color: _saving ? AppTheme.ink3 : AppTheme.voltLime)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity type chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _types.map((t) {
                        final isSelected = _activityType == t[1];
                        return GestureDetector(
                          onTap: () => setState(() => _activityType = t[1]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.voltLime
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? AppTheme.voltLime
                                      : AppTheme.border),
                            ),
                            child: Text(
                              t[0],
                              style: AppTheme.label(12).copyWith(
                                color: isSelected ? AppTheme.bg : AppTheme.ink2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration',
                            style: AppTheme.label(11, color: AppTheme.ink3)),
                        const SizedBox(height: 4),
                        Text('$_durationMinutes Min',
                            style: AppTheme.bigNum(44, color: AppTheme.voltLime)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _durations.map((d) {
                            final isSelected = _durationMinutes == d;
                            return GestureDetector(
                              onTap: () => setState(() => _durationMinutes = d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.voltLime.withValues(alpha: 0.15)
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
                  const SizedBox(height: 12),

                  // Intensity + Calories row
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Intensity',
                                style: AppTheme.label(11, color: AppTheme.ink3)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _intensities.map((ins) {
                                final isSelected = _intensity == ins;
                                return GestureDetector(
                                  onTap: () => setState(() => _intensity = ins),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.voltLime.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ins[0].toUpperCase() + ins.substring(1),
                                      style: AppTheme.label(11).copyWith(
                                        color: isSelected
                                            ? AppTheme.voltLime
                                            : AppTheme.ink2,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Calories',
                                style: AppTheme.label(11, color: AppTheme.ink3)),
                            const SizedBox(height: 4),
                            Text('~ $_estimatedCalories',
                                style: AppTheme.label(18, color: Colors.white)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Notes
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes (optional)',
                            style: AppTheme.label(11, color: AppTheme.ink3)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          style: AppTheme.bigNum(16),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. Chest + triceps · felt strong',
                            hintStyle: TextStyle(
                              color: AppTheme.ink3,
                              fontFamily: 'Inter',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Coins preview banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.voltLime.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Earns toward active challenges',
                            style: AppTheme.label(12, color: AppTheme.ink2)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.voltLime.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('+40 ¢',
                              style: AppTheme.bigNum(12, color: AppTheme.voltLime)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.bg))
                          : const Text('Save session →'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
