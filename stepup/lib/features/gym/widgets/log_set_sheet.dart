// stepup/lib/features/gym/widgets/log_set_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import '../models/gym_session.dart';

class LogSetSheet extends StatefulWidget {
  final PlanExercise exercise;
  final int setNumber;
  final SetLog? existing;
  final Future<void> Function({
    required String exerciseId,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? durationSecs,
  }) onLog;

  const LogSetSheet({
    super.key,
    required this.exercise,
    required this.setNumber,
    required this.onLog,
    this.existing,
  });

  static Future<bool> show(
    BuildContext context, {
    required PlanExercise exercise,
    required int setNumber,
    SetLog? existing,
    required Future<void> Function({
      required String exerciseId,
      required int setNumber,
      double? weightKg,
      int? reps,
      int? durationSecs,
    }) onLog,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogSetSheet(
        exercise: exercise,
        setNumber: setNumber,
        existing: existing,
        onLog: onLog,
      ),
    );
    return result ?? false;
  }

  @override
  State<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<LogSetSheet> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  bool _loading = false;

  bool get _isTimed => widget.exercise.repsLabel.endsWith('s');

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.existing?.weightKg != null ? widget.existing!.weightKg!.toStringAsFixed(1) : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.existing?.reps != null
          ? widget.existing!.reps.toString()
          : widget.existing?.durationSecs != null
              ? widget.existing!.durationSecs.toString()
              : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final weight = double.tryParse(_weightCtrl.text.trim());
      final repsVal = int.tryParse(_repsCtrl.text.trim());
      await widget.onLog(
        exerciseId: widget.exercise.id,
        setNumber: widget.setNumber,
        weightKg: weight,
        reps: _isTimed ? null : repsVal,
        durationSecs: _isTimed ? repsVal : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 4, decoration: BoxDecoration(
          color: AppTheme.ink3, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 16),

        // Title
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.exercise.name, style: AppTheme.bigNum(18)),
              const SizedBox(height: 2),
              Text(
                'Set ${widget.setNumber} of ${widget.exercise.sets} · ${widget.exercise.repsLabel} ${_isTimed ? 'sec' : 'reps'}',
                style: AppTheme.label(12, color: AppTheme.ink2),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.voltLime.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.voltLime.withOpacity(0.3)),
            ),
            child: Text('+10 XP', style: AppTheme.label(11, color: AppTheme.voltLime)),
          ),
        ]),
        const SizedBox(height: 20),

        // Weight field (skip for bodyweight)
        if (widget.exercise.equipment != 'bodyweight') ...[
          _InputField(
            label: 'Weight (kg)',
            controller: _weightCtrl,
            hint: '0.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
        ],

        // Reps / Duration field
        _InputField(
          label: _isTimed ? 'Duration (seconds)' : 'Reps completed',
          controller: _repsCtrl,
          hint: _isTimed ? '45' : widget.exercise.repsLabel,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('LOG SET'),
          ),
        ),
      ]),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({required this.label, required this.controller, required this.hint, required this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.label(12, color: AppTheme.ink2)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: hint),
            autofocus: true,
          ),
        ],
      );
}
