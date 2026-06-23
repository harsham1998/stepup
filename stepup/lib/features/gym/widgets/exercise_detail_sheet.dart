// stepup/lib/features/gym/widgets/exercise_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import 'muscle_diagram.dart';

// ── Exercise metadata ─────────────────────────────────────────────────────────

class _ExerciseMeta {
  final List<String> steps;
  final String tip;
  const _ExerciseMeta({required this.steps, required this.tip});
}

const _exerciseMeta = <String, _ExerciseMeta>{
  'Machine Chest Press': _ExerciseMeta(
    steps: [
      'Adjust seat so handles are at mid-chest height. Sit tall with back flat.',
      'Grip handles slightly wider than shoulder-width, elbows at 90°.',
      'Exhale and press handles forward until arms are almost straight.',
      'Inhale and slowly return, feeling a stretch across your chest.',
      'Keep wrists neutral — do not let them bend back.',
    ],
    tip: 'Squeeze your chest at the top — don\'t just push with your arms.',
  ),
  'Incline Dumbbell Press': _ExerciseMeta(
    steps: [
      'Set bench to 30–45°. Sit back with dumbbells on your thighs.',
      'Kick dumbbells up as you lie back, holding them at chest level.',
      'Retract shoulder blades and press dumbbells up and slightly inward.',
      'Lower with control until elbows are just below bench level.',
      'Pause briefly at the bottom — don\'t bounce.',
    ],
    tip: 'Keep your arch natural — don\'t flatten your lower back.',
  ),
  'Pec Deck Fly': _ExerciseMeta(
    steps: [
      'Adjust seat so handles are at shoulder height when arms are open.',
      'Sit tall, grip handles with palms facing forward.',
      'Exhale and bring handles together in a hugging arc.',
      'Hold the contracted position for 1 second.',
      'Open slowly — control the negative for full stretch.',
    ],
    tip: 'Think "hugging a barrel" — keep a slight bend in your elbows.',
  ),
  'Machine Shoulder Press': _ExerciseMeta(
    steps: [
      'Adjust seat so handles start at ear height. Sit tall.',
      'Grip handles, elbows pointing forward (not flared).',
      'Press up explosively, stop just short of lockout.',
      'Lower slowly back to ear height — full range of motion.',
      'Keep your core braced and avoid shrugging.',
    ],
    tip: 'Press in a slight forward arc — not straight up — to protect the joint.',
  ),
  'Lateral Raise': _ExerciseMeta(
    steps: [
      'Stand with dumbbells at your sides, slight bend in elbows.',
      'Lead the lift with your pinkies — imagine pouring water from a jug.',
      'Raise until arms are parallel to the floor (shoulder height).',
      'Pause at the top for a half-second.',
      'Lower slowly — 3 seconds down — to time under tension.',
    ],
    tip: 'Lean forward 10° from the hips to target the lateral head more directly.',
  ),
  'Rope Pushdown': _ExerciseMeta(
    steps: [
      'Set cable to chest height. Grip rope with thumbs up.',
      'Tuck elbows tight to your sides — keep them there throughout.',
      'Push rope down and slightly outward, spreading at the bottom.',
      'Squeeze triceps hard at the bottom position.',
      'Let rope rise until forearms are parallel to floor — no higher.',
    ],
    tip: 'The spread at the bottom hits all three tricep heads simultaneously.',
  ),
  'Overhead Rope Extension': _ExerciseMeta(
    steps: [
      'Set cable low. Face away, grip rope overhead with elbows beside ears.',
      'Hinge at the hips slightly so rope clears your head.',
      'Extend arms forward and up until fully straight.',
      'Squeeze triceps at the top, then lower slowly.',
      'Feel the long head stretch at the bottom — that\'s the goal.',
    ],
    tip: 'Keep your ribs down — don\'t let your back arch as you extend.',
  ),
  'Lat Pulldown': _ExerciseMeta(
    steps: [
      'Grip bar just outside shoulder-width, palms facing away.',
      'Lean back slightly — about 15°. Lock thighs under the pad.',
      'Pull bar down to upper chest, driving elbows into your pockets.',
      'Hold for 1 second at the bottom — full lat contraction.',
      'Let bar rise with control until arms are fully extended.',
    ],
    tip: 'Think "elbows to hips" — not "hands to chest" — to feel your lats.',
  ),
  'Seated Cable Row': _ExerciseMeta(
    steps: [
      'Sit tall, feet flat, slight bend in knees. Grip the V-bar.',
      'Start with arms extended and back straight — no rounding.',
      'Pull handle to your lower chest, driving elbows back.',
      'Squeeze your shoulder blades together at the end.',
      'Return slowly — let your shoulder blades protract fully.',
    ],
    tip: 'Row to your belly button, not your chest — keeps the elbows in.',
  ),
  'Chest Supported Row': _ExerciseMeta(
    steps: [
      'Set bench to 30–45°. Lie chest-down, arms hanging below.',
      'Pull weight up by driving elbows high and back.',
      'Squeeze shoulder blades together at the top.',
      'Lower with full control — don\'t drop the weight.',
      'Keep chest in contact with the pad throughout.',
    ],
    tip: 'Supported position removes lower-back fatigue — go heavier safely.',
  ),
  'Face Pull': _ExerciseMeta(
    steps: [
      'Set rope at face height. Stand back, slight lean away.',
      'Pull rope toward your face, elbows high and flared.',
      'Separate the rope ends at your face — think "hands to ears".',
      'Externally rotate wrists so hands finish behind your head.',
      'Return slowly — control the cable all the way.',
    ],
    tip: 'Elbows must stay above the line of the cable — never drop them.',
  ),
  'Machine Curl': _ExerciseMeta(
    steps: [
      'Adjust pad so elbows rest at the pivot point of the machine.',
      'Grip handles with palms up, arms fully extended.',
      'Curl up in a smooth arc — don\'t rock or swing.',
      'Squeeze biceps hard at the top for 1 second.',
      'Lower slowly — a 3-second negative builds more size.',
    ],
    tip: 'Full extension at the bottom is essential — don\'t cut the range.',
  ),
  'Hammer Curl': _ExerciseMeta(
    steps: [
      'Stand with dumbbells at sides, palms facing your thighs.',
      'Keep thumbs pointing up throughout the lift.',
      'Curl one or both dumbbells up, elbow stays stationary.',
      'Squeeze at the top — feel the brachialis and forearm fire.',
      'Lower completely before the next rep.',
    ],
    tip: 'Neutral grip hits the brachialis — the muscle that makes arms look thicker.',
  ),
  'Leg Press': _ExerciseMeta(
    steps: [
      'Place feet shoulder-width, mid-platform. Toes slightly out.',
      'Release safety, lower sled until knees reach 90° (or deeper).',
      'Drive through your heels to press sled back up.',
      'Stop short of lockout — keep tension on the quads.',
      'Control the descent — 2-3 seconds down.',
    ],
    tip: 'Keep lower back flat against the pad — never let it peel off.',
  ),
  'Barbell Squat': _ExerciseMeta(
    steps: [
      'Bar rests on traps (high bar) or rear delts (low bar). Feet shoulder-width.',
      'Brace core hard — 360° pressure around your torso.',
      'Break at the hips and knees simultaneously, tracking knees over toes.',
      'Descend until thighs are parallel or below.',
      'Drive through the floor to stand — hips and chest rise together.',
    ],
    tip: 'Push your knees out — don\'t let them cave inward on the way up.',
  ),
  'Romanian Deadlift': _ExerciseMeta(
    steps: [
      'Start standing, bar at hip level. Soft bend in knees, flat back.',
      'Push hips back as bar slides down your thighs.',
      'Lower until you feel a strong hamstring stretch (usually just below the knee).',
      'Drive hips forward to stand — squeeze glutes at the top.',
      'Keep bar close to your body the entire movement.',
    ],
    tip: 'This is a hip hinge, not a squat — minimal knee bend, maximum hip travel.',
  ),
  'Leg Curl': _ExerciseMeta(
    steps: [
      'Lie face down, pad rests just above your heels.',
      'Curl feet toward your glutes in a smooth arc.',
      'Squeeze hard at the top — hamstrings fully contracted.',
      'Lower slowly — 3-4 seconds — for maximum tension.',
      'Hips stay flat on the pad — no lifting.',
    ],
    tip: 'Plantar-flex (point toes) at the top to get an extra squeeze.',
  ),
  'Leg Extension': _ExerciseMeta(
    steps: [
      'Sit tall, pad rests on your lower shins just above the ankle.',
      'Extend legs until they are nearly straight — full contraction.',
      'Hold at the top for 1 second — quad burn is the goal.',
      'Lower slowly — resist the weight on the way down.',
      'Don\'t swing or use momentum.',
    ],
    tip: 'Point toes slightly inward to emphasize the vastus medialis (inner quad).',
  ),
  'Standing Calf Raise': _ExerciseMeta(
    steps: [
      'Stand with toes on the edge of a step or plate for full range.',
      'Hold weight or use machine — straight legs, slight knee softness.',
      'Rise as high as possible — maximum plantar-flexion.',
      'Pause at the top for 1 full second.',
      'Lower slowly until heels are below the platform level.',
    ],
    tip: 'Full range — all the way up and all the way down — is what makes calves grow.',
  ),
  'Plank': _ExerciseMeta(
    steps: [
      'Start in push-up position, then drop to forearms.',
      'Elbows directly under shoulders, forearms parallel.',
      'Squeeze every muscle: quads, glutes, abs, fists.',
      'Keep hips level — don\'t pike up or sag down.',
      'Breathe steadily. Eyes focused on the floor.',
    ],
    tip: 'If your hips sag, stop the set — quality beats time every time.',
  ),
};


