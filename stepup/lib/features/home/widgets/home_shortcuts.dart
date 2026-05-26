import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutDef(Icons.emoji_events_outlined,   'Join',      '/challenges'),
      _ShortcutDef(Icons.sports_kabaddi_rounded,  'Rival',     '/rivals'),
      _ShortcutDef(Icons.monetization_on_outlined,'Redeem',    '/coins/rewards'),
      _ShortcutDef(Icons.group_outlined,          'Friends',   '/leaderboard/friends'),
      _ShortcutDef(Icons.workspace_premium_rounded,'League',   '/leaderboard/league'),
      _ShortcutDef(Icons.track_changes_rounded,   'Missions',  '/missions'),
    ];

    return Column(
      children: [
        Row(
          children: shortcuts.take(3).map((s) => _Shortcut(def: s)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: shortcuts.skip(3).map((s) => _Shortcut(def: s)).toList(),
        ),
      ],
    );
  }
}

class _ShortcutDef {
  final IconData icon;
  final String label;
  final String route;
  const _ShortcutDef(this.icon, this.label, this.route);
}

class _Shortcut extends StatelessWidget {
  final _ShortcutDef def;
  const _Shortcut({required this.def});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: () => context.push(def.route),
          child: Column(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(def.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              def.label,
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      );
}
