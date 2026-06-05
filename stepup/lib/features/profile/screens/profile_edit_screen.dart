import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editAsync = ref.watch(editProfileProvider);

    if (editAsync.hasValue) {
      return _ProfileEditForm(initial: editAsync.value!);
    }
    if (editAsync.hasError) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text('Failed to load profile', style: AppTheme.label(14, color: AppTheme.ink2)),
        ),
      );
    }
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form state
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileEditForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> initial;
  const _ProfileEditForm({required this.initial});

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  // Text controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _usernameCtrl;
  Timer? _usernameDebounce;
  String _usernameStatus = 'idle'; // idle | checking | available | taken | invalid
  String? _usernameInitial;

  // Selection state
  String _language = 'english';
  String? _sex;
  String _units = 'metric';
  String? _fitnessLevel;
  String? _primaryGoal;
  int _stepGoal = 10000;
  String? _workoutTime;
  int? _workoutDays;
  Set<String> _activities = {};
  bool _pushNotifications = true;
  bool _showOnLeaderboard = true;
  String _profileVisibility = 'public';

  bool _saving = false;

  static const _stepGoals = [5000, 8000, 10000, 12000, 15000];
  static const _languages = ['english', 'hindi', 'telugu', 'tamil', 'kannada'];
  static const _activityOptions = [
    ('walk', '🚶', 'Walking'),
    ('gym', '🏋️', 'Gym'),
    ('run', '🏃', 'Running'),
    ('yoga', '🧘', 'Yoga'),
    ('sport', '🏸', 'Sport'),
    ('cycle', '🚴', 'Cycling'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameCtrl  = TextEditingController(text: p['name'] as String? ?? '');
    _bioCtrl   = TextEditingController(text: p['bio'] as String? ?? '');
    _cityCtrl  = TextEditingController(text: p['city'] as String? ?? '');
    _dobCtrl   = TextEditingController(text: p['dob'] as String? ?? '');
    _heightCtrl = TextEditingController(
      text: p['height_cm'] != null ? '${p['height_cm']}' : '',
    );
    _weightCtrl = TextEditingController(
      text: p['weight_kg'] != null ? '${p['weight_kg']}' : '',
    );

    _usernameInitial = p['username'] as String? ?? '';
    _usernameCtrl = TextEditingController(text: _usernameInitial ?? '');
    _usernameCtrl.addListener(_onUsernameChanged);

    _language          = p['language'] as String? ?? 'english';
    _sex               = p['sex'] as String?;
    _units             = p['units'] as String? ?? 'metric';
    _fitnessLevel      = p['fitness_level'] as String?;
    _primaryGoal       = p['primary_goal'] as String?;
    _stepGoal          = p['step_goal'] as int? ?? 10000;
    _workoutTime       = p['preferred_workout_time'] as String?;
    _workoutDays       = p['workout_days_per_week'] as int?;
    _activities        = Set<String>.from(
      (p['activity_types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
    _pushNotifications = p['push_notifications'] as bool? ?? true;
    _showOnLeaderboard = p['show_on_leaderboard'] as bool? ?? true;
    _profileVisibility = p['profile_visibility'] as String? ?? 'public';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    final raw = _usernameCtrl.text;
    final lower = raw.toLowerCase();
    if (raw != lower) {
      _usernameCtrl.value = _usernameCtrl.value.copyWith(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
      return;
    }
    if (lower.isEmpty || lower == _usernameInitial) {
      _usernameDebounce?.cancel();
      setState(() => _usernameStatus = 'idle');
      return;
    }
    final validFormat = RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(lower);
    if (!validFormat) {
      _usernameDebounce?.cancel();
      setState(() => _usernameStatus = 'invalid');
      return;
    }
    setState(() => _usernameStatus = 'checking');
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await ApiClient.instance.get('/friends/check-username', {'q': lower}) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() => _usernameStatus = (result['available'] as bool) ? 'available' : 'taken');
      } catch (_) {
        if (mounted) setState(() => _usernameStatus = 'idle');
      }
    });
  }

  Future<void> _save() async {
    if (_usernameStatus == 'taken' || _usernameStatus == 'invalid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix your username before saving')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim().isEmpty ? 'User' : _nameCtrl.text.trim(),
        if (_usernameCtrl.text.trim().isNotEmpty) 'username': _usernameCtrl.text.trim(),
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'language': _language,
        if (_dobCtrl.text.isNotEmpty) 'dob': _dobCtrl.text,
        if (_heightCtrl.text.isNotEmpty)
          'height_cm': int.tryParse(_heightCtrl.text),
        if (_weightCtrl.text.isNotEmpty)
          'weight_kg': double.tryParse(_weightCtrl.text),
        if (_sex != null) 'sex': _sex,
        'units': _units,
        if (_fitnessLevel != null) 'fitness_level': _fitnessLevel,
        if (_primaryGoal != null) 'primary_goal': _primaryGoal,
        'step_goal': _stepGoal,
        if (_workoutTime != null) 'preferred_workout_time': _workoutTime,
        if (_workoutDays != null) 'workout_days_per_week': _workoutDays,
        'activity_types': _activities.toList(),
        'push_notifications': _pushNotifications,
        'show_on_leaderboard': _showOnLeaderboard,
        'profile_visibility': _profileVisibility,
      };

      await ref.read(authServiceProvider).saveFullProfile(body);

      // Invalidate so profile screen refreshes on pop
      ref.invalidate(profileSummaryProvider);
      ref.invalidate(editProfileProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    DateTime initial = DateTime(1998, 1, 1);
    if (_dobCtrl.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_dobCtrl.text);
      if (parsed != null) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.voltLime, onPrimary: AppTheme.bg),
          dialogBackgroundColor: AppTheme.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatDob(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int _age(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 0;
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return age;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarUploadProvider);
    final initialAvatarUrl = widget.initial['avatar_url'] as String?;
    // Sync provider so other screens see the avatar even before an upload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(avatarUploadProvider.notifier).seedUrl(initialAvatarUrl);
    });
    final avatarUrl = avatarState.url ?? initialAvatarUrl;
    final name = _nameCtrl.text.trim();
    final phone = widget.initial['phone'] as String?;
    final email = widget.initial['email'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────
            _AppBar(saving: _saving, onSave: _save),
            // ── Scrollable form ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Hero(
                      name: name.isNotEmpty ? name : (phone ?? 'You'),
                      avatarUrl: avatarUrl,
                      isUploading: avatarState.isUploading,
                      phone: phone,
                      onTapAvatar: () =>
                          ref.read(avatarUploadProvider.notifier).pickAndUpload(),
                    ),
                    _divider(),

                    // ── Identity ─────────────────────────────────
                    _sectionHeader('Identity', AppTheme.voltLime),
                    _textField(
                      icon: Icons.person_rounded,
                      iconColor: AppTheme.voltLime,
                      label: 'Display Name',
                      ctrl: _nameCtrl,
                      hint: 'Your name',
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _UsernameField(ctrl: _usernameCtrl, status: _usernameStatus),
                    ),
                    _gap(),
                    _bioField(),
                    _gap(),
                    _textField(
                      icon: Icons.location_city_rounded,
                      iconColor: AppTheme.pink,
                      label: 'City',
                      ctrl: _cityCtrl,
                      hint: 'Your city',
                    ),
                    _gap(),
                    _selectField(
                      icon: Icons.language_rounded,
                      iconColor: AppTheme.blue,
                      label: 'Language',
                      value: _language[0].toUpperCase() + _language.substring(1),
                      onTap: () => _showLanguagePicker(),
                    ),
                    _gap(),
                    // Phone & email (read-only)
                    if (phone != null && phone.isNotEmpty) ...[
                      _readOnlyField(
                        icon: Icons.phone_rounded,
                        iconColor: AppTheme.green,
                        label: 'Mobile Number',
                        value: '+91 $phone',
                      ),
                      _gap(),
                    ],
                    if (email != null && email.isNotEmpty) ...[
                      _readOnlyField(
                        icon: Icons.email_rounded,
                        iconColor: AppTheme.amber,
                        label: 'Email',
                        value: email,
                      ),
                      _gap(),
                    ],
                    const SizedBox(height: 8),
                    _divider(),

                    // ── Personal Info ─────────────────────────────
                    _sectionHeader('Personal Info', AppTheme.amber),
                    _dobField(),
                    _gap(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Expanded(
                          child: _FieldBox(
                            icon: Icons.straighten_rounded,
                            iconColor: AppTheme.purple,
                            label: _units == 'metric' ? 'Height (cm)' : 'Height (ft)',
                            child: TextField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: AppTheme.label(15, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: _units == 'metric' ? 'e.g. 178' : 'e.g. 510',
                                hintStyle: AppTheme.label(13, color: AppTheme.ink3),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FieldBox(
                            icon: Icons.monitor_weight_rounded,
                            iconColor: AppTheme.amber,
                            label: _units == 'metric' ? 'Weight (kg)' : 'Weight (lb)',
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: AppTheme.label(15, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: _units == 'metric' ? 'e.g. 72' : 'e.g. 158',
                                hintStyle: AppTheme.label(13, color: AppTheme.ink3),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    _gap(),
                    _chipSection(
                      icon: Icons.wc_rounded,
                      iconColor: const Color(0xFFFF8080),
                      label: 'Sex',
                      options: const [
                        ('male', 'Male'),
                        ('female', 'Female'),
                        ('other', 'Other'),
                        ('prefer_not_to_say', 'Prefer not to say'),
                      ],
                      selected: {if (_sex != null) _sex!},
                      singleSelect: true,
                      activeColor: AppTheme.voltLime,
                      onToggle: (v) => setState(() => _sex = v),
                    ),
                    _gap(),
                    _chipSection(
                      icon: Icons.straighten_rounded,
                      iconColor: AppTheme.green,
                      label: 'Units',
                      options: const [
                        ('metric', 'Metric (cm / kg)'),
                        ('imperial', 'Imperial (ft / lb)'),
                      ],
                      selected: {_units},
                      singleSelect: true,
                      activeColor: AppTheme.green,
                      onToggle: (v) => setState(() => _units = v),
                    ),
                    const SizedBox(height: 8),
                    _divider(),

                    // ── Fitness Goals ─────────────────────────────
                    _sectionHeader('Fitness Goals', AppTheme.purple),
                    _chipSection(
                      icon: Icons.military_tech_rounded,
                      iconColor: AppTheme.voltLime,
                      label: 'Fitness Level',
                      options: const [
                        ('beginner', 'Beginner'),
                        ('intermediate', 'Intermediate'),
                        ('advanced', 'Advanced'),
                      ],
                      selected: {if (_fitnessLevel != null) _fitnessLevel!},
                      singleSelect: true,
                      activeColor: AppTheme.voltLime,
                      onToggle: (v) => setState(() => _fitnessLevel = v),
                    ),
                    _gap(),
                    _chipSection(
                      icon: Icons.flag_rounded,
                      iconColor: AppTheme.amber,
                      label: 'Primary Goal',
                      options: const [
                        ('lose_weight', 'Lose Weight'),
                        ('build_muscle', 'Build Muscle'),
                        ('stay_active', 'Stay Active'),
                        ('endurance', 'Endurance'),
                      ],
                      selected: {if (_primaryGoal != null) _primaryGoal!},
                      singleSelect: true,
                      activeColor: AppTheme.amber,
                      onToggle: (v) => setState(() => _primaryGoal = v),
                    ),
                    const SizedBox(height: 8),
                    _divider(),

                    // ── Schedule ──────────────────────────────────
                    _sectionHeader('Schedule', AppTheme.blue),
                    _stepGoalPicker(),
                    _gap(),
                    _chipSection(
                      icon: Icons.access_time_rounded,
                      iconColor: AppTheme.blue,
                      label: 'Preferred Workout Time',
                      options: const [
                        ('morning', '🌅 Morning'),
                        ('afternoon', '☀️ Afternoon'),
                        ('evening', '🌆 Evening'),
                        ('night', '🌙 Night'),
                      ],
                      selected: {if (_workoutTime != null) _workoutTime!},
                      singleSelect: true,
                      activeColor: AppTheme.blue,
                      onToggle: (v) => setState(() => _workoutTime = v),
                    ),
                    _gap(),
                    _workoutDaysPicker(),
                    _gap(),
                    _activitiesGrid(),
                    const SizedBox(height: 8),
                    _divider(),

                    // ── Privacy ───────────────────────────────────
                    _sectionHeader('Privacy', AppTheme.green),
                    _chipSection(
                      icon: Icons.visibility_rounded,
                      iconColor: AppTheme.green,
                      label: 'Profile Visibility',
                      options: const [
                        ('public', '🌍 Public'),
                        ('friends', '👥 Friends'),
                        ('private', '🔒 Private'),
                      ],
                      selected: {_profileVisibility},
                      singleSelect: true,
                      activeColor: AppTheme.green,
                      onToggle: (v) => setState(() => _profileVisibility = v),
                    ),
                    _gap(),
                    _toggleRow(
                      icon: Icons.notifications_none_rounded,
                      iconColor: AppTheme.blue,
                      label: 'Push Notifications',
                      sublabel: 'Streaks, challenges, rivals',
                      value: _pushNotifications,
                      onChanged: (v) => setState(() => _pushNotifications = v),
                    ),
                    _gap(),
                    _toggleRow(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppTheme.amber,
                      label: 'Show on Leaderboard',
                      sublabel: 'Others can see your rank',
                      value: _showOnLeaderboard,
                      onChanged: (v) => setState(() => _showOnLeaderboard = v),
                    ),
                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SaveButton(saving: _saving, onSave: _save),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _divider() => Container(height: 1, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 4));

  Widget _gap() => const SizedBox(height: 10);

  Widget _sectionHeader(String title, Color accent) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          Container(width: 3, height: 16, color: accent, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.bigNum(14, color: accent),
          ),
        ]),
      );

  Widget _textField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController ctrl,
    String? hint,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _FieldBox(
          icon: icon,
          iconColor: iconColor,
          label: label,
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: AppTheme.label(15, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.label(13, color: AppTheme.ink3),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      );

  Widget _selectField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onTap,
          child: _FieldBox(
            icon: icon,
            iconColor: iconColor,
            label: label,
            child: Row(children: [
              Expanded(child: Text(value, style: AppTheme.label(15, color: Colors.white))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.ink3),
            ]),
          ),
        ),
      );

  Widget _readOnlyField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _FieldBox(
          icon: icon,
          iconColor: iconColor,
          label: label,
          child: Row(children: [
            Expanded(child: Text(value, style: AppTheme.label(15, color: Colors.white))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.ink3.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Read-only', style: AppTheme.label(10, color: AppTheme.ink3)),
            ),
          ]),
        ),
      );

  Widget _bioField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.purple),
                ),
                const SizedBox(width: 10),
                Text('Bio / Tagline', style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 200,
                style: AppTheme.label(14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'A short line about yourself…',
                  hintStyle: AppTheme.label(13, color: AppTheme.ink3),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterStyle: AppTheme.label(10, color: AppTheme.ink3),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dobField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: _pickDob,
          child: _FieldBox(
            icon: Icons.cake_rounded,
            iconColor: AppTheme.blue,
            label: 'Date of Birth',
            child: Row(children: [
              Expanded(
                child: Text(
                  _dobCtrl.text.isNotEmpty
                      ? '${_formatDob(_dobCtrl.text)}  ·  Age ${_age(_dobCtrl.text)}'
                      : 'Tap to set',
                  style: AppTheme.label(
                    15,
                    color: _dobCtrl.text.isNotEmpty ? Colors.white : AppTheme.ink3,
                  ),
                ),
              ),
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.ink3),
            ]),
          ),
        ),
      );

  Widget _chipSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required List<(String, String)> options,
    required Set<String> selected,
    required bool singleSelect,
    required Color activeColor,
    required void Function(String) onToggle,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(label, style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10)),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final (key, display) = opt;
                  final on = selected.contains(key);
                  return GestureDetector(
                    onTap: () => onToggle(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: on ? activeColor.withValues(alpha: 0.12) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on ? activeColor.withValues(alpha: 0.5) : AppTheme.border,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        display,
                        style: AppTheme.label(13, color: on ? activeColor : AppTheme.ink2)
                            .copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w400),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

  Widget _stepGoalPicker() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_walk_rounded, size: 14, color: AppTheme.voltLime),
                ),
                const SizedBox(width: 10),
                Text('Daily Step Goal', style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10)),
                const Spacer(),
                Text(
                  _stepGoal >= 1000 ? '${(_stepGoal / 1000).toStringAsFixed(0)}k' : '$_stepGoal',
                  style: AppTheme.bigNum(16, color: AppTheme.amber),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _stepGoals.map((g) {
                  final on = _stepGoal == g;
                  final label = '${(g / 1000).toStringAsFixed(0)}k';
                  return GestureDetector(
                    onTap: () => setState(() => _stepGoal = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? AppTheme.amber.withValues(alpha: 0.12) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on ? AppTheme.amber.withValues(alpha: 0.5) : AppTheme.border,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppTheme.bigNum(13, color: on ? AppTheme.amber : AppTheme.ink2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

  Widget _workoutDaysPicker() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.purple),
                ),
                const SizedBox(width: 10),
                Text('Workout Days / Week', style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10)),
                if (_workoutDays != null) ...[
                  const Spacer(),
                  Text('$_workoutDays days', style: AppTheme.bigNum(14, color: AppTheme.purple)),
                ],
              ]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final on = _workoutDays == day;
                  return GestureDetector(
                    onTap: () => setState(() => _workoutDays = on ? null : day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: on ? AppTheme.purple.withValues(alpha: 0.15) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: on ? AppTheme.purple.withValues(alpha: 0.6) : AppTheme.border,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: AppTheme.bigNum(14, color: on ? AppTheme.purple : AppTheme.ink2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );

  Widget _activitiesGrid() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_run_rounded, size: 14, color: AppTheme.amber),
                ),
                const SizedBox(width: 10),
                Text('Activities', style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10)),
                const Spacer(),
                if (_activities.isNotEmpty)
                  Text(
                    '${_activities.length} selected',
                    style: AppTheme.label(11, color: AppTheme.ink3),
                  ),
              ]),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
                children: _activityOptions.map((opt) {
                  final (key, emoji, label) = opt;
                  final on = _activities.contains(key);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (on) _activities.remove(key); else _activities.add(key);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: on ? AppTheme.amber.withValues(alpha: 0.08) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: on ? AppTheme.amber.withValues(alpha: 0.4) : AppTheme.border,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            label,
                            style: AppTheme.label(12, color: on ? AppTheme.amber : AppTheme.ink2)
                                .copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ),
                        if (on)
                          Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.amber),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.label(14, color: Colors.white).copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(sublabel, style: AppTheme.label(11, color: AppTheme.ink3)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 24,
                decoration: BoxDecoration(
                  color: value
                      ? AppTheme.voltLime.withValues(alpha: 0.15)
                      : AppTheme.ink3.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: value
                        ? AppTheme.voltLime.withValues(alpha: 0.5)
                        : AppTheme.border,
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: value ? AppTheme.voltLime : AppTheme.ink3,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );

  void _showLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: AppTheme.bigNum(18)),
            const SizedBox(height: 16),
            ..._languages.map((lang) {
              final label = lang[0].toUpperCase() + lang.substring(1);
              return GestureDetector(
                onTap: () {
                  setState(() => _language = lang);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _language == lang
                        ? AppTheme.voltLime.withValues(alpha: 0.08)
                        : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _language == lang
                          ? AppTheme.voltLime.withValues(alpha: 0.4)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(label, style: AppTheme.label(14, color: Colors.white))),
                    if (_language == lang)
                      const Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 18),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _AppBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.ink2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Edit Profile', style: AppTheme.bigNum(20)),
          ),
          if (saving)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.voltLime),
            )
          else
            GestureDetector(
              onTap: onSave,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.voltLime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Save', style: AppTheme.bigNum(14, color: AppTheme.bg)),
              ),
            ),
        ]),
      );
}

