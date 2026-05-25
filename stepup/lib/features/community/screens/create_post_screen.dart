import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/community_provider.dart';
import '../../../core/theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  String _selectedType = 'flex';
  String _visibility = 'everyone';

  static const _types = [
    ('flex', 'Flex', '💪'),
    ('gym', 'Gym', '🏋️'),
    ('progress', 'Progress', '📈'),
    ('nutrition', 'Nutrition', '🥗'),
    ('achievement', 'Achievement', '🏅'),
    ('milestone', 'Milestone', '⭐'),
  ];

  static const _visibilityOptions = [
    ('everyone', 'Everyone', Icons.public_rounded),
    ('followers', 'Followers', Icons.people_rounded),
    ('friends', 'Friends', Icons.group_rounded),
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption to post')),
      );
      return;
    }
    await ref.read(createPostProvider.notifier).submit(
          type: _selectedType,
          content: caption,
          visibility: _visibility,
        );
    if (!mounted) return;
    final s = ref.read(createPostProvider);
    if (s.success) {
      ref.invalidate(communityFeedProvider);
      context.pop();
    } else if (s.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createPostProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('New Post',
            style: AppTheme.bigNum(18).copyWith(fontStyle: FontStyle.italic)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppTheme.voltLime, strokeWidth: 2))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Post',
                          style: AppTheme.label(13, color: AppTheme.bg)
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Post type chips
          Text('POST TYPE',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final (val, label, emoji) = t;
              final selected = _selectedType == val;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = val),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.voltLime.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.voltLime : AppTheme.border,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(label,
                        style: AppTheme.label(13,
                                color: selected
                                    ? AppTheme.voltLime
                                    : Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Caption
          Text('CAPTION',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _captionCtrl,
              maxLines: 5,
              maxLength: 280,
              style: AppTheme.label(14, color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    "What's on your mind? Tag @friends to shout them out...",
                hintStyle: AppTheme.label(14, color: AppTheme.ink2),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: AppTheme.label(11, color: AppTheme.ink2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Audience
          Text('AUDIENCE',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: _visibilityOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final (val, label, icon) = entry.value;
                final selected = _visibility == val;
                return Column(children: [
                  if (i != 0)
                    Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06)),
                  GestureDetector(
                    onTap: () => setState(() => _visibility = val),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Icon(icon,
                            color: selected
                                ? AppTheme.voltLime
                                : AppTheme.ink2,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label,
                              style: AppTheme.label(14,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.ink2)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded,
                              color: AppTheme.voltLime, size: 18),
                      ]),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
