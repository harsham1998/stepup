// stepup/lib/features/gym/widgets/muscle_diagram.dart
import 'package:flutter/material.dart';

// Professional anatomical muscle diagram — filled body silhouette with
// colored muscle-group overlays. Matches the style seen on gym machines.

class MuscleDiagram extends StatelessWidget {
  final List<String> primaryMuscles;
  final Color primaryColor;

  const MuscleDiagram({
    super.key,
    required this.primaryMuscles,
    required this.primaryColor,
  });

  bool get _isBackExercise => primaryMuscles.any(
    (m) => const {'lats', 'back', 'mid-back', 'upper-back', 'rear-delt',
                  'hamstrings', 'glutes'}.contains(m),
  );

  @override
  Widget build(BuildContext context) {
    if (_isBackExercise) {
      return Row(children: [
        Expanded(child: _DiagramCanvas(
          view: _View.front,
          muscles: primaryMuscles,
          color: primaryColor,
          dimmed: true,
        )),
        Expanded(child: _DiagramCanvas(
          view: _View.back,
          muscles: primaryMuscles,
          color: primaryColor,
          dimmed: false,
        )),
      ]);
    }
    return _DiagramCanvas(
      view: _View.front,
      muscles: primaryMuscles,
      color: primaryColor,
      dimmed: false,
    );
  }
}

enum _View { front, back }

class _DiagramCanvas extends StatelessWidget {
  final _View view;
  final List<String> muscles;
  final Color color;
  final bool dimmed;

  const _DiagramCanvas({
    required this.view,
    required this.muscles,
    required this.color,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodyPainter(
        view: view,
        muscles: muscles,
        accentColor: color,
        dimmed: dimmed,
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final _View view;
  final List<String> muscles;
  final Color accentColor;
  final bool dimmed;

  static const _body     = Color(0xFF252538);
  static const _bodyEdge = Color(0xFF353550);
  static const _joint    = Color(0xFF2F2F48);

  const _BodyPainter({
    required this.view,
    required this.muscles,
    required this.accentColor,
    required this.dimmed,
  });

  Paint get _fill      => Paint()..color = _body;
  Paint get _jointFill => Paint()..color = _joint;
  Paint get _outline   => Paint()
    ..color = _bodyEdge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (dimmed) {
      canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withOpacity(0.25));
    }
    _drawSilhouette(canvas, size);
    _drawHighlights(canvas, size);
    if (dimmed) canvas.restore();
  }

  // ── Silhouette ─────────────────────────────────────────────────────────────

  void _drawSilhouette(Canvas c, Size s) {
    _head(c, s);
    _neck(c, s);
    _torso(c, s);
    _shoulders(c, s);
    _arms(c, s);
    _hips(c, s);
    _legs(c, s);
  }

  void _head(Canvas c, Size s) {
    final r = s.width * 0.09;
    final center = Offset(s.width * 0.5, s.height * 0.085);
    c.drawCircle(center, r, _fill);
    c.drawCircle(center, r, _outline);
  }

  void _neck(Canvas c, Size s) {
    _oval(c, s, 0.5, 0.185, 0.11, 0.065, _fill, _outline);
  }

  void _torso(Canvas c, Size s) {
    final p = Path()
      ..moveTo(s.width * 0.285, s.height * 0.225)
      ..lineTo(s.width * 0.715, s.height * 0.225)
      ..cubicTo(s.width * 0.75, s.height * 0.37,
                s.width * 0.70, s.height * 0.50,
                s.width * 0.63, s.height * 0.565)
      ..lineTo(s.width * 0.37, s.height * 0.565)
      ..cubicTo(s.width * 0.30, s.height * 0.50,
                s.width * 0.25, s.height * 0.37,
                s.width * 0.285, s.height * 0.225)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _outline);
  }

  void _shoulders(Canvas c, Size s) {
    _circle(c, s, 0.245, 0.255, 0.072, _jointFill, _outline);
    _circle(c, s, 0.755, 0.255, 0.072, _jointFill, _outline);
  }

