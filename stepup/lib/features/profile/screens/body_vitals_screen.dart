// stepup/lib/features/profile/screens/body_vitals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../shared/models/body_vitals.dart';
import '../providers/body_vitals_provider.dart';

// ─── Metric definition ────────────────────────────────────────────────────────
enum _Metric { weight, bmi, visceral, muscle }

class _MetricDef {
  final _Metric metric;
  final String label;
  final String unit;
  final Color color;
  final String emoji;
  const _MetricDef(this.metric, this.label, this.unit, this.color, this.emoji);
}

const _metrics = [
  _MetricDef(_Metric.weight,   'Weight',       'kg',  AppTheme.voltLime, '⚖️'),
  _MetricDef(_Metric.bmi,      'BMI',          '',    AppTheme.blue,     '📊'),
  _MetricDef(_Metric.visceral, 'Visceral Fat', 'lvl', AppTheme.pink,     '🔥'),
  _MetricDef(_Metric.muscle,   'Muscle %',     '%',   AppTheme.green,    '💪'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class BodyVitalsScreen extends ConsumerStatefulWidget {
  const BodyVitalsScreen({super.key});
  @override
  ConsumerState<BodyVitalsScreen> createState() => _BodyVitalsScreenState();
}

class _BodyVitalsScreenState extends ConsumerState<BodyVitalsScreen> {
  int _page = 0;
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(bodyVitalsSummaryProvider);
    final historyAsync = ref.watch(bodyVitalsHistoryProvider);
    final loggedToday  = summaryAsync.whenOrNull(data: (s) => s.loggedToday) == true;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Topbar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              _BackBtn(),
              const Expanded(
                child: Center(
                  child: Text('Body Vitals',
                      style: TextStyle(
                        fontFamily: 'BigShouldersDisplay',
                        fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              loggedToday ? _LoggedBadge() : _LogBtn(onTap: () => _showLogModal(context)),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Time range ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _TimeSegment(),
          ),
          const SizedBox(height: 12),

          // ── Swipe hint ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('← swipe', style: AppTheme.label(9, color: AppTheme.ink3)),
                Text('Weight · BMI · Visceral · Muscle',
                    style: AppTheme.label(8.5, color: AppTheme.ink3)),
                Text('swipe →', style: AppTheme.label(9, color: AppTheme.ink3)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── PageView metric cards ──
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _metrics.length,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MetricCard(
                  def: _metrics[i],
                  summary: summaryAsync.whenOrNull(data: (s) => s),
                  history: historyAsync.whenOrNull(data: (h) => h) ?? [],
                ),
              ),
            ),
          ),

          // ── Dots + legend ──
          const SizedBox(height: 8),
          _DotsRow(current: _page),
          const SizedBox(height: 4),
          _MetricLegend(current: _page),
          const SizedBox(height: 14),

          // ── Bottom log button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: loggedToday
                ? _LoggedFullBtn()
                : _LogFullBtn(onTap: () => _showLogModal(context)),
          ),
        ]),
      ),
    );
  }

  void _showLogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LogModal(),
    );
  }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final _MetricDef def;
  final BodyVitalsSummary? summary;
  final List<BodyVitalsEntry> history;

  const _MetricCard({required this.def, required this.summary, required this.history});

  double? _valueOf(BodyVitalsEntry? e) {
    if (e == null) return null;
    return switch (def.metric) {
      _Metric.weight   => e.weightKg,
      _Metric.bmi      => e.bmi,
      _Metric.visceral => e.visceralFatLevel?.toDouble(),
      _Metric.muscle   => e.musclePercentage,
    };
  }

  double? _goalOf(BodyVitalsGoal? g) => switch (def.metric) {
    _Metric.weight => g?.goalWeightKg,
    _Metric.bmi    => g?.goalBmi,
    _             => null,
  };

  @override
  Widget build(BuildContext context) {
    final current = _valueOf(summary?.latest);
    final start   = _valueOf(summary?.earliest);
    final goal    = _goalOf(summary?.goal);
    final change  = (current != null && start != null) ? current - start : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: def.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(def.emoji, style: const TextStyle(fontSize: 13))),
            ),
            const SizedBox(width: 7),
            Text(def.label.toUpperCase(),
                style: AppTheme.label(10, color: def.color)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          ]),
          if (change != null) _DeltaBadge(value: change, metric: def.metric),
        ]),
        const SizedBox(height: 10),

        // Big number
        if (current != null)
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(
              def.metric == _Metric.visceral ? current.toInt().toString() : current.toStringAsFixed(1),
              style: AppTheme.bigNum(36, color: def.color),
            ),
            const SizedBox(width: 4),
            if (def.unit.isNotEmpty)
              Text(def.unit, style: AppTheme.label(14, color: AppTheme.ink2).copyWith(fontWeight: FontWeight.w500)),
          ])
        else
          Text('— ${def.unit}', style: AppTheme.bigNum(36, color: AppTheme.ink3)),
        const SizedBox(height: 14),

        // Heatmap
        Expanded(
          child: _VitalsHeatmap(
            metric: def.metric,
            history: history,
            accentColor: def.color,
            goalValue: goal,
          ),
        ),

        // BMI range bar
        if (def.metric == _Metric.bmi && current != null) ...[
          const SizedBox(height: 8),
          _BmiRangeBar(bmi: current),
        ],

        // Stats
        const SizedBox(height: 10),
        _StatsRow(start: start, current: current, change: change, goal: goal, metric: def.metric, color: def.color),
      ]),
    );
  }
}

