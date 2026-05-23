import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/neon_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  // ignore: prefer_final_fields
  String _language = 'english', _goalTier = 'active';
  bool _loading = false;

  static const _goals = [
    ('casual',   '🚶', 'Casual',   '5,000 steps/day'),
    ('active',   '🏃', 'Active',   '10,000 steps/day'),
    ('champion', '⚡', 'Champion', '15,000 steps/day'),
    ('elite',    '👑', 'Elite',    '20,000+ steps/day'),
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _cityCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _cityCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).saveProfile(
        name: _nameCtrl.text, city: _cityCtrl.text,
        language: _language, goalTier: _goalTier,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Set up your profile 🎯',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text("We'll match challenges to your fitness level",
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 24),
              TextField(controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Your name')),
              const SizedBox(height: 12),
              TextField(controller: _cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Your city')),
              const SizedBox(height: 24),
              const Text('Daily Step Goal',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ..._goals.map((g) => _GoalTile(
                emoji: g.$2, title: g.$3, subtitle: g.$4,
                selected: _goalTier == g.$1,
                onTap: () => setState(() => _goalTier = g.$1),
              )),
              const SizedBox(height: 28),
              NeonButton(label: "Let's Go →", onPressed: _save, isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _GoalTile({required this.emoji, required this.title, required this.subtitle,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1).withValues(alpha: 0.14) : const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ])),
          if (title == 'Active')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}