// ── Main Sheet ────────────────────────────────────────────────────────────────

class ExerciseDetailSheet extends StatefulWidget {
  final PlanExercise exercise;

  const ExerciseDetailSheet({super.key, required this.exercise});

  static Future<void> show(BuildContext context, PlanExercise exercise) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _stepAnim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeInOut);
    _stepAnim.forward();
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final meta = _exerciseMeta[widget.exercise.name];
    if (meta == null) return;
    if (step < 0 || step >= meta.steps.length) return;
    _stepAnim.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentStep = step);
      _stepAnim.forward();
    });
  }

  Color _muscleColor(String muscle) {
    if ({'chest', 'upper-chest', 'lower-chest'}.contains(muscle)) return AppTheme.blue;
    if ({'lats', 'back', 'mid-back', 'upper-back', 'rear-delt'}.contains(muscle)) return AppTheme.green;
    if ({'quads', 'hamstrings', 'glutes', 'calves'}.contains(muscle)) return AppTheme.amber;
    if ({'shoulders', 'side-delt', 'front-delt'}.contains(muscle)) return AppTheme.purple;
    if ({'biceps', 'brachialis', 'triceps', 'long-head-triceps'}.contains(muscle)) return AppTheme.pink;
    if ({'core', 'abs'}.contains(muscle)) return AppTheme.voltLime;
    return AppTheme.ink2;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _exerciseMeta[widget.exercise.name];
    final steps = meta?.steps ?? ['Perform the exercise with controlled form and full range of motion.'];
    final tip = meta?.tip;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.ink3, borderRadius: BorderRadius.circular(2))),
          ),

          Expanded(
            child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [

              // Title row
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.exercise.name, style: AppTheme.bigNum(22)),
                  const SizedBox(height: 4),
                  Text('${widget.exercise.sets} sets · ${widget.exercise.repsLabel} ${widget.exercise.repsLabel.endsWith("s") ? "sec" : "reps"}',
                    style: AppTheme.label(13, color: AppTheme.ink2)),
                ])),
                _EquipmentBadge(equipment: widget.exercise.equipment),
              ]),
              const SizedBox(height: 12),

              // Muscle tags
              Wrap(spacing: 6, runSpacing: 6, children: [
                ...widget.exercise.targetMuscles.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _muscleColor(m).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _muscleColor(m).withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _muscleColor(m))),
                    const SizedBox(width: 5),
                    Text(m, style: AppTheme.label(11, color: _muscleColor(m))),
                  ]),
                )),
              ]),
              const SizedBox(height: 20),

              // Muscle targeting diagram + YouTube button
              _MuscleCard(
                exercise: widget.exercise,
                muscleColor: _muscleColor(
                  widget.exercise.targetMuscles.isNotEmpty
                      ? widget.exercise.targetMuscles.first
                      : 'chest',
                ),
              ),
              const SizedBox(height: 20),

              // Step-by-step instructions
              Text('HOW TO PERFORM', style: AppTheme.label(11, color: AppTheme.ink3)),
              const SizedBox(height: 10),

              // Step navigator
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ...List.generate(steps.length, (i) => GestureDetector(
                  onTap: () => _goToStep(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentStep ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentStep ? AppTheme.voltLime : AppTheme.ink3,
                    ),
                  ),
                )),
              ]),
              const SizedBox(height: 14),

              // Animated step content
              FadeTransition(
                opacity: _fade,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.voltLime.withOpacity(0.15),
                          border: Border.all(color: AppTheme.voltLime.withOpacity(0.4)),
                        ),
                        child: Center(child: Text(
                          '${_currentStep + 1}',
                          style: AppTheme.label(13, color: AppTheme.voltLime),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        steps[_currentStep],
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                      )),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // Prev / Next buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: _currentStep > 0 ? () => _goToStep(_currentStep - 1) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentStep > 0 ? AppTheme.surface3 : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.chevron_left_rounded,
                        color: _currentStep > 0 ? Colors.white : AppTheme.ink3, size: 18),
                      const SizedBox(width: 4),
                      Text('Prev', style: AppTheme.label(13,
                        color: _currentStep > 0 ? Colors.white : AppTheme.ink3)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: _currentStep < steps.length - 1 ? () => _goToStep(_currentStep + 1) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentStep < steps.length - 1 ? AppTheme.voltLime.withOpacity(0.15) : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentStep < steps.length - 1 ? AppTheme.voltLime.withOpacity(0.4) : AppTheme.border),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Next', style: AppTheme.label(13,
                        color: _currentStep < steps.length - 1 ? AppTheme.voltLime : AppTheme.ink3)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                        color: _currentStep < steps.length - 1 ? AppTheme.voltLime : AppTheme.ink3, size: 18),
                    ]),
                  ),
                )),
              ]),

              // Pro tip
              if (tip != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.amber.withOpacity(0.25)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('💡', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PRO TIP', style: AppTheme.label(10, color: AppTheme.amber)),
                      const SizedBox(height: 3),
                      Text(tip, style: AppTheme.label(13, color: Colors.white)),
                    ])),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Muscle targeting card ─────────────────────────────────────────────────────

