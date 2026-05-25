import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../steps/step_sync_service.dart';
import '../../../core/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  // Step 1 — carousel
  int _slide = 0;

  // Step 2 — activities
  final _selectedActivities = <String>{'walk', 'gym'};

  // Step 4 — profile
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _sex = 'male';
  String _stepGoal = '10k';

  bool _loading = false;

  static const _carouselSlides = [
    (
      'Every Step\nCounts. 👟',
      'Auto-sync from your phone or wearable. No manual logging.'
    ),
    (
      'Join Wellness\nChallenges 🏆',
      'Daily, weekly and seasonal challenges by category.'
    ),
    (
      'Earn & Redeem\nRewards 🎁',
      'Coins for consistency. Redeem for gift cards.'
    ),
  ];

  static const _activities = [
    ('walk', 'Walking & steps'),
    ('gym', 'Gym & strength'),
    ('run', 'Running'),
    ('yoga', 'Yoga & mindfulness'),
    ('sport', 'Sport (badminton, cricket…)'),
    ('cycle', 'Cycling & swimming'),
  ];

  static const _activityIcons = {
    'walk': Icons.directions_walk_rounded,
    'gym': Icons.fitness_center_rounded,
    'run': Icons.directions_run_rounded,
    'yoga': Icons.self_improvement_rounded,
    'sport': Icons.sports_rounded,
    'cycle': Icons.directions_bike_rounded,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishFree() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).saveProfile(
        name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User',
        city: '',
        language: 'english',
        goalTier: _stepGoal == '5k'
            ? 'casual'
            : _stepGoal == '15k'
                ? 'champion'
                : 'active',
      );
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCarousel();
      case 1:
        return _buildActivityPicker();
      case 2:
        return _buildPermissions();
      case 3:
        return _buildProfileSetup();
      case 4:
        return _buildPlanPicker();
      default:
        return const SizedBox();
    }
  }

  // ---- STEP 0: Carousel ----
  Widget _buildCarousel() {
    final (title, sub) = _carouselSlides[_slide];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => setState(() => _step = 4),
            child: Text('Skip',
                style: AppTheme.label(13, color: AppTheme.ink2)),
          ),
          Text('${_slide + 1}/3',
              style: AppTheme.label(13, color: AppTheme.ink3)),
        ]),
        const Spacer(),
        // Illustration placeholder
        Container(
          width: 180,
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.voltLime.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.voltLime.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              '[ Illustration ]',
              style: AppTheme.label(12, color: AppTheme.voltLime),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.bigNum(28).copyWith(height: 1.1),
        ),
        const SizedBox(height: 10),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: AppTheme.label(13, color: AppTheme.ink2),
          maxLines: 3,
        ),
        const Spacer(),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _slide
                    ? AppTheme.voltLime
                    : Colors.transparent,
                border: Border.all(
                    color: i == _slide
                        ? AppTheme.voltLime
                        : AppTheme.ink3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _GoldBtn(
          label: _slide < 2 ? 'Next →' : "Let's go →",
          onPressed: () {
            if (_slide < 2)
              setState(() => _slide++);
            else
              setState(() => _step = 1);
          },
        ),
      ]),
    );
  }

  // ---- STEP 1: Activity picker ----
  Widget _buildActivityPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("What's your vibe?", style: AppTheme.bigNum(28)),
        const SizedBox(height: 6),
        Text(
          "Pick what you do · we'll match challenges",
          style: AppTheme.label(13, color: AppTheme.ink2),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: _activities.map((a) {
              final (key, label) = a;
              final on = _selectedActivities.contains(key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (on)
                    _selectedActivities.remove(key);
                  else
                    _selectedActivities.add(key);
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: on
                        ? AppTheme.voltLime.withValues(alpha: 0.08)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: on
                          ? AppTheme.voltLime
                          : Colors.transparent,
                      width: on ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: on
                            ? AppTheme.voltLime.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _activityIcons[key] ?? Icons.fitness_center,
                        size: 18,
                        color: on ? AppTheme.voltLime : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTheme.label(14, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? AppTheme.voltLime : Colors.transparent,
                        border: Border.all(
                            color: on
                                ? AppTheme.voltLime
                                : Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: on
                          ? Icon(Icons.check, size: 12, color: AppTheme.bg)
                          : null,
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
        _GoldBtn(
          label:
              'Continue (${_selectedActivities.length} picked) →',
          onPressed: () => setState(() => _step = 2),
        ),
      ]),
    );
  }

  // ---- STEP 2: Permissions ----
  Widget _buildPermissions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A few asks 🙏', style: AppTheme.bigNum(28)),
        const SizedBox(height: 6),
        Text(
          'We only use these to track & remind',
          style: AppTheme.label(13, color: AppTheme.ink2),
        ),
        const SizedBox(height: 20),
        _PermCard(
          title: 'Health data',
          sub: 'Count your steps',
          status: '✓ on',
          granted: true,
          onTap: () async {
            try {
              await StepSyncService.instance.requestPermissions();
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        _PermCard(
          title: 'Notifications',
          sub: 'Streak reminders',
          status: 'Allow →',
          granted: false,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _PermCard(
          title: 'Location',
          sub: 'Detect runs (optional)',
          status: 'Skip if u want',
          granted: false,
          onTap: () {},
        ),
        const Spacer(),
        Text(
          'You can change these later in Settings',
          textAlign: TextAlign.center,
          style: AppTheme.label(12, color: AppTheme.ink3),
        ),
        const SizedBox(height: 10),
        _GoldBtn(
            label: 'Continue →',
            onPressed: () => setState(() => _step = 3)),
      ]),
    );
  }

  // ---- STEP 3: Profile Setup ----
  Widget _buildProfileSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Set up profile', style: AppTheme.bigNum(28)),
        const SizedBox(height: 6),
        Text(
          'All in one go · skip what you want',
          style: AppTheme.label(13, color: AppTheme.ink2),
        ),
        const SizedBox(height: 20),
        // Avatar + name row
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.voltLime.withValues(alpha: 0.5),
                  width: 1.5),
              color: AppTheme.surface,
            ),
            child: Center(
              child: Text('+',
                  style: AppTheme.bigNum(22, color: AppTheme.voltLime)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _Field(ctrl: _nameCtrl, hint: 'Display name')),
        ]),
        const SizedBox(height: 6),
        Text('Tap photo to add',
            style: AppTheme.label(11, color: AppTheme.ink3)),
        const SizedBox(height: 16),
        _Field(
          ctrl: _dobCtrl,
          hint: 'Date of birth · DD / MM / YYYY',
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _Field(
              ctrl: _heightCtrl,
              hint: 'Height (cm)',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Field(
              ctrl: _weightCtrl,
              hint: 'Weight (kg)',
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text('Sex', style: AppTheme.label(12, color: AppTheme.ink3)),
        const SizedBox(height: 8),
        Row(
          children: ['male', 'female', 'other']
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: s[0].toUpperCase() + s.substring(1),
                      active: _sex == s,
                      onTap: () => setState(() => _sex = s),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),
        Text('Daily goal',
            style: AppTheme.label(12, color: AppTheme.ink3)),
        const SizedBox(height: 8),
        Row(
          children: ['5k', '8k', '10k', '12k', '15k']
              .map((g) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: g,
                      active: _stepGoal == g,
                      onTap: () => setState(() => _stepGoal = g),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 28),
        _GoldBtn(
            label: 'Save & continue →',
            onPressed: () => setState(() => _step = 4)),
      ]),
    );
  }

  // ---- STEP 4: Plan Picker ----
  Widget _buildPlanPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: _finishFree,
            child: Text('Skip',
                style: AppTheme.label(13, color: AppTheme.ink2)),
          ),
          Text('5/5', style: AppTheme.label(13, color: AppTheme.ink3)),
        ]),
        const SizedBox(height: 16),
        Text('Pick your plan', style: AppTheme.bigNum(28)),
        const SizedBox(height: 6),
        Text(
          'Upgrade anytime · cancel anytime',
          style: AppTheme.label(13, color: AppTheme.ink2),
        ),
        const SizedBox(height: 20),
        // Free card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.ink3.withValues(alpha: 0.3)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Free', style: AppTheme.bigNum(22)),
                      Text('₹0', style: AppTheme.bigNum(18)),
                    ]),
                const SizedBox(height: 2),
                Text('Forever · for trying out',
                    style: AppTheme.label(12, color: AppTheme.ink2)),
                const SizedBox(height: 10),
                ...[
                  ('✓ Track all activities', true),
                  ('✓ Join free challenges', true),
                  ('✗ No coin rewards', false),
                  ('✗ Free user pool only', false),
                ].map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        f.$1,
                        style: AppTheme.label(12,
                            color: f.$2 ? Colors.white : AppTheme.ink3),
                      ),
                    )),
              ]),
        ),
        const SizedBox(height: 16),
        // Beginner card
        Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.voltLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.voltLime, width: 1.5),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Beginner', style: AppTheme.bigNum(22)),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: '₹149',
                                style: AppTheme.bigNum(18)),
                            TextSpan(
                                text: ' / Mo',
                                style: AppTheme.label(11,
                                    color: AppTheme.ink2)),
                          ]),
                        ),
                      ]),
                  const SizedBox(height: 2),
                  Text('Consistency rewards',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                  const SizedBox(height: 10),
                  ...[
                    '✓ Everything in Free',
                    '✓ 2 Paid challenges / month',
                    '✓ Earn coins for consistency',
                    '✓ Top 50% rewarded with coins',
                    '✓ Redeem for gift cards',
                  ].map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(f,
                            style: AppTheme.label(12, color: Colors.white)),
                      )),
                ]),
          ),
          Positioned(
            top: -10,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.voltLime,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Recommended',
                  style: AppTheme.bigNum(10, color: AppTheme.bg)),
            ),
          ),
        ]),
        const Spacer(),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _finishFree,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              child: Text('Stay free', style: AppTheme.label(14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GoldBtn(
              label: 'Start Beginner →',
              loading: _loading,
              onPressed: () {
                _finishFree().then((_) {
                  if (mounted) context.push('/profile/subscription');
                });
              },
            ),
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: _buildStep()),
    );
  }
}

