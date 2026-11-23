import 'package:flutter/material.dart';

/// Radius sesuai Figma: 8 (tombol/input), 12, 14, 16, 20, 99 (pil).
class AppRadius {
  AppRadius._();

  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const pill = 99.0;
}

class AppSpacing {
  AppSpacing._();

  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;

  /// Margin horizontal standar layar.
  static const screen = 16.0;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x1A002E38), // rgba(0,46,56,0.10)
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const nav = [
    BoxShadow(
      color: Color(0x29002E38), // rgba(0,46,56,0.16)
      blurRadius: 24,
      spreadRadius: -8,
      offset: Offset(0, -6),
    ),
  ];
}

/// Warna bayangan dan gradien yang dipakai lebih dari satu layar.
class AppGradients {
  AppGradients._();

  static const insight = LinearGradient(
    colors: [Color(0xFF05404F), Color(0xFF056170)],
  );
}