// ─── Heatmap ──────────────────────────────────────────────────────────────────
class _VitalsHeatmap extends StatelessWidget {
  final _Metric metric;
  final List<BodyVitalsEntry> history;
  final Color accentColor;
  final double? goalValue;

  const _VitalsHeatmap({
    required this.metric, required this.history,
    required this.accentColor, this.goalValue,
  });

  double? _valueOf(BodyVitalsEntry e) => switch (metric) {
    _Metric.weight   => e.weightKg,
    _Metric.bmi      => e.bmi,
    _Metric.visceral => e.visceralFatLevel?.toDouble(),
    _Metric.muscle   => e.musclePercentage,
  };

  Color _cellColor(double value) {
    final goal = goalValue;
    if (goal == null) return accentColor.withValues(alpha: 0.7);
    // For muscle: higher is better. For all others: lower is better when above goal.
    final isHigherBetter = metric == _Metric.muscle;
    final diff = isHigherBetter ? goal - value : value - goal;
    if (diff <= 0)   return const Color(0xFFD4FF3A).withValues(alpha: 0.9);
    if (diff <= 1)   return const Color(0xFF34D399).withValues(alpha: 0.85);
    if (diff <= 2)   return const Color(0xFFA3E635).withValues(alpha: 0.8);
    if (diff <= 3.5) return const Color(0xFFFBBF24).withValues(alpha: 0.8);
    if (diff <= 5)   return const Color(0xFFF97316).withValues(alpha: 0.75);
    return const Color(0xFFEF4444).withValues(alpha: 0.75);
  }

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{};
    for (final e in history) {
      final v = _valueOf(e);
      if (v != null) dataMap[e.date] = v;
    }

    // Build 6 × 7 = 42 cells aligned Mon–Sun
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final mondayOffset  = todayMidnight.weekday - 1;
    final gridEnd       = todayMidnight.add(Duration(days: 6 - mondayOffset));
    final gridStart     = gridEnd.subtract(const Duration(days: 41));

    final cells = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    final todayStr = todayMidnight.toIso8601String().substring(0, 10);

    return Column(children: [
      // Day-of-week headers
      Row(
        children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: AppTheme.label(6.5, color: AppTheme.ink3)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ))
            .toList(),
      ),
      const SizedBox(height: 3),

