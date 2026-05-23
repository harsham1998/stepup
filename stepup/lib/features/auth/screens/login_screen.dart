import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/neon_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrls = List.generate(4, (_) => TextEditingController());
  bool _otpSent = false, _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).sendOtp(_phoneCtrl.text);
      setState(() { _otpSent = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length != 4) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).verifyOtp(_phoneCtrl.text, otp);
      if (mounted) context.go('/onboard');
      return; // navigation disposes the widget — don't reset loading
    } catch (e) {
      if (mounted) setState(() { _error = 'Invalid OTP. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Sign In',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Enter your number to receive an OTP',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 28),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700),
                  hintText: '98765 43210',
                  hintStyle: TextStyle(color: Color(0xFF4B5563)),
                  counterText: '',
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 20),
                Text('OTP sent to +91 ${_phoneCtrl.text}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                    width: 52, height: 56, margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _otpCtrls[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        counterText: '',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) FocusScope.of(context).nextFocus();
                      },
                    ),
                  )),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              ],
              const SizedBox(height: 24),
              NeonButton(
                label: _otpSent ? 'Verify & Continue' : 'Send OTP',
                onPressed: _otpSent ? _verifyOtp : _sendOtp,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
              Row(children: const [
                Expanded(child: Divider(color: Color(0xFF1F2937))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12)),
                ),
                Expanded(child: Divider(color: Color(0xFF1F2937))),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata, size: 20),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1F2937)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
