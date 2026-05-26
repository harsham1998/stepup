import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

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
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
                Text('Devices', style: AppTheme.label(13, color: AppTheme.ink2)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Title
                Text('CONNECT A DEVICE',
                    style: AppTheme.bigNum(28)
                        .copyWith(fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Sync workouts, heart rate & sleep automatically',
                    style: AppTheme.label(13, color: AppTheme.ink2)),
                const SizedBox(height: 20),

                // Connected device — Apple Watch (via HealthKit)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.voltLime.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.watch_rounded,
                          color: AppTheme.voltLime, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Apple Watch',
                          style: AppTheme.label(15, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: AppTheme.voltLime, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text('Connected · synced 2 min ago',
                            style: AppTheme.label(11, color: AppTheme.ink2)),
                      ]),
                    ])),
                    const Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 22),
                  ]),
                ),
                const SizedBox(height: 20),

                // Available section
                Text('AVAILABLE',
                    style: AppTheme.label(10, color: AppTheme.ink2)
                        .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                ..._available.map((d) => _DeviceRow(
                      name: d[0] as String,
                      icon: d[1] as IconData,
                    )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static const _available = [
    ['Samsung Galaxy Watch', Icons.watch_rounded],
    ['Fitbit', Icons.monitor_heart_rounded],
    ['Garmin', Icons.gps_fixed_rounded],
    ['Noise ColorFit', Icons.watch_outlined],
    ['boAt Storm', Icons.watch_outlined],
  ];
}

class _DeviceRow extends StatefulWidget {
  final String name;
  final IconData icon;
  const _DeviceRow({required this.name, required this.icon});

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _connecting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, color: AppTheme.ink2, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(widget.name,
            style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600))),
        GestureDetector(
          onTap: () async {
            setState(() => _connecting = true);
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) setState(() => _connecting = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.name} is not available on this device')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: _connecting
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.voltLime))
                : Text('CONNECT',
                    style: AppTheme.label(11, color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ),
      ]),
    );
  }
}