      // Grid
      Expanded(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 3, mainAxisSpacing: 3,
          ),
          itemCount: 42,
          itemBuilder: (context, i) {
            final date    = cells[i];
            final dateStr = date.toIso8601String().substring(0, 10);
            final value   = dataMap[dateStr];
            final isToday  = dateStr == todayStr;
            final isFuture = date.isAfter(todayMidnight);

            return Container(
              decoration: BoxDecoration(
                color: isFuture
                    ? Colors.transparent
                    : value != null
                        ? _cellColor(value)
                        : AppTheme.surface2,
                borderRadius: BorderRadius.circular(5),
                border: isToday
                    ? Border.all(color: AppTheme.voltLime, width: 1.5)
                    : isFuture
                        ? null
                        : Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: value != null
                  ? Center(
                      child: Text(
                        metric == _Metric.visceral
                            ? value.toInt().toString()
                            : value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 5, fontWeight: FontWeight.w700,
                          color: Color(0x99000000),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
      const SizedBox(height: 5),
      _HeatmapLegend(),
    ]);
  }
}

class _HeatmapLegend extends StatelessWidget {
  static const _swatches = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFBBF24),
    Color(0xFFA3E635), Color(0xFF34D399), Color(0xFFD4FF3A),
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('Far', style: AppTheme.label(7, color: AppTheme.ink3)),
      const SizedBox(width: 4),
      ..._swatches.map((c) => Container(
        width: 9, height: 9,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      )),
      Text('Goal', style: AppTheme.label(7, color: AppTheme.ink3)),
    ],
  );
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final double? start, current, change, goal;
  final _Metric metric;
  final Color color;

  const _StatsRow({
    this.start, this.current, this.change, this.goal,
    required this.metric, required this.color,
  });

  String _fmt(double? v) {
    if (v == null) return '—';
    return metric == _Metric.visceral ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  Color _changeColor() {
    if (change == null) return AppTheme.ink2;
    return metric == _Metric.muscle
        ? (change! >= 0 ? AppTheme.green : AppTheme.red)
        : (change! <= 0 ? AppTheme.green : AppTheme.red);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppTheme.border)),
    ),
    padding: const EdgeInsets.only(top: 9),
    child: Row(children: [
      _SC(value: _fmt(start),   label: 'Start',  color: Colors.white),
      _SC(value: _fmt(current), label: 'Now',    color: color),
      _SC(
        value: change != null
            ? '${change! >= 0 ? '+' : ''}${_fmt(change)}'
            : '—',
        label: 'Change',
        color: _changeColor(),
      ),
      _SC(value: _fmt(goal), label: 'Goal', color: AppTheme.ink2),
    ]),
  );
}

class _SC extends StatelessWidget {
  final String value, label;
  final Color color;
  const _SC({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: AppTheme.bigNum(14, color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppTheme.label(7.5, color: AppTheme.ink3)),
    ]),
  );
}

// ─── Delta Badge ──────────────────────────────────────────────────────────────
class _DeltaBadge extends StatelessWidget {
  final double value;
  final _Metric metric;
  const _DeltaBadge({required this.value, required this.metric});

  @override
  Widget build(BuildContext context) {
    final isGood  = metric == _Metric.muscle ? value >= 0 : value <= 0;
    final color   = isGood ? AppTheme.green : AppTheme.red;
    final sign    = value >= 0 ? '+' : '';
    final display = metric == _Metric.visceral
        ? '$sign${value.toInt()}'
        : '$sign${value.toStringAsFixed(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${isGood ? '▼' : '▲'} $display',
          style: AppTheme.label(10, color: color).copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

// ─── BMI Range Bar ────────────────────────────────────────────────────────────
class _BmiRangeBar extends StatelessWidget {
  final double bmi;
  const _BmiRangeBar({required this.bmi});

  String _label() {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25)   return 'Normal ✓';
    if (bmi < 30)   return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Under', style: AppTheme.label(7, color: AppTheme.ink3)),
        Text(_label(), style: AppTheme.label(7, color: AppTheme.voltLime).copyWith(fontWeight: FontWeight.w700)),
        Text('Over',  style: AppTheme.label(7, color: AppTheme.ink3)),
        Text('Obese', style: AppTheme.label(7, color: AppTheme.ink3)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 6,
          child: CustomPaint(painter: _BmiBarPainter(markerPos: ((bmi - 15) / 25).clamp(0.0, 1.0))),
        ),
      ),
    ],
  );
}

