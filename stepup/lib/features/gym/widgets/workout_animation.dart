// stepup/lib/features/gym/widgets/workout_animation.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gym_plan.dart';

// ── Category enum ─────────────────────────────────────────────────────────────

enum WorkoutCategory {
  chestPress,
  backRow,
  shoulderPress,
  squat,
  hamstring,
  curl,
  tricep,
  calfRaise,
  plank,
  cardio,
  legExtension,
}

// ── Widget ────────────────────────────────────────────────────────────────────

class WorkoutAnimationWidget extends StatefulWidget {
  final WorkoutCategory category;
  final Color accentColor;

  const WorkoutAnimationWidget({
    super.key,
    required this.category,
    required this.accentColor,
  });

  static WorkoutCategory categoryFor(PlanExercise exercise) {
    final n = exercise.name.toLowerCase();
    final m = exercise.targetMuscles;
    if (n.contains('plank')) return WorkoutCategory.plank;
    if (n.contains('calf')) return WorkoutCategory.calfRaise;
    if (n.contains('leg extension')) return WorkoutCategory.legExtension;
    if (n.contains('leg curl') || n.contains('romanian')) return WorkoutCategory.hamstring;
    if (n.contains('curl') || m.contains('biceps') || m.contains('brachialis')) return WorkoutCategory.curl;
    if (n.contains('squat') || n.contains('leg press')) return WorkoutCategory.squat;
    if (n.contains('pushdown') || (n.contains('extension') && m.contains('triceps'))) return WorkoutCategory.tricep;
    if (n.contains('lateral') || n.contains('shoulder press') || m.contains('side-delt')) return WorkoutCategory.shoulderPress;
    if (m.contains('chest') || m.contains('upper-chest')) return WorkoutCategory.chestPress;
    if (m.contains('lats') || m.contains('back') || m.contains('mid-back') || n.contains('row') || n.contains('pull')) return WorkoutCategory.backRow;
    if (m.contains('quads') || m.contains('hamstrings') || m.contains('glutes')) return WorkoutCategory.squat;
    return WorkoutCategory.chestPress;
  }

  @override
  State<WorkoutAnimationWidget> createState() => _WorkoutAnimationWidgetState();
}

