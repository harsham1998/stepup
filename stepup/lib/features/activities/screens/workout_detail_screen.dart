import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/health_data_provider.dart';
import '../../steps/step_sync_service.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key});
  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  late TextEditingController _notesCtrl;
  bool _saving = false;
  bool _notesDirty = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _noteKey(HealthWorkout w) => w.startTime.toIso8601String();

  Future<void> _saveNotes(HealthWorkout w) async {
    setState(() => _saving = true);
    await saveWorkoutNote(_noteKey(w), _notesCtrl.text.trim());
    if (mounted) {
      setState(() { _saving = false; _notesDirty = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(selectedWorkoutProvider);
    if (workout == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const Scaffold(backgroundColor: AppTheme.bg);
    }

    final noteKey = _noteKey(workout);
    final notesAsync = ref.watch(workoutNotesProvider(noteKey));
    notesAsync.whenData((note) {
      if (_notesCtrl.text.isEmpty && note.isNotEmpty) {
        _notesCtrl.text = note;
      }
    });

    final color = _color(workout.type);
    final icon = _icon(workout.type);
    final label = _label(workout.type);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
                Text(_fmtDate(workout.startTime),
                    style: AppTheme.label(13, color: AppTheme.ink2)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Workout hero
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(label, style: AppTheme.bigNum(22)),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmtTime(workout.startTime)} – ${_fmtTime(workout.endTime)}',
                          style: AppTheme.label(12, color: AppTheme.ink2),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Health',
                          style: AppTheme.label(9, color: AppTheme.ink2)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Stats grid
                Row(children: [
                  _StatBox(
                    label: 'Duration',
                    value: '${workout.durationMins} min',
                    icon: Icons.timer_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Calories',
                    value: workout.calories > 0
                        ? '${workout.calories} kcal'
                        : '—',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.amber,
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _StatBox(
                    label: 'Distance',
                    value: workout.distanceKm > 0
                        ? '${workout.distanceKm.toStringAsFixed(2)} km'
                        : '—',
                    icon: Icons.straighten_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Avg pace',
                    value: workout.distanceKm > 0 &&
                            workout.durationMins > 0
                        ? _pace(workout.durationMins, workout.distanceKm)
                        : '—',
                    icon: Icons.speed_rounded,
                    color: AppTheme.ink2,
                  ),
                ]),
                const SizedBox(height: 20),

                // Notes section
                Text('Notes',
                    style: AppTheme.label(13, color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _notesDirty
                            ? AppTheme.voltLime.withValues(alpha: 0.4)
                            : AppTheme.border),
                  ),
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    style: AppTheme.label(13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add notes about this session…',
                      hintStyle:
                          AppTheme.label(13, color: AppTheme.ink2),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    onChanged: (_) =>
                        setState(() => _notesDirty = true),
                  ),
                ),
                const SizedBox(height: 10),
                if (_notesDirty)
                  GestureDetector(
                    onTap: () => _saveNotes(workout),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.voltLime.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.voltLime))
                            : Text('Save notes',
                                style: AppTheme.label(13,
                                        color: AppTheme.voltLime)
                                    .copyWith(
                                        fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static String _pace(int mins, double km) {
    if (km <= 0) return '—';
    final secPerKm = (mins * 60 / km).round();
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).toString().padLeft(2, '0');
    return "$m'$s\" /km";
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $amPm';
  }

  static Color _color(String type) {
    final t = type.toLowerCase();
    if (t.contains('yoga') || t.contains('mind')) return const Color(0xFF818CF8);
    if (t.contains('run') || t.contains('walk')) return AppTheme.voltLime;
    if (t.contains('cycl')) return const Color(0xFF38BDF8);
    return AppTheme.amber;
  }

  static IconData _icon(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return Icons.directions_run_rounded;
    if (t.contains('walk')) return Icons.directions_walk_rounded;
    if (t.contains('cycl') || t.contains('bike')) return Icons.directions_bike_rounded;
    if (t.contains('swim')) return Icons.pool_rounded;
    if (t.contains('yoga') || t.contains('mindful')) return Icons.self_improvement_rounded;
    return Icons.fitness_center_rounded;
  }

  static String _label(String type) {
    final t = type.toLowerCase();
    if (t.contains('traditional_strength') || t.contains('strength_training')) return 'Strength Training';
    if (t.contains('functional')) return 'Functional Training';
    if (t.contains('high_intensity')) return 'HIIT';
    if (t.contains('running')) return 'Running';
    if (t.contains('walking')) return 'Walking';
    if (t.contains('cycling')) return 'Cycling';
    if (t.contains('swimming')) return 'Swimming';
    if (t.contains('yoga')) return 'Yoga';
    if (t.contains('mind')) return 'Mindfulness';
    return type.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(value,
                style: AppTheme.bigNum(22, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTheme.label(10, color: AppTheme.ink2)),
          ]),
        ),
      );
}
