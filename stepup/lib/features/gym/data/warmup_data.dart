// stepup/lib/features/gym/data/warmup_data.dart

class WarmupItem {
  final String name;
  final String dosage; // "30 sec" / "15 reps each side" etc.

  const WarmupItem(this.name, this.dosage);
}

class WorkoutPhases {
  final List<WarmupItem> warmup;
  final List<WarmupItem> cooldown;

  const WorkoutPhases({required this.warmup, required this.cooldown});
}

const workoutPhases = <String, WorkoutPhases>{
  // ── Monday: Chest Power ──────────────────────────────────────────────────
  'push_a': WorkoutPhases(
    warmup: [
      WarmupItem('Band Pull-Aparts', '15 reps'),
      WarmupItem('Arm Circles', '20 reps each direction'),
      WarmupItem('Push-up Warm-up', '10 reps, bodyweight only'),
      WarmupItem('Shoulder External Rotation', '15 reps each side'),
    ],
    cooldown: [
      WarmupItem('Doorway Chest Stretch', '45 sec each side'),
      WarmupItem('Tricep Overhead Stretch', '30 sec each arm'),
      WarmupItem('Cross-body Shoulder Stretch', '30 sec each arm'),
      WarmupItem("Child's Pose", '60 sec'),
    ],
  ),

  // ── Tuesday: Back & Biceps ───────────────────────────────────────────────
  'pull_a': WorkoutPhases(
    warmup: [
      WarmupItem('Cat-Cow', '10 reps'),
      WarmupItem('Scapular Retractions', '15 reps'),
      WarmupItem('Dead Hang', '20 sec'),
      WarmupItem('Band Pull-Aparts', '15 reps'),
    ],
    cooldown: [
      WarmupItem('Lat Doorway Stretch', '30 sec each side'),
      WarmupItem('Standing Bicep Wall Stretch', '30 sec each arm'),
      WarmupItem('Upper Back Foam Roll', '60 sec'),
      WarmupItem("Child's Pose", '60 sec'),
    ],
  ),

  // ── Wednesday: Leg Day ───────────────────────────────────────────────────
  'legs': WorkoutPhases(
    warmup: [
      WarmupItem('Hip Circles', '10 each way'),
      WarmupItem('Leg Swings', '15 each leg'),
      WarmupItem('Bodyweight Squat', '15 reps'),
      WarmupItem('Walking Lunges', '10 each leg'),
    ],
    cooldown: [
      WarmupItem('Standing Quad Stretch', '30 sec each leg'),
      WarmupItem('Seated Hamstring Stretch', '30 sec each leg'),
      WarmupItem('Hip Flexor Kneeling Stretch', '45 sec each side'),
      WarmupItem('Pigeon Pose', '60 sec each side'),
    ],
  ),

  // ── Thursday: Upper Push ─────────────────────────────────────────────────
  'push_b': WorkoutPhases(
    warmup: [
      WarmupItem('Arm Circles', '20 reps each direction'),
      WarmupItem('Shoulder Pendulum Swings', '15 each arm'),
      WarmupItem('Band Pull-Aparts', '15 reps'),
      WarmupItem('Pike Push-up', '10 reps'),
    ],
    cooldown: [
      WarmupItem('Cross-body Shoulder Stretch', '30 sec each arm'),
      WarmupItem('Overhead Tricep Stretch', '30 sec each arm'),
      WarmupItem('Neck Side Stretch', '30 sec each side'),
      WarmupItem('Doorway Chest Stretch', '45 sec'),
    ],
  ),

  // ── Friday: Pull Strength ────────────────────────────────────────────────
  'pull_b': WorkoutPhases(
    warmup: [
      WarmupItem('Thoracic Rotations', '10 each side'),
      WarmupItem('Cat-Cow', '10 reps'),
      WarmupItem('Scapular Push-ups', '10 reps'),
      WarmupItem('Dead Hang', '20 sec'),
    ],
    cooldown: [
      WarmupItem('Lat Overhead Stretch', '30 sec each side'),
      WarmupItem('Bicep Wall Stretch', '30 sec each arm'),
      WarmupItem('Foam Roll Thoracic Spine', '60 sec'),
      WarmupItem('Seated Forward Fold', '60 sec'),
    ],
  ),

  // ── Saturday: Cardio Burn ────────────────────────────────────────────────
  'cardio': WorkoutPhases(
    warmup: [
      WarmupItem('Light Jog in Place', '2 min'),
      WarmupItem('High Knees', '30 sec'),
      WarmupItem('Jumping Jacks', '30 sec'),
      WarmupItem('Hip Swings', '15 each leg'),
    ],
    cooldown: [
      WarmupItem('Easy Walking', '2 min'),
      WarmupItem('Standing Quad Stretch', '30 sec each leg'),
      WarmupItem('Calf Stretch Against Wall', '30 sec each leg'),
      WarmupItem('Deep Breathing', '1 min'),
    ],
  ),
};