class _Hero extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isUploading;
  final String? phone;
  final VoidCallback onTapAvatar;

  const _Hero({
    required this.name,
    required this.avatarUrl,
    required this.isUploading,
    required this.phone,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.voltLime.withValues(alpha: 0.06),
              AppTheme.purple.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: isUploading ? null : onTapAvatar,
            child: Stack(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.voltLime.withValues(alpha: 0.08),
                  border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initials(name))
                      : _initials(name),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bg, width: 2),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: AppTheme.bg),
                        )
                      : const Icon(Icons.camera_alt_rounded, size: 11, color: AppTheme.bg),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTheme.bigNum(20)),
                const SizedBox(height: 3),
                if (phone != null)
                  Text('+91 $phone', style: AppTheme.label(12, color: AppTheme.ink2)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: isUploading ? null : onTapAvatar,
                  child: Text(
                    'Change photo',
                    style: AppTheme.label(12, color: AppTheme.voltLime)
                        .copyWith(decoration: TextDecoration.underline, decorationColor: AppTheme.voltLime),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _initials(String n) => Center(
        child: Text(
          n.isNotEmpty ? n[0].toUpperCase() : 'S',
          style: AppTheme.bigNum(26, color: AppTheme.voltLime),
        ),
      );
}

class _FieldBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _FieldBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTheme.label(10, color: AppTheme.ink3)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 10),
              ),
            ]),
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.only(left: 38), child: child),
          ],
        ),
      );
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveButton({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.voltLime,
            foregroundColor: AppTheme.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg),
                )
              : Text('Save Changes →', style: AppTheme.bigNum(17, color: AppTheme.bg)),
        ),
      );
}