class _BmiBarPainter extends CustomPainter {
  final double markerPos;
  const _BmiBarPainter({required this.markerPos});

  @override
  void paint(Canvas canvas, Size size) {
    const zones = [
      (0.22, Color(0xFF63B4FF), 0.5),
      (0.38, Color(0xFF34D399), 0.6),
      (0.22, Color(0xFFFFB547), 0.5),
      (0.18, Color(0xFFEF4444), 0.5),
    ];
    double x = 0;
    for (final (frac, color, alpha) in zones) {
      final w = size.width * frac;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = color.withValues(alpha: alpha),
      );
      x += w;
    }
    final mx = size.width * markerPos;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(mx - 1.5, -1, 3, size.height + 2),
          const Radius.circular(2)),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BmiBarPainter old) => old.markerPos != markerPos;
}

// ─── Dot Indicator ───────────────────────────────────────────────────────────
class _DotsRow extends StatelessWidget {
  final int current;
  const _DotsRow({required this.current});

  static const _colors = [AppTheme.voltLime, AppTheme.blue, AppTheme.pink, AppTheme.green];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(4, (i) {
      final active = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: active ? 20 : 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: active ? _colors[i] : _colors[i].withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }),
  );
}

// ─── Metric Legend ────────────────────────────────────────────────────────────
class _MetricLegend extends StatelessWidget {
  final int current;
  const _MetricLegend({required this.current});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_metrics.length, (i) {
        final active = i == current;
        final def = _metrics[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: def.color.withValues(alpha: active ? 1.0 : 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 3),
            Text(def.label,
                style: AppTheme.label(8, color: active ? AppTheme.ink2 : AppTheme.ink3)),
          ]),
        );
      }),
    ),
  );
}

// ─── Time Segment ─────────────────────────────────────────────────────────────
class _TimeSegment extends StatefulWidget {
  const _TimeSegment();

  @override
  State<_TimeSegment> createState() => _TimeSegmentState();
}

class _TimeSegmentState extends State<_TimeSegment> {
  int _sel = 1;

  @override
  Widget build(BuildContext context) {
    const labels = ['7D', '30D', '90D', 'ALL'];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _sel = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: _sel == i
                  ? BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppTheme.border2),
                    )
                  : null,
              child: Center(
                child: Text(labels[i],
                    style: AppTheme.label(10,
                            color: _sel == i ? Colors.white : AppTheme.ink3)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        )),
      ),
    );
  }
}

// ─── Log Modal ────────────────────────────────────────────────────────────────
class _LogModal extends ConsumerStatefulWidget {
  const _LogModal();

  @override
  ConsumerState<_LogModal> createState() => _LogModalState();
}