class _WorkoutAnimationWidgetState extends State<WorkoutAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => CustomPaint(
      painter: _ExercisePainter(
        category: widget.category,
        t: _anim.value,
        accent: widget.accentColor,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ExercisePainter extends CustomPainter {
  final WorkoutCategory category;
  final double t;
  final Color accent;

  const _ExercisePainter({required this.category, required this.t, required this.accent});

  // Scale normalized 0-1 point to canvas size
  Offset _p(double x, double y, Size s) => Offset(x * s.width, y * s.height);

  Paint get _body => Paint()
    ..color = Colors.white.withOpacity(0.80)
    ..strokeWidth = 5.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Paint get _bodyThin => Paint()
    ..color = Colors.white.withOpacity(0.55)
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint _acc([double w = 6.0]) => Paint()
    ..color = accent
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Paint _glow([double a = 0.14]) => Paint()
    ..color = accent.withOpacity(a)
    ..style = PaintingStyle.fill;

  void _head(Canvas c, Offset center, double r) {
    c.drawCircle(center, r, _body..strokeWidth = 3.0);
    // minimal face dot
    c.drawCircle(
      Offset(center.dx + r * 0.28, center.dy - r * 0.1),
      r * 0.14,
      Paint()..color = Colors.white.withOpacity(0.45)..style = PaintingStyle.fill,
    );
  }

  void _joint(Canvas c, Offset p, [Color? col]) {
    c.drawCircle(
      p, 4.5,
      Paint()..color = (col ?? Colors.white).withOpacity(0.95)..style = PaintingStyle.fill,
    );
  }

  void _line(Canvas c, Offset a, Offset b, Paint p) => c.drawLine(a, b, p);

  @override
  void paint(Canvas canvas, Size size) {
    switch (category) {
      case WorkoutCategory.chestPress:   _chestPress(canvas, size);   break;
      case WorkoutCategory.backRow:      _backRow(canvas, size);       break;
      case WorkoutCategory.shoulderPress:_shoulderPress(canvas, size); break;
      case WorkoutCategory.squat:        _squat(canvas, size);         break;
      case WorkoutCategory.hamstring:    _hamstring(canvas, size);     break;
      case WorkoutCategory.curl:         _curl(canvas, size);          break;
      case WorkoutCategory.tricep:       _tricep(canvas, size);        break;
      case WorkoutCategory.calfRaise:    _calfRaise(canvas, size);     break;
      case WorkoutCategory.plank:        _plank(canvas, size);         break;
      case WorkoutCategory.cardio:       _cardio(canvas, size);        break;
      case WorkoutCategory.legExtension: _legExtension(canvas, size);  break;
    }
  }

  // ── CHEST PRESS — front view, two arms pressing forward ────────────────────
  void _chestPress(Canvas c, Size s) {
    // Muscle glow — chest
    c.drawOval(
      Rect.fromCenter(center: _p(0.50, 0.35, s), width: s.width * 0.35, height: s.height * 0.25),
      _glow(0.12 + 0.10 * t),
    );
    // Torso
    final torso = Path()
      ..moveTo(_p(0.40, 0.16, s).dx, _p(0.40, 0.16, s).dy)
      ..lineTo(_p(0.60, 0.16, s).dx, _p(0.60, 0.16, s).dy)
      ..lineTo(_p(0.58, 0.60, s).dx, _p(0.58, 0.60, s).dy)
      ..lineTo(_p(0.42, 0.60, s).dx, _p(0.42, 0.60, s).dy)
      ..close();
    c.drawPath(torso, _bodyThin);
    _head(c, _p(0.50, 0.08, s), s.width * 0.062);

    // LEFT arm: shoulder → elbow → hand (arms pull in as t→1)
    final lSh = _p(0.40, 0.22, s);
    final lEl = Offset.lerp(_p(0.20, 0.34, s), _p(0.28, 0.26, s), t)!;
    final lHd = Offset.lerp(_p(0.10, 0.46, s), _p(0.35, 0.38, s), t)!;
    _line(c, lSh, lEl, _acc()); _line(c, lEl, lHd, _acc());
    _joint(c, lEl, accent); _joint(c, lHd, accent);

    // RIGHT arm (mirrored)
    final rSh = _p(0.60, 0.22, s);
    final rEl = Offset.lerp(_p(0.80, 0.34, s), _p(0.72, 0.26, s), t)!;
    final rHd = Offset.lerp(_p(0.90, 0.46, s), _p(0.65, 0.38, s), t)!;
    _line(c, rSh, rEl, _acc()); _line(c, rEl, rHd, _acc());
    _joint(c, rEl, accent); _joint(c, rHd, accent);
  }

  // ── BACK ROW — side view, bent over, arm rowing ────────────────────────────
  void _backRow(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.48, 0.28, s), width: s.width * 0.38, height: s.height * 0.22),
      _glow(0.12 + 0.10 * t),
    );
    final hip = _p(0.54, 0.58, s);
    final neck = _p(0.34, 0.16, s);
    _line(c, hip, neck, _body); // torso
    _head(c, _p(0.29, 0.09, s), s.width * 0.055);
    // Legs
    _line(c, hip, _p(0.52, 0.80, s), _bodyThin);
    _line(c, _p(0.52, 0.80, s), _p(0.54, 0.94, s), _bodyThin);
    // Rowing arm: t=0 extended, t=1 pulled to hip
    final sh = _p(0.42, 0.26, s);
    final el = Offset.lerp(_p(0.42, 0.60, s), _p(0.60, 0.42, s), t)!;
    final hd = Offset.lerp(_p(0.42, 0.78, s), _p(0.70, 0.38, s), t)!;
    _line(c, sh, el, _acc()); _line(c, el, hd, _acc());
    _joint(c, el, accent); _joint(c, hd, accent);
    // Static support arm
    _line(c, _p(0.40, 0.28, s), _p(0.36, 0.58, s), _bodyThin);
  }

  // ── SHOULDER PRESS — front view, arms pressing overhead ────────────────────
  void _shoulderPress(Canvas c, Size s) {
    // Shoulder glow (both sides)
    c.drawCircle(_p(0.33, 0.28, s), s.width * 0.12, _glow(0.12 + 0.10 * t));
    c.drawCircle(_p(0.67, 0.28, s), s.width * 0.12, _glow(0.12 + 0.10 * t));
    final torso = Path()
      ..moveTo(_p(0.40, 0.26, s).dx, _p(0.40, 0.26, s).dy)
      ..lineTo(_p(0.60, 0.26, s).dx, _p(0.60, 0.26, s).dy)
      ..lineTo(_p(0.58, 0.65, s).dx, _p(0.58, 0.65, s).dy)
      ..lineTo(_p(0.42, 0.65, s).dx, _p(0.42, 0.65, s).dy)
      ..close();
    c.drawPath(torso, _bodyThin);
    _head(c, _p(0.50, 0.15, s), s.width * 0.062);
    // LEFT arm: t=0 at ear height, t=1 overhead
    final lSh = _p(0.40, 0.29, s);
    final lEl = Offset.lerp(_p(0.22, 0.36, s), _p(0.24, 0.16, s), t)!;
    final lHd = Offset.lerp(_p(0.18, 0.29, s), _p(0.26, 0.04, s), t)!;
    _line(c, lSh, lEl, _acc()); _line(c, lEl, lHd, _acc());
    _joint(c, lEl, accent); _joint(c, lHd, accent);
    // RIGHT arm
    final rSh = _p(0.60, 0.29, s);
    final rEl = Offset.lerp(_p(0.78, 0.36, s), _p(0.76, 0.16, s), t)!;
    final rHd = Offset.lerp(_p(0.82, 0.29, s), _p(0.74, 0.04, s), t)!;
    _line(c, rSh, rEl, _acc()); _line(c, rEl, rHd, _acc());
    _joint(c, rEl, accent); _joint(c, rHd, accent);
  }

  // ── SQUAT — side view, body lowering ──────────────────────────────────────
  void _squat(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.50, 0.66, s), width: s.width * 0.22, height: s.height * 0.30),
      _glow(0.12 + 0.10 * t),
    );
    final hipY = 0.42 + 0.22 * t;
    final hipX = 0.46 - 0.05 * t;
    final kneeX = 0.52 + 0.06 * t;
    final kneeY = 0.60 + 0.16 * t;
    final foot = _p(0.50, 0.92, s);
    final knee = _p(kneeX, kneeY, s);
    final hip = _p(hipX, hipY, s);
    final shY = hipY - 0.25 - 0.03 * t;
    final sh = _p(hipX + 0.02, shY, s);
    _line(c, foot, knee, _body);
    _line(c, knee, hip, _acc());
    _line(c, hip, sh, _body);
    _head(c, _p(hipX + 0.02, shY - 0.08, s), s.width * 0.055);
    // Arms out front for balance
    _line(c, sh, _p(hipX + 0.16, shY - 0.02 + 0.06 * t, s), _bodyThin);
    _joint(c, knee, accent); _joint(c, hip, accent);
  }

  // ── HAMSTRING / RDL — side view, hip hinge ────────────────────────────────
  void _hamstring(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.50, 0.62, s), width: s.width * 0.18, height: s.height * 0.28),
      _glow(0.12 + 0.10 * t),
    );
    // t=0: standing, t=1: fully hinged
    final lean = t * 0.60;
    const hipY0 = 0.42;
    final hipY = hipY0 + 0.14 * t;
    final hip = _p(0.50, hipY, s);
    final knee = _p(0.50, 0.68, s);
    final foot = _p(0.50, 0.92, s);
    final shX = 0.50 - math.sin(lean) * 0.24;
    final shY = hipY - math.cos(lean) * 0.26;
    final sh = _p(shX, shY, s);
    _line(c, foot, knee, _bodyThin);
    _line(c, knee, hip, _acc());
    _line(c, hip, sh, _body);
    _head(c, _p(shX - 0.02, shY - 0.08, s), s.width * 0.055);
    // Hanging arms with bar
    _line(c, sh, _p(shX + 0.04, shY + 0.20, s), _bodyThin);
    _joint(c, hip, accent); _joint(c, knee);
  }

  // ── BICEP CURL — side view, forearm curling ────────────────────────────────
  void _curl(Canvas c, Size s) {
    c.drawCircle(_p(0.50, 0.38, s), s.width * 0.14, _glow(0.12 + 0.10 * t));
    // Static body
    final sh = _p(0.50, 0.22, s);
    _line(c, sh, _p(0.50, 0.60, s), _body);
    _line(c, _p(0.50, 0.60, s), _p(0.50, 0.78, s), _bodyThin);
    _line(c, _p(0.50, 0.78, s), _p(0.50, 0.92, s), _bodyThin);
    _head(c, _p(0.50, 0.12, s), s.width * 0.055);
    // Curling arm
    final el = _p(0.50, 0.40, s);
    final angle = math.pi * 0.78 - t * math.pi * 0.54;
    final hd = el + Offset(math.cos(angle) * s.height * 0.20, math.sin(angle) * s.height * 0.20);
    _line(c, sh, el, _bodyThin);
    _line(c, el, hd, _acc());
    // Dumbbell
    c.drawCircle(hd, 8, Paint()..color = accent.withOpacity(0.90)..style = PaintingStyle.fill);
    c.drawCircle(hd, 8, _acc(2.5));
    _joint(c, el, accent);
  }

  // ── TRICEP PUSHDOWN — side view, arm pushing down ─────────────────────────
  void _tricep(Canvas c, Size s) {
    c.drawCircle(_p(0.50, 0.34, s), s.width * 0.12, _glow(0.12 + 0.10 * t));
    // Cable line
    _line(c, _p(0.50, 0.02, s), _p(0.50, 0.24, s),
      Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 2);
    final sh = _p(0.50, 0.22, s);
    _line(c, sh, _p(0.50, 0.62, s), _body);
    _line(c, _p(0.50, 0.62, s), _p(0.50, 0.80, s), _bodyThin);
    _line(c, _p(0.50, 0.80, s), _p(0.50, 0.92, s), _bodyThin);
    _head(c, _p(0.50, 0.12, s), s.width * 0.055);
    final el = _p(0.50, 0.38, s);
    // t=0: forearm bent forward, t=1: pushed down
    final angle = math.pi * 0.28 + t * math.pi * 0.48;
    final hd = el + Offset(math.cos(angle) * s.height * 0.19, math.sin(angle) * s.height * 0.19);
    _line(c, sh, el, _bodyThin);
    _line(c, el, hd, _acc());
    _joint(c, el, accent); _joint(c, hd, accent);
  }

  // ── CALF RAISE — side view, heel rising ───────────────────────────────────
  void _calfRaise(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.50, 0.82, s), width: s.width * 0.16, height: s.height * 0.18),
      _glow(0.12 + 0.10 * t),
    );
    final ankleY = 0.84 - t * 0.05;
    final heelY = 0.92 - t * 0.09;
    _line(c, _p(0.50, 0.20, s), _p(0.50, 0.55, s), _body);
    _line(c, _p(0.50, 0.55, s), _p(0.50, 0.76, s), _bodyThin);
    _line(c, _p(0.50, 0.76, s), _p(0.50, ankleY, s), _acc());
    _line(c, _p(0.50, ankleY, s), _p(0.52, heelY, s), _acc());
    _head(c, _p(0.50, 0.11, s), s.width * 0.055);
    _joint(c, _p(0.50, ankleY, s), accent);
  }

  // ── PLANK — side view horizontal, core highlighted ─────────────────────────
  void _plank(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.50, 0.50, s), width: s.width * 0.44, height: s.height * 0.18),
      _glow(0.08 + 0.10 * t),
    );
    final hd = _p(0.84, 0.44, s);
    final sh = _p(0.70, 0.48, s);
    final hip = _p(0.36, 0.50, s);
    final kn = _p(0.22, 0.52, s);
    final ft = _p(0.10, 0.55, s);
    final el = _p(0.65, 0.62, s);
    final fa = _p(0.57, 0.64, s);
    _head(c, hd, s.width * 0.055);
    _line(c, sh, hip, _acc(6.0));
    _line(c, hip, kn, _bodyThin); _line(c, kn, ft, _bodyThin);
    _line(c, sh, el, _bodyThin); _line(c, el, fa, _bodyThin);
    _joint(c, hip, accent); _joint(c, el);
    // Ground line
    _line(c, _p(0.04, 0.70, s), _p(0.75, 0.70, s),
      Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 2);
  }

  // ── CARDIO / RUNNING — side view, alternating legs ─────────────────────────
  void _cardio(Canvas c, Size s) {
    final sh = _p(0.52, 0.28, s);
    final hip = _p(0.50, 0.50, s);
    _head(c, _p(0.54, 0.13, s), s.width * 0.060);
    _line(c, sh, hip, _body);
    // Alternating legs
    final lKn = Offset.lerp(_p(0.60, 0.66, s), _p(0.37, 0.62, s), t)!;
    final lFt = Offset.lerp(_p(0.72, 0.86, s), _p(0.28, 0.82, s), t)!;
    _line(c, hip, lKn, _acc(5.5)); _line(c, lKn, lFt, _acc(5.5));
    final rKn = Offset.lerp(_p(0.37, 0.62, s), _p(0.60, 0.66, s), t)!;
    final rFt = Offset.lerp(_p(0.28, 0.82, s), _p(0.72, 0.86, s), t)!;
    _line(c, hip, rKn, _body); _line(c, rKn, rFt, _body);
    // Alternating arms
    final lHd = Offset.lerp(_p(0.38, 0.42, s), _p(0.66, 0.36, s), t)!;
    final rHd = Offset.lerp(_p(0.66, 0.36, s), _p(0.38, 0.42, s), t)!;
    _line(c, sh, lHd, _acc(4.0)); _line(c, sh, rHd, _bodyThin);
    _joint(c, lKn, accent);
  }

  // ── LEG EXTENSION — seated, side view ─────────────────────────────────────
  void _legExtension(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: _p(0.58, 0.64, s), width: s.width * 0.24, height: s.height * 0.22),
      _glow(0.12 + 0.10 * t),
    );
    // Bench
    _line(c, _p(0.18, 0.63, s), _p(0.78, 0.63, s),
      Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 3);
    final hip = _p(0.36, 0.60, s);
    final kn = _p(0.58, 0.62, s);
    // Leg extends from bent (down) to horizontal (forward)
    final ft = Offset.lerp(_p(0.58, 0.90, s), _p(0.86, 0.62, s), t)!;
    _line(c, hip, _p(0.30, 0.28, s), _body);
    _head(c, _p(0.28, 0.18, s), s.width * 0.055);
    _line(c, hip, kn, _bodyThin);
    _line(c, kn, ft, _acc());
    _joint(c, kn, accent); _joint(c, ft, accent);
  }

  @override
  bool shouldRepaint(_ExercisePainter old) => old.t != t || old.accent != accent;
}
