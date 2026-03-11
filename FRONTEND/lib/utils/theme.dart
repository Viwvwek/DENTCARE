import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF0F172A); // Deep Slate
  static const Color accent = Color(0xFF2DD4BF);  // Vibrant Mint
  static const Color background = Color(0xFFF8FAFC); // Soft White
  static const Color surface = Colors.white;
  static const Color secondaryText = Color(0xFF64748B);
  
  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2DD4BF),
      Color(0xFF14B8A6),
    ],
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> accentShadow = [
    BoxShadow(
      color: const Color(0xFF2DD4BF).withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Text Styles (Assuming system font for now)
  static const TextStyle heading = TextStyle(
    color: primary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeading = TextStyle(
    color: secondaryText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardTitle = TextStyle(
    color: primary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