  void _arms(Canvas c, Size s) {
    // Upper arms
    _oval(c, s, 0.19, 0.365, 0.10, 0.215, _fill, _outline);
    _oval(c, s, 0.81, 0.365, 0.10, 0.215, _fill, _outline);
    // Elbow joint
    _circle(c, s, 0.19, 0.450, 0.044, _jointFill, _outline);
    _circle(c, s, 0.81, 0.450, 0.044, _jointFill, _outline);
    // Forearms
    _oval(c, s, 0.175, 0.540, 0.09, 0.18, _fill, _outline);
    _oval(c, s, 0.825, 0.540, 0.09, 0.18, _fill, _outline);
    // Hands
    _oval(c, s, 0.165, 0.635, 0.08, 0.055, _fill, null);
    _oval(c, s, 0.835, 0.635, 0.08, 0.055, _fill, null);
  }

  void _hips(Canvas c, Size s) {
    _oval(c, s, 0.5, 0.59, 0.32, 0.065, _fill, _outline);
  }

  void _legs(Canvas c, Size s) {
    // Thighs
    _oval(c, s, 0.41, 0.72, 0.135, 0.24, _fill, _outline);
    _oval(c, s, 0.59, 0.72, 0.135, 0.24, _fill, _outline);
    // Knee joints
    _circle(c, s, 0.41, 0.825, 0.055, _jointFill, _outline);
    _circle(c, s, 0.59, 0.825, 0.055, _jointFill, _outline);
    // Shins
    _oval(c, s, 0.41, 0.905, 0.105, 0.19, _fill, _outline);
    _oval(c, s, 0.59, 0.905, 0.105, 0.19, _fill, _outline);
    // Feet
    _oval(c, s, 0.40, 0.985, 0.135, 0.035, _fill, null);
    _oval(c, s, 0.60, 0.985, 0.135, 0.035, _fill, null);
  }

  // ── Muscle highlights ───────────────────────────────────────────────────────

  void _drawHighlights(Canvas c, Size s) {
    for (final muscle in muscles) {
      if (view == _View.front) {
        _frontHighlight(c, s, muscle);
      } else {
        _backHighlight(c, s, muscle);
      }
    }
  }

  void _frontHighlight(Canvas c, Size s, String muscle) {
    final glow = Paint()
      ..color = accentColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final fill = Paint()..color = accentColor.withOpacity(0.75);

    switch (muscle) {
      case 'chest':
      case 'upper-chest':
      case 'lower-chest':
        c.drawOval(_rect(s, 0.5, 0.345, 0.42, 0.22), glow);
        c.drawOval(_rect(s, 0.5, 0.345, 0.34, 0.16), fill);
        break;
      case 'shoulders':
      case 'front-delt':
      case 'side-delt':
        c.drawCircle(_pt(s, 0.24, 0.255), s.width * 0.08, glow);
        c.drawCircle(_pt(s, 0.24, 0.255), s.width * 0.06, fill);
        c.drawCircle(_pt(s, 0.76, 0.255), s.width * 0.08, glow);
        c.drawCircle(_pt(s, 0.76, 0.255), s.width * 0.06, fill);
        break;
      case 'biceps':
      case 'brachialis':
        c.drawOval(_rect(s, 0.19, 0.365, 0.10, 0.19), glow);
        c.drawOval(_rect(s, 0.19, 0.365, 0.08, 0.15), fill);
        c.drawOval(_rect(s, 0.81, 0.365, 0.10, 0.19), glow);
        c.drawOval(_rect(s, 0.81, 0.365, 0.08, 0.15), fill);
        break;
      case 'triceps':
      case 'long-head-triceps':
        c.drawOval(_rect(s, 0.19, 0.375, 0.10, 0.20), glow);
        c.drawOval(_rect(s, 0.19, 0.375, 0.08, 0.15), fill);
        c.drawOval(_rect(s, 0.81, 0.375, 0.10, 0.20), glow);
        c.drawOval(_rect(s, 0.81, 0.375, 0.08, 0.15), fill);
        break;
      case 'core':
      case 'abs':
        c.drawOval(_rect(s, 0.5, 0.47, 0.28, 0.14), glow);
        c.drawOval(_rect(s, 0.5, 0.47, 0.20, 0.10), fill);
        break;
      case 'quads':
        c.drawOval(_rect(s, 0.41, 0.72, 0.135, 0.24), glow);
        c.drawOval(_rect(s, 0.41, 0.72, 0.115, 0.19), fill);
        c.drawOval(_rect(s, 0.59, 0.72, 0.135, 0.24), glow);
        c.drawOval(_rect(s, 0.59, 0.72, 0.115, 0.19), fill);
        break;
      case 'calves':
        c.drawOval(_rect(s, 0.41, 0.90, 0.11, 0.17), glow);
        c.drawOval(_rect(s, 0.41, 0.90, 0.09, 0.13), fill);
        c.drawOval(_rect(s, 0.59, 0.90, 0.11, 0.17), glow);
        c.drawOval(_rect(s, 0.59, 0.90, 0.09, 0.13), fill);
        break;
    }
  }

