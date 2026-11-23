import 'package:flutter/material.dart';

/// Warna e-SKPB, diambil dari Figma (Colour Palette + frame HI-fi).
class AppColors {
  AppColors._();

  // Palet hijau-teal (token green-50 .. green-900)
  static const green50 = Color(0xFFE6EEF0);
  static const green100 = Color(0xFFB0CAD0);
  static const green200 = Color(0xFF8AB1B9);
  static const green300 = Color(0xFF548D98);
  static const green400 = Color(0xFF337785);
  static const green500 = Color(0xFF005566); // warna utama
  static const green600 = Color(0xFF004D5D);
  static const green700 = Color(0xFF003C48);
  static const green800 = Color(0xFF002F38);
  static const green900 = Color(0xFF00242B);

  // Semantik
  static const primary = green500;
  static const background = Color(0xFFF4FAF9);
  static const surface = Colors.white;
  static const border = green200;
  static const textStrong = Color(0xFF042129);
  static const textBody = green700;
  static const textMuted = Color(0xFF3B7380);
  static const disabledFill = green100;
  static const disabledText = green300;

  // Pil dan aksen
  static const tealTint = Color(0xFFE5F5F2); // pil netral, item nav aktif
  static const queueTint = Color(0xFFFFF2D6);
  static const queueText = Color(0xFFEB8C14);
  static const quotaIconTint = Color(0xFFE5F2FF);
  static const validateIconTint = Color(0xFFE5FAF0);
  static const queueIconTint = Color(0xFFFFF5E0);

  // Kartu ringkasan semester di Beranda
  static const summaryBackground = green700;
  static const summaryTile = Color(0xFF096373);
  static const summaryLabel = Color(0xFFABDBE0);
  static const summarySubtle = Color(0xFFC2E5E8);

  // Status
  static const success = Color(0xFF0F9452);
  static const warning = Color(0xFFF57A08);
  static const info = Color(0xFF2470B8);
  static const danger = Color(0xFFD64545);
}
