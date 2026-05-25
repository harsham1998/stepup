import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());
  bool _otpSent = false, _loading = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0)
          _resendSeconds--;
        else
          t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendOtp(_phoneCtrl.text);
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      _startResendTimer();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isNewUser =
          await ref.read(authServiceProvider).verifyOtp(_phoneCtrl.text, otp);
      if (mounted) context.go(isNewUser ? '/onboard' : '/home');
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: _otpSent
                    ? () => setState(() {
                          _otpSent = false;
                          _error = null;
                        })
                    : () => context.go('/'),
                child: Row(children: [
                  const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _otpSent ? '+91 ${_phoneCtrl.text} · Edit' : 'Back',
                    style: AppTheme.label(13, color: AppTheme.ink2),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              Text(
                _otpSent ? "Verify it's you." : "Let's go.",
                style: AppTheme.bigNum(30),
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? '6-digit code sent · auto-detecting'
                    : 'Enter your phone, we’ll send an OTP',
                style: AppTheme.label(13, color: AppTheme.ink2),
              ),
              const SizedBox(height: 28),
              if (!_otpSent) ...[
                _PhoneBox(controller: _phoneCtrl),
                const SizedBox(height: 6),
                Text(
                  'By continuing you agree to our terms',
                  style: AppTheme.label(11, color: AppTheme.ink3),
                ),
                const SizedBox(height: 20),
                _GoldButton(
                    label: 'Send OTP →', loading: _loading, onPressed: _sendOtp),
                const SizedBox(height: 20),
                _OrDivider(),
                const SizedBox(height: 16),
                _SocialButton(
                  glyph: 'G',
                  label: 'Continue with Google',
                  onPressed: () =>
                      ref.read(authServiceProvider).signInWithGoogle(),
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  glyph: '',
                  label: 'Continue with Apple',
                  dark: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 40),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.label(12, color: AppTheme.ink3),
                      children: [
                        const TextSpan(text: 'New here? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.go('/onboard'),
                            child: Text(
                              'Create account',
                              style: AppTheme.label(12,
                                  color: AppTheme.voltLime),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                _OtpRow(
                    ctrls: _otpCtrls,
                    focuses: _otpFocuses,
                    onComplete: _verifyOtp),
                const SizedBox(height: 16),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.label(13, color: AppTheme.ink2),
                      children: [
                        const TextSpan(text: "Didn't get it? "),
                        TextSpan(
                          text: _resendSeconds > 0
                              ? 'Resend in 0:${_resendSeconds.toString().padLeft(2, '0')}'
                              : 'Resend',
                          style: TextStyle(
                              color: _resendSeconds > 0
                                  ? AppTheme.ink3
                                  : AppTheme.voltLime),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: AppTheme.label(12,
                          color: const Color(0xFFEF4444))),
                ],
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                    child: _GhostButton(
                        label: 'Resend',
                        onPressed: _resendSeconds == 0 ? _sendOtp : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GoldButton(
                        label: 'Verify →',
                        loading: _loading,
                        onPressed: _verifyOtp),
                  ),
                ]),
              ],
              if (_error != null && !_otpSent) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppTheme.label(12,
                        color: const Color(0xFFEF4444))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneBox extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneBox({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Text('+91', style: AppTheme.bigNum(16)),
          const SizedBox(width: 10),
          Container(width: 1, height: 18, color: AppTheme.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: AppTheme.bigNum(20),
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: AppTheme.bigNum(20, color: AppTheme.ink3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ]),
      );
}

class _OtpRow extends StatelessWidget {
  final List<TextEditingController> ctrls;
  final List<FocusNode> focuses;
  final VoidCallback onComplete;
  const _OtpRow(
      {required this.ctrls,
      required this.focuses,
      required this.onComplete});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (i) => SizedBox(
            width: 46,
            height: 54,
            child: TextField(
              controller: ctrls[i],
              focusNode: focuses[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: AppTheme.bigNum(22),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.voltLime, width: 1.5),
                ),
              ),
              onChanged: (v) {
                if (v.isNotEmpty) {
                  if (i < 5)
                    focuses[i + 1].requestFocus();
                  else {
                    focuses[i].unfocus();
                    onComplete();
                  }
                } else if (i > 0) {
                  focuses[i - 1].requestFocus();
                }
              },
            ),
          ),
        ),
      );
}

class _GoldButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const _GoldButton(
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

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GhostButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
                color: onPressed != null ? AppTheme.border : AppTheme.ink3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          ),
          child: Text(label, style: AppTheme.label(14)),
        ),
      );
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Divider(
                color: AppTheme.ink3.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or',
              style: AppTheme.label(12, color: AppTheme.ink3)),
        ),
        Expanded(
            child: Divider(
                color: AppTheme.ink3.withValues(alpha: 0.3))),
      ]);
}

class _SocialButton extends StatelessWidget {
  final String glyph, label;
  final bool dark;
  final VoidCallback onPressed;
  const _SocialButton(
      {required this.glyph,
      required this.label,
      required this.onPressed,
      this.dark = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: dark ? Colors.white : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: dark ? Colors.transparent : AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: dark ? AppTheme.bg : AppTheme.surface2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    glyph,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTheme.label(14,
                    color: dark ? AppTheme.bg : Colors.white),
              ),
            ],
          ),
        ),
      );
}
