import 'package:flutter/material.dart';

/// Gambar dari assets dengan cadangan (ikon/widget) kalau berkas belum ada.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.fallback,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}

/// Lokasi berkas gambar dari Figma.
class AppAssets {
  AppAssets._();

  static const itsEmblem = 'assets/images/its_emblem.png';
  static const campus = 'assets/images/campus_illustration.png';
  static const logo = 'assets/images/eskpb_logo.png';
  static const itsLogo = 'assets/images/its_logo.png';
  static const loginHeader = 'assets/images/login_header.jpg';
}
