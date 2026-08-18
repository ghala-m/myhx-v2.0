import 'package:flutter/material.dart';

/// Modern semantic color system for myhx.
///
/// All colors are defined as static constants so they can be used directly
/// in widgets or referenced from [AppTheme].
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00A9B8);
  static const Color primaryDark = Color(0xFF007A86);
  static const Color primaryLight = Color(0xFF5DD6E3);
  static const Color primaryContainer = Color(0xFFD6F5F8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary / Accent
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryContainer = Color(0xFFE0E7FF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // Dark theme
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF151B2B);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF334155);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF00A9B8), Color(0xFF007A86)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