class _PermCard extends StatelessWidget {
  final String title, sub, status;
  final bool granted;
  final VoidCallback onTap;
  const _PermCard({
    required this.title,
    required this.sub,
    required this.status,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: granted
                ? AppTheme.voltLime.withValues(alpha: 0.08)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: granted
                  ? AppTheme.voltLime.withValues(alpha: 0.4)
                  : AppTheme.ink3.withValues(alpha: 0.3),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.label(14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(sub,
                        style:
                            AppTheme.label(12, color: AppTheme.ink2)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: granted ? AppTheme.voltLime : AppTheme.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: AppTheme.label(11,
                    color: granted ? AppTheme.bg : AppTheme.ink2),
              ),
            ),
          ]),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboardType;
  const _Field(
      {required this.ctrl,
      required this.hint,
      this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: AppTheme.label(14, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.label(13, color: AppTheme.ink3),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppTheme.voltLime : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? AppTheme.voltLime : AppTheme.border),
          ),
          child: Text(
            label,
            style: AppTheme.label(12,
                color: active ? AppTheme.bg : AppTheme.ink2),
          ),
        ),
      );
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _GoldBtn(
      {required this.label,
      required this.onPressed,
      this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.voltLime,
            foregroundColor: AppTheme.bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.bg),
                )
              : Text(label,
                  style: AppTheme.bigNum(16, color: AppTheme.bg)),
        ),
      );
}