  void _backHighlight(Canvas c, Size s, String muscle) {
    final glow = Paint()
      ..color = accentColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final fill = Paint()..color = accentColor.withOpacity(0.75);

    switch (muscle) {
      case 'lats':
      case 'back':
        c.drawOval(_rect(s, 0.39, 0.40, 0.16, 0.26), glow);
        c.drawOval(_rect(s, 0.39, 0.40, 0.13, 0.22), fill);
        c.drawOval(_rect(s, 0.61, 0.40, 0.16, 0.26), glow);
        c.drawOval(_rect(s, 0.61, 0.40, 0.13, 0.22), fill);
        break;
      case 'mid-back':
      case 'upper-back':
        c.drawOval(_rect(s, 0.5, 0.31, 0.42, 0.14), glow);
        c.drawOval(_rect(s, 0.5, 0.31, 0.36, 0.10), fill);
        break;
      case 'rear-delt':
        c.drawCircle(_pt(s, 0.24, 0.255), s.width * 0.08, glow);
        c.drawCircle(_pt(s, 0.24, 0.255), s.width * 0.06, fill);
        c.drawCircle(_pt(s, 0.76, 0.255), s.width * 0.08, glow);
        c.drawCircle(_pt(s, 0.76, 0.255), s.width * 0.06, fill);
        break;
      case 'hamstrings':
        c.drawOval(_rect(s, 0.41, 0.72, 0.135, 0.24), glow);
        c.drawOval(_rect(s, 0.41, 0.72, 0.115, 0.19), fill);
        c.drawOval(_rect(s, 0.59, 0.72, 0.135, 0.24), glow);
        c.drawOval(_rect(s, 0.59, 0.72, 0.115, 0.19), fill);
        break;
      case 'glutes':
        c.drawOval(_rect(s, 0.5, 0.595, 0.34, 0.10), glow);
        c.drawOval(_rect(s, 0.5, 0.595, 0.28, 0.07), fill);
        break;
    }
  }

  // ── Drawing helpers ─────────────────────────────────────────────────────────

  void _oval(Canvas c, Size s, double cx, double cy, double fw, double fh,
             Paint fill, Paint? outline) {
    final r = _rect(s, cx, cy, fw, fh);
    c.drawOval(r, fill);
    if (outline != null) c.drawOval(r, outline);
  }

  void _circle(Canvas c, Size s, double cx, double cy, double fr,
               Paint fill, Paint? outline) {
    final center = _pt(s, cx, cy);
    c.drawCircle(center, s.width * fr, fill);
    if (outline != null) c.drawCircle(center, s.width * fr, outline);
  }

  Rect _rect(Size s, double cx, double cy, double fw, double fh) =>
      Rect.fromCenter(
        center: Offset(s.width * cx, s.height * cy),
        width: s.width * fw,
        height: s.height * fh,
      );

  Offset _pt(Size s, double x, double y) => Offset(s.width * x, s.height * y);

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.muscles != muscles || old.accentColor != accentColor || old.view != view;
}
