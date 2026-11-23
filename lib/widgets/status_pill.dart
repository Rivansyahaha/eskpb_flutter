import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// Badge status kuota: nilai sama dengan kolom `status_kuota` di v_kelas.
enum QuotaStatus {
  tersedia('Tersedia'),
  hampirPenuh('Hampir Penuh'),
  penuh('Penuh');

  const QuotaStatus(this.label);
  final String label;

  static QuotaStatus fromDb(String? value) => switch (value) {
        'hampir_penuh' => QuotaStatus.hampirPenuh,
        'penuh' => QuotaStatus.penuh,
        _ => QuotaStatus.tersedia,
      };
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final QuotaStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color border, Color text) = switch (status) {
      QuotaStatus.tersedia =>
        (AppColors.green50, AppColors.primary, AppColors.textBody),
      QuotaStatus.hampirPenuh =>
        (AppColors.green100, AppColors.green700, AppColors.textBody),
      QuotaStatus.penuh =>
        (const Color(0xFFFBE4E4), AppColors.danger, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Text(status.label, style: AppTextStyles.label.copyWith(color: text)),
    );
  }
}

/// Pil kecil serbaguna (mis. "ANTREAN AKTIF", "± 25 menit", "SELASA").
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.text,
    this.background = AppColors.tealTint,
    this.foreground = AppColors.primary,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.captionBold.copyWith(color: foreground),
      ),
    );
  }
}
