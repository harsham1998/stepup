import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/neon_button.dart';

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
          const SnackBar(
            content: Text('Joined! Good luck 🏆'),
            backgroundColor: Color(0xFF6366F1),
          ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Spacer(),
          NeonButton(
            label: _joined ? 'Joined ✓' : 'Join Challenge',
            onPressed: _joined ? null : _join,
            isLoading: _joining,
          ),
        ]),
      ),
    );
  }
}
