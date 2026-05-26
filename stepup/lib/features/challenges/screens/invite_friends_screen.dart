import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class InviteFriendsScreen extends StatefulWidget {
  final String challengeId;
  const InviteFriendsScreen(
      {required this.challengeId, super.key});

  @override
  State<InviteFriendsScreen> createState() =>
      _InviteFriendsScreenState();
}

class _InviteFriendsScreenState
    extends State<InviteFriendsScreen> {
  Map<String, dynamic>? _challenge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance
          .get('/challenges/custom/${widget.challengeId}')
          as Map<String, dynamic>;
      setState(() {
        _challenge = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareLink =
        'stepup://join/${widget.challengeId}';
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.voltLime))
            : Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text('← Back',
                                style: AppTheme.label(13, color: AppTheme.ink2)),
                          ),
                          Text('2 / 2',
                              style: AppTheme.label(11, color: AppTheme.ink2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('INVITE', style: AppTheme.bigNum(28)),
                      Text('YOUR SQUAD',
                          style: AppTheme.bigNum(28, color: AppTheme.voltLime)),
                      const SizedBox(height: 8),

                      if (_challenge != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.voltLime
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(
                                Icons.emoji_events_rounded,
                                color: AppTheme.voltLime),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _challenge!['title']
                                              as String? ??
                                          '',
                                      style: AppTheme.label(14,
                                              color: Colors.white)
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight
                                                      .w600),
                                    ),
                                    Text(
                                      '${_challenge!['duration_days']}d · ${((_challenge!['difficulty'] as String?) ?? '').toUpperCase()}',
                                      style: AppTheme.label(11),
                                    ),
                                  ]),
                            ),
                            Text(
                              '+${_challenge!['coin_reward']}¢',
                              style: AppTheme.bigNum(16,
                                  color: AppTheme.amber),
                            ),
                          ]),
                        ),
                      const SizedBox(height: 20),

                      Text(
                        'SHARE LINK',
                        style: AppTheme.label(10,
                                color: AppTheme.ink3)
                            .copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.border),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              shareLink,
                              style: AppTheme.label(12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: shareLink));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content:
                                          Text('Link copied!')));
                            },
                            child: const Icon(
                                Icons.copy_rounded,
                                color: AppTheme.voltLime,
                                size: 20),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      Row(children: [
                        _ShareBtn(
                          label: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          color: const Color(0xFF25D366),
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _ShareBtn(
                          label: 'Telegram',
                          icon: Icons.send_rounded,
                          color: const Color(0xFF2AABEE),
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _ShareBtn(
                          label: 'More',
                          icon: Icons.share_rounded,
                          color: AppTheme.ink2,
                          onTap: () {},
                        ),
                      ]),
                      const Spacer(),

                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.amber.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text('Done — Go to Home',
                                style: AppTheme.label(14, color: AppTheme.amber)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ]),
              ),
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      AppTheme.label(11, color: Colors.white)),
            ]),
          ),
        ),
      );
}
