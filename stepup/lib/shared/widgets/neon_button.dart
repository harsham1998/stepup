import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const NeonButton({
    required this.label, this.onPressed,
    this.isLoading = false, this.color, super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primary;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shadowColor: bg.withValues(alpha: 0.4),
          elevation: 8,
        ),
        child: isLoading
            ? const SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}
