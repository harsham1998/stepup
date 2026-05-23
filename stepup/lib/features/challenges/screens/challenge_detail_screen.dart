import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/widgets/neon_button.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.id}/join', {});
      if (mounted) {
        setState(() { _joining = false; _joined = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined! Good luck 🏆'),
              backgroundColor: Color(0xFF6366F1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: Color(0xFF9CA3AF))),
        ),
        data: (challenge) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(challenge.title,
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [
              _InfoChip(
                label: '${(challenge.stepGoal / 1000).toStringAsFixed(challenge.stepGoal % 1000 == 0 ? 0 : 1)}k steps',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              _InfoChip(label: challenge.prizePoolInr, color: AppTheme.green),
              if (challenge.isPaid) ...[
                const SizedBox(width: 8),
                _InfoChip(label: 'Entry: ${challenge.entryFeeInr}', color: AppTheme.amber),
              ],
            ]),
            const SizedBox(height: 4),
            Text(
              'Ends ${_formatDate(challenge.endTime)}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
            const Spacer(),
            NeonButton(
              label: _joined ? 'Joined ✓' : 'Join Challenge',
              onPressed: _joined ? null : _join,
              isLoading: _joining,
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