class _LogModalState extends ConsumerState<_LogModal> {
  final _weightCtrl   = TextEditingController();
  final _bmiCtrl      = TextEditingController();
  final _visceralCtrl = TextEditingController();
  final _muscleCtrl   = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose(); _bmiCtrl.dispose();
    _visceralCtrl.dispose(); _muscleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(vitalsLogProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(
          child: Container(
            width: 36, height: 3,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: AppTheme.border2, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Text("Log Today's Vitals",
            style: AppTheme.bigNum(18)),
        const SizedBox(height: 16),

        // Weight + BMI
        Row(children: [
          Expanded(child: _VitalField(label: 'Weight', unit: 'kg', controller: _weightCtrl, hint: '68.4')),
          const SizedBox(width: 8),
          Expanded(child: _VitalField(label: 'BMI', unit: '', controller: _bmiCtrl, hint: '22.1')),
        ]),
        const SizedBox(height: 8),

        // Visceral + Muscle
        Row(children: [
          Expanded(child: _VitalField(label: 'Visceral Fat', unit: 'lvl', controller: _visceralCtrl, hint: '7', isInt: true)),
          const SizedBox(width: 8),
          Expanded(child: _VitalField(label: 'Muscle %', unit: '%', controller: _muscleCtrl, hint: '42.3')),
        ]),
        const SizedBox(height: 16),

        if (logState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(logState.error!,
                style: AppTheme.label(11, color: AppTheme.red)),
          ),

        // Save button
        GestureDetector(
          onTap: logState.isLoading ? null : _save,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.voltLime,
              borderRadius: BorderRadius.circular(13),
            ),
            child: logState.isLoading
                ? const Center(
                    child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF050510))))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Save & Earn',
                        style: AppTheme.label(13, color: const Color(0xFF050510))
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('+10 XP',
                          style: AppTheme.label(9, color: const Color(0xFF050510))
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _save() async {
    final weight   = double.tryParse(_weightCtrl.text.trim());
    final bmi      = double.tryParse(_bmiCtrl.text.trim());
    final visceral = int.tryParse(_visceralCtrl.text.trim());
    final muscle   = double.tryParse(_muscleCtrl.text.trim());

    if (weight == null && bmi == null && visceral == null && muscle == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter at least one value')));
      return;
    }

    await ref.read(vitalsLogProvider.notifier).log(
      weightKg: weight, bmi: bmi,
      visceralFatLevel: visceral, musclePercentage: muscle,
    );

    if (mounted && ref.read(vitalsLogProvider).error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vitals logged · +10 XP earned 🎉'),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _VitalField extends StatelessWidget {
  final String label, unit, hint;
  final TextEditingController controller;
  final bool isInt;
  const _VitalField({
    required this.label, required this.unit,
    required this.controller, required this.hint, this.isInt = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface3,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border2),
    ),
    padding: const EdgeInsets.all(10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: AppTheme.label(8, color: AppTheme.ink3).copyWith(letterSpacing: 0.4)),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: isInt
                ? TextInputType.number
                : const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bigNum(18),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTheme.bigNum(18, color: AppTheme.ink3),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (unit.isNotEmpty)
          Text(unit, style: AppTheme.label(11, color: AppTheme.ink2).copyWith(fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}

// ─── Small helpers ────────────────────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.border2),
      ),
      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: AppTheme.ink2),
    ),
  );
}

class _LogBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _LogBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: AppTheme.voltLime, borderRadius: BorderRadius.circular(9)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('+ Log', style: AppTheme.label(9, color: const Color(0xFF050510)).copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
          child: Text('+10 XP', style: AppTheme.label(7.5, color: const Color(0xFF050510)).copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );
}

class _LoggedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppTheme.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppTheme.green.withValues(alpha: 0.25)),
    ),
    child: Text('✓ Logged',
        style: AppTheme.label(9, color: AppTheme.green).copyWith(fontWeight: FontWeight.w700)),
  );
}

class _LogFullBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _LogFullBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppTheme.voltLime, borderRadius: BorderRadius.circular(13)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("📝 Log Today's Vitals",
            style: AppTheme.label(12, color: const Color(0xFF050510)).copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text('+10 XP',
              style: AppTheme.label(9, color: const Color(0xFF050510)).copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );
}

class _LoggedFullBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: AppTheme.green.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppTheme.green.withValues(alpha: 0.22)),
    ),
    child: Center(
      child: Text('✓ Logged today · +10 XP earned',
          style: AppTheme.label(11, color: AppTheme.green).copyWith(fontWeight: FontWeight.w700)),
    ),
  );
}
