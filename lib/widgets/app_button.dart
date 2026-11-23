import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

enum AppButtonType { primary, secondary }

/// Tombol e-SKPB: tinggi 48, radius 8. [onPressed] null = tampil nonaktif.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    final secondary = type == AppButtonType.secondary;

    final Color fill = disabled
        ? AppColors.disabledFill
        : secondary
            ? AppColors.surface
            : AppColors.primary;
    final Color border = disabled ? AppColors.disabledFill : AppColors.primary;
    final Color textColor = disabled
        ? AppColors.disabledText
        : secondary
            ? AppColors.primary
            : Colors.white;

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
          )
        : Text(label, style: AppTextStyles.label.copyWith(color: textColor));

    return SizedBox(
      height: 48,
      width: expanded ? double.infinity : null,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r8),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r8),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(widthFactor: expanded ? null : 1, child: child),
          ),
        ),
      ),
    );
  }
}
