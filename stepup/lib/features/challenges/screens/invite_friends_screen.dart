import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../friends/models/friend.dart';
import '../../friends/providers/friends_provider.dart';

class InviteFriendsScreen extends ConsumerStatefulWidget {
  final String challengeId;
  const InviteFriendsScreen({required this.challengeId, super.key});

  @override
  ConsumerState<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  Map<String, dynamic>? _challenge;
  bool _loading = true;
  final Set<String> _selected = {};
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/challenges/custom/${widget.challengeId}') as Map<String, dynamic>;
      setState(() { _challenge = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendInvites() async {
    if (_selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.challengeId}/invite', {
        'friend_ids': _selected.toList(),
      });
      setState(() { _sent = true; _sending = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _sent = false);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send invites')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareLink = 'stepup://join/${widget.challengeId}';
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.voltLime))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('← Back', style: AppTheme.label(13, color: AppTheme.ink2)),
                    ),
                    Text('2 / 2', style: AppTheme.label(11, color: AppTheme.ink2)),
                  ]),
                  const SizedBox(height: 12),
                  Text('INVITE', style: AppTheme.bigNum(28)),
                  Text('YOUR SQUAD', style: AppTheme.bigNum(28, color: AppTheme.voltLime)),
                  const SizedBox(height: 8),

                  // Challenge card
                  if (_challenge != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.emoji_events_rounded, color: AppTheme.voltLime),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_challenge!['title'] as String? ?? '',
                              style: AppTheme.label(14, color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('${_challenge!['duration_days']}d · ${((_challenge!['difficulty'] as String?) ?? '').toUpperCase()}',
                              style: AppTheme.label(11)),
                        ])),
                        Text('+${_challenge!['coin_reward']}¢',
                            style: AppTheme.bigNum(16, color: AppTheme.amber)),
                      ]),
                    ),
                  const SizedBox(height: 20),

                  // ─── Section 1: Invite Friends ───────────────────────
                  Text('INVITE FRIENDS', style: AppTheme.label(10, color: AppTheme.ink3)
                      .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  friendsAsync.when(
                    loading: () => const CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 1.5),
                    error: (err, st) => Text('Could not load friends', style: AppTheme.label(12, color: AppTheme.ink2)),
                    data: (friends) {
                      if (friends.isEmpty) {
                        return GestureDetector(
                          onTap: () => context.push('/friends'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text('No friends yet — tap to add friends →',
                                style: AppTheme.label(12, color: AppTheme.voltLime)),
                          ),
                        );
                      }
                      return _FriendPickerList(
                        friends: friends,
                        selected: _selected,
                        challengeId: widget.challengeId,
                        onToggle: (id) => setState(() {
                          _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Send invite button
                  if (!friendsAsync.isLoading)
                    GestureDetector(
                      onTap: (_selected.isEmpty || _sending || _sent) ? null : _sendInvites,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _sent
                              ? AppTheme.voltLime.withValues(alpha: 0.15)
                              : _selected.isEmpty
                                  ? AppTheme.surface
                                  : AppTheme.voltLime,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _sent ? AppTheme.voltLime : _selected.isEmpty ? AppTheme.border : AppTheme.voltLime,
                          ),
                        ),
                        child: Center(
                          child: _sending
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(
                                  _sent
                                      ? 'Sent ✓'
                                      : _selected.isEmpty
                                          ? 'Select friends to invite'
                                          : 'Send Invite (${_selected.length})',
                                  style: AppTheme.label(14,
                                      color: _sent
                                          ? AppTheme.voltLime
                                          : _selected.isEmpty
                                              ? AppTheme.ink2
                                              : Colors.black)
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ─── Section 2: Share Link (unchanged fallback) ───────
                  Row(children: [
                    Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR SHARE LINK', style: AppTheme.label(10, color: AppTheme.ink3)
                          .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Divider(color: AppTheme.border)),
                  ]),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(shareLink, style: AppTheme.label(12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied!')));
                        },
                        child: const Icon(Icons.copy_rounded, color: AppTheme.voltLime, size: 20),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _ShareBtn(label: 'WhatsApp', icon: Icons.chat_rounded, color: const Color(0xFF25D366), onTap: () {}),
                    const SizedBox(width: 10),
                    _ShareBtn(label: 'Telegram', icon: Icons.send_rounded, color: const Color(0xFF2AABEE), onTap: () {}),
                    const SizedBox(width: 10),
                    _ShareBtn(label: 'More', icon: Icons.share_rounded, color: AppTheme.ink2, onTap: () {}),
                  ]),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
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

class _FriendPickerList extends ConsumerWidget {
  final List<Friend> friends;
  final Set<String> selected;
  final String challengeId;
  final void Function(String id) onToggle;
  const _FriendPickerList({
    required this.friends, required this.selected,
    required this.challengeId, required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(challengeFriendsLeaderboardProvider(challengeId));
    final alreadyIn = lbAsync.whenOrNull(
      data: (lb) => lb.participants.map((p) => p.userId).toSet(),
    ) ?? <String>{};

    return Column(children: friends.map((f) {
      final inChallenge = alreadyIn.contains(f.id);
      final isSelected = selected.contains(f.id);
      return GestureDetector(
        onTap: inChallenge ? null : () => onToggle(f.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.voltLime.withValues(alpha: 0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.voltLime : AppTheme.border,
            ),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
              backgroundColor: AppTheme.surface2,
              child: f.avatarUrl == null
                  ? Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.voltLime))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: AppTheme.label(13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              if (f.username != null)
                Text('@${f.username}', style: AppTheme.label(10, color: AppTheme.ink2)),
            ])),
            if (inChallenge)
              Text('In challenge ✓', style: AppTheme.label(10, color: AppTheme.ink2))
            else
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.voltLime : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? AppTheme.voltLime : AppTheme.ink2, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
                    : null,
              ),
          ]),
        ),
      );
    }).toList());
  }
}

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: AppTheme.label(11, color: Colors.white)),
            ]),
          ),
        ),
      );
}
