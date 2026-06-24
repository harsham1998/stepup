// stepup/lib/features/gym/screens/edit_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import '../providers/gym_provider.dart';

class EditScheduleScreen extends ConsumerStatefulWidget {
  const EditScheduleScreen({super.key});

  @override
  ConsumerState<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends ConsumerState<EditScheduleScreen> {
  // Workout plans ordered Mon(0)…Sun(6) — slot position = day index
  List<WorkoutPlan?> _slots = List.filled(7, null);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // day_of_week for each slot index: Mon=1,Tue=2,...,Sat=6,Sun=0
  static const _dowOrder = [1, 2, 3, 4, 5, 6, 0];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final week = await ref.read(gymWeekProvider.future);
      final slots = _dowOrder.map((dow) {
        final day = week.firstWhere((d) => d.dayOfWeek == dow, orElse: () => week.first);
        return day.plan;
      }).toList();
      if (mounted) setState(() { _slots = slots; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final schedule = <String, String>{};
      for (var i = 0; i < _slots.length; i++) {
        final plan = _slots[i];
        if (plan != null) schedule[_dowOrder[i].toString()] = plan.id;
      }
      await ApiClient.instance.put('/gym/user-schedule', {'schedule': schedule});
      ref.invalidate(gymWeekProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Edit Schedule',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              if (!_loading)
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _saving ? AppTheme.surface3 : AppTheme.voltLime,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Save',
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Hold and drag to move workouts to different days',
              style: AppTheme.label(12, color: AppTheme.ink2)),
          ),
          const SizedBox(height: 4),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
            ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.voltLime)))
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: _slots.length,
                proxyDecorator: (child, _, _anim) => Material(
                  color: Colors.transparent,
                  child: child,
                ),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _slots.removeAt(oldIndex);
                    _slots.insert(newIndex, item);
                  });
                },
                itemBuilder: (_, i) {
                  final plan = _slots[i];
                  return _ScheduleSlot(
                    key: ValueKey('slot_$i'),
                    dayName: _dayNames[i],
                    plan: plan,
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _ScheduleSlot extends StatelessWidget {
  final String dayName;
  final WorkoutPlan? plan;

  const _ScheduleSlot({super.key, required this.dayName, required this.plan});

  Color _color() {
    if (plan == null || plan!.isRest) return AppTheme.ink3;
    return switch (plan!.slug) {
      'push_a' || 'push_b' => AppTheme.blue,
      'pull_a' || 'pull_b' => AppTheme.green,
      'legs' => AppTheme.amber,
      'cardio' => AppTheme.pink,
      _ => AppTheme.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final planName = plan?.name ?? 'Rest';
    final muscles = plan?.muscleGroups ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Day label
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
          ),
          child: Center(
            child: Text(dayName,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
        // Plan info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(planName,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              if (muscles.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(muscles.join(' · '),
                  style: AppTheme.label(11, color: AppTheme.ink2)),
              ],
            ]),
          ),
        ),
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Icon(Icons.drag_handle_rounded, color: AppTheme.ink3, size: 20),
        ),
      ]),
    );
  }
}
