import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi Inter. Ukuran mengikuti Figma (9, 10, 11, 12, 14, 15, 18, 25, 28).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter(double size, FontWeight weight, Color color) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  static final display = _inter(28, FontWeight.w700, AppColors.textStrong);
  static final headline = _inter(25, FontWeight.w700, Colors.white);
  static final metric = _inter(18, FontWeight.w700, Colors.white);
  static final title = _inter(15, FontWeight.w700, AppColors.textStrong);
  static final heading = _inter(14, FontWeight.w700, AppColors.textStrong);
  static final label = _inter(12, FontWeight.w600, AppColors.textBody);
  static final bodyLarge = _inter(12, FontWeight.w400, AppColors.textBody);
  static final body = _inter(11, FontWeight.w400, AppColors.textMuted);
  static final bodyBold = _inter(11, FontWeight.w700, AppColors.textStrong);
  static final caption = _inter(10, FontWeight.w400, AppColors.textMuted);
  static final captionBold = _inter(10, FontWeight.w600, AppColors.primary);
  static final micro = _inter(9, FontWeight.w400, AppColors.textMuted);
  static final microBold = _inter(9, FontWeight.w600, AppColors.primary);
}