class _MuscleCard extends StatelessWidget {
  final PlanExercise exercise;
  final Color muscleColor;

  const _MuscleCard({required this.exercise, required this.muscleColor});

  @override
  Widget build(BuildContext context) {
    final muscles = exercise.targetMuscles;
    final bool isBackExercise = muscles.any(
      (m) => const {'lats', 'back', 'mid-back', 'upper-back', 'rear-delt',
                    'hamstrings', 'glutes'}.contains(m),
    );

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // Muscle diagram filling the card
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: MuscleDiagram(
              primaryMuscles: muscles,
              primaryColor: muscleColor,
            ),
          ),
        ),

        // Label badge
        Positioned(
          top: 10, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.60),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isBackExercise ? 'MUSCLES · FRONT & BACK' : 'MUSCLE TARGET',
              style: AppTheme.label(9, color: Colors.white70),
            ),
          ),
        ),

        // YouTube button
        Positioned(
          bottom: 10, right: 10,
          child: GestureDetector(
            onTap: () {
              final query = Uri.encodeComponent('${exercise.name} exercise form tutorial');
              final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('Watch Form', style: AppTheme.label(11, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Equipment badge ───────────────────────────────────────────────────────────

class _EquipmentBadge extends StatelessWidget {
  final String equipment;
  const _EquipmentBadge({required this.equipment});

  IconData get _icon {
    switch (equipment) {
      case 'barbell': return Icons.sports_gymnastics;
      case 'dumbbell': return Icons.fitness_center_rounded;
      case 'cable': return Icons.cable_rounded;
      case 'bodyweight': return Icons.accessibility_new_rounded;
      default: return Icons.precision_manufacturing_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.surface3,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, color: AppTheme.ink2, size: 14),
      const SizedBox(width: 5),
      Text(equipment, style: AppTheme.label(11, color: AppTheme.ink2)),
    ]),
  );
}
