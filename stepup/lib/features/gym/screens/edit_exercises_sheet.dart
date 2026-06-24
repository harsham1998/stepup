// stepup/lib/features/gym/screens/edit_exercises_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import '../providers/gym_provider.dart';

// ── Exercise Search Sheet ─────────────────────────────────────────────────────

class ExerciseSearchSheet extends ConsumerStatefulWidget {
  final void Function(MasterExercise) onAdd;
  final Set<String> existingNames;

  const ExerciseSearchSheet({
    super.key,
    required this.onAdd,
    required this.existingNames,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(MasterExercise) onAdd,
    required Set<String> existingNames,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseSearchSheet(onAdd: onAdd, existingNames: existingNames),
    );
  }

  @override
  ConsumerState<ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends ConsumerState<ExerciseSearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _filterCategory = 'all';

  static const _categories = ['all', 'push', 'pull', 'legs', 'core', 'cardio'];

  List<MasterExercise> get _filtered {
    return masterExercises.where((e) {
      final matchQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase()) ||
          e.targetMuscles.any((m) => m.toLowerCase().contains(_query.toLowerCase()));
      final matchCat = _filterCategory == 'all' || e.category == _filterCategory;
      return matchQuery && matchCat;
    }).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.ink3, borderRadius: BorderRadius.circular(2))),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Expanded(
                child: Text('Add Exercise',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: AppTheme.ink2, size: 20),
              ),
            ]),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: AppTheme.ink3, size: 18),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search exercises or muscles…',
                    hintStyle: TextStyle(color: AppTheme.ink3),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                )),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                    child: const Icon(Icons.clear_rounded, color: AppTheme.ink3, size: 16),
                  ),
              ]),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _categories.map((cat) {
                final selected = _filterCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _filterCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.voltLime.withValues(alpha: 0.15) : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.voltLime.withValues(alpha: 0.5) : AppTheme.border),
                    ),
                    child: Text(cat == 'all' ? 'All' : cat[0].toUpperCase() + cat.substring(1),
                      style: AppTheme.label(12,
                        color: selected ? AppTheme.voltLime : AppTheme.ink2)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Exercise list
          Expanded(
            child: exercises.isEmpty
                ? Center(child: Text('No exercises found',
                    style: AppTheme.label(14, color: AppTheme.ink3)))
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: exercises.length,
                    itemBuilder: (_, i) {
                      final ex = exercises[i];
                      final already = widget.existingNames.contains(ex.name);
                      return _SearchResultRow(
                        exercise: ex,
                        alreadyAdded: already,
                        onAdd: already ? null : () {
                          widget.onAdd(ex);
                          setState(() {}); // refresh "already added" state
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  final MasterExercise exercise;
  final bool alreadyAdded;
  final VoidCallback? onAdd;

  const _SearchResultRow({
    required this.exercise,
    required this.alreadyAdded,
    required this.onAdd,
  });

  Color _catColor() => switch (exercise.category) {
        'push' => AppTheme.blue,
        'pull' => AppTheme.green,
        'legs' => AppTheme.amber,
        'core' => AppTheme.voltLime,
        'cardio' => AppTheme.pink,
        _ => AppTheme.ink2,
      };

  @override
  Widget build(BuildContext context) {
    final color = _catColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Category dot
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Row(children: [
            Text(exercise.targetMuscles.take(2).join(', '),
              style: AppTheme.label(11, color: AppTheme.ink2)),
            const SizedBox(width: 6),
            Text('· ${exercise.equipment}',
              style: AppTheme.label(11, color: AppTheme.ink3)),
          ]),
        ])),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: alreadyAdded
                  ? AppTheme.surface3
                  : AppTheme.voltLime.withValues(alpha: 0.15),
              border: Border.all(
                color: alreadyAdded
                    ? AppTheme.ink3
                    : AppTheme.voltLime.withValues(alpha: 0.5)),
            ),
            child: Icon(
              alreadyAdded ? Icons.check_rounded : Icons.add_rounded,
              color: alreadyAdded ? AppTheme.ink3 : AppTheme.voltLime,
              size: 16,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Edit Exercises Sheet ──────────────────────────────────────────────────────

class EditExercisesSheet extends ConsumerStatefulWidget {
  final WorkoutPlan plan;

  const EditExercisesSheet({super.key, required this.plan});

  static Future<bool?> show(BuildContext context, WorkoutPlan plan) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExercisesSheet(plan: plan),
    );
  }

  @override
  ConsumerState<EditExercisesSheet> createState() => _EditExercisesSheetState();
}

class _EditExercisesSheetState extends ConsumerState<EditExercisesSheet> {
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editExercisesProvider.notifier).load(widget.plan.id);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(editExercisesProvider.notifier).save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(editExercisesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.ink3, borderRadius: BorderRadius.circular(2))),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Edit Exercises',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(widget.plan.name, style: AppTheme.label(12, color: AppTheme.ink2)),
              ])),
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

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text('Hold and drag to reorder · tap sets to adjust',
              style: AppTheme.label(11, color: AppTheme.ink3)),
          ),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.red))),
              data: (exercises) => Column(children: [
                Expanded(
                  child: exercises.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.fitness_center_rounded, color: AppTheme.ink3, size: 40),
                          const SizedBox(height: 12),
                          Text('No exercises — add some below',
                            style: AppTheme.label(14, color: AppTheme.ink3)),
                        ]))
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          proxyDecorator: (child, _, _anim) =>
                              Material(color: Colors.transparent, child: child),
                          itemCount: exercises.length,
                          onReorder: (oldIdx, newIdx) {
                            ref.read(editExercisesProvider.notifier).reorder(oldIdx, newIdx);
                          },
                          itemBuilder: (_, i) {
                            final ex = exercises[i];
                            return _EditableExerciseRow(
                              key: ValueKey(ex.id),
                              exercise: ex,
                              onDelete: () =>
                                  ref.read(editExercisesProvider.notifier).remove(ex.id),
                              onSetsChanged: (v) =>
                                  ref.read(editExercisesProvider.notifier).updateSets(ex.id, v),
                            );
                          },
                        ),
                ),

                // Add exercise button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: GestureDetector(
                    onTap: () {
                      final existing = (exercisesAsync.value ?? []).map((e) => e.name).toSet();
                      ExerciseSearchSheet.show(
                        context,
                        existingNames: existing,
                        onAdd: (master) =>
                            ref.read(editExercisesProvider.notifier).add(master),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.voltLime.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.voltLime, size: 18),
                        const SizedBox(width: 8),
                        Text('Add Exercise',
                          style: AppTheme.label(14, color: AppTheme.voltLime)),
                      ]),
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
}

class _EditableExerciseRow extends StatelessWidget {
  final EditableExercise exercise;
  final VoidCallback onDelete;
  final void Function(int) onSetsChanged;

  const _EditableExerciseRow({
    super.key,
    required this.exercise,
    required this.onDelete,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Drag handle
        const Icon(Icons.drag_handle_rounded, color: AppTheme.ink3, size: 20),
        const SizedBox(width: 10),

        // Exercise info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(exercise.targetMuscles.take(2).join(', '),
            style: AppTheme.label(11, color: AppTheme.ink2)),
        ])),

        // Sets counter
        Row(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => onSetsChanged(exercise.sets - 1),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.remove_rounded, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text('${exercise.sets}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onSetsChanged(exercise.sets + 1),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 6),
          Text('sets', style: AppTheme.label(11, color: AppTheme.ink3)),
        ]),

        const SizedBox(width: 10),

        // Delete
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 20),
        ),
      ]),
    );
  }
}
