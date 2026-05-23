import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          data: (user) {
            if (user.isEmpty) {
              return const Center(
                child: Text('Not logged in', style: TextStyle(color: Color(0xFF6B7280))),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(children: [
                // Avatar + name card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withValues(alpha: 0.12), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          ((user['name'] as String?) ?? 'U').isNotEmpty
                              ? ((user['name'] as String?) ?? 'U')[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF0C0C18), width: 1.5),
                          ),
                          child: const Icon(Icons.edit, size: 10, color: Colors.white),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      (user['name'] as String?) ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${(user['city'] as String?) ?? ''} · '
                      '${((user['league'] as String?) ?? 'bronze').toUpperCase()} League',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _Badge('🔥 ${user['streak_days'] ?? 0} Streak', AppTheme.primary),
                      const SizedBox(width: 6),
                      _Badge('${user['xp'] ?? 0} XP', AppTheme.amber),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // Settings
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    _SettingRow('Connected Devices', 'Apple Health', Icons.watch_rounded),
                    _SettingRow('Language',
                        (user['language'] as String?) ?? 'english', Icons.language),
                    _SettingRow('Notifications', 'On', Icons.notifications_rounded),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _SettingRow extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _SettingRow(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      const SizedBox(width: 10),
      Expanded(child: Text(title,
          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12))),
      Text(value, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, size: 14, color: Color(0xFF374151)),
    ]),
  );
}