class _UsernameField extends StatelessWidget {
  final TextEditingController ctrl;
  final String status;
  const _UsernameField({required this.ctrl, required this.status});

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.border;
    Widget? trailing;

    switch (status) {
      case 'checking':
        trailing = const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.voltLime),
        );
      case 'available':
        borderColor = AppTheme.voltLime;
        trailing = const Icon(Icons.check_circle_rounded, color: AppTheme.voltLime, size: 18);
      case 'taken':
        borderColor = Color(0xFFFF4D4D);
        trailing = const Icon(Icons.cancel_rounded, color: Color(0xFFFF4D4D), size: 18);
      case 'invalid':
        borderColor = Color(0xFFFF4D4D);
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('USERNAME', style: AppTheme.label(10, color: AppTheme.ink3)
            .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text('@', style: AppTheme.label(14, color: AppTheme.ink2)),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                style: AppTheme.label(14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'your_username',
                  hintStyle: AppTheme.label(14, color: AppTheme.ink3),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  suffixIcon: trailing != null ? Padding(padding: const EdgeInsets.only(right: 12), child: trailing) : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ),
          ]),
        ),
        if (status == 'invalid')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('3–20 chars · letters, numbers, underscores only',
                style: AppTheme.label(11, color: Color(0xFFFF4D4D))),
          ),
        if (status == 'taken')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('Username taken — try adding numbers or underscores',
                style: AppTheme.label(11, color: Color(0xFFFF4D4D))),
          ),
        if (status == 'available')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('Username available',
                style: AppTheme.label(11, color: AppTheme.voltLime)),
          ),
      ],
    );
  }
}
