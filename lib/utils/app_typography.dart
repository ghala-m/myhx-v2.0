import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles for the app.
///
/// Use these instead of inline `TextStyle(...)` to keep typography consistent.
class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter();

  static TextStyle displayLarge(BuildContext context) => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.5,
      );

  static TextStyle displayMedium(BuildContext context) => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.3,
      );

  static TextStyle titleLarge(BuildContext context) => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle titleMedium(BuildContext context) => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodyLarge(BuildContext context) => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle bodyMedium(BuildContext context) => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle labelLarge(BuildContext context) => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle button(BuildContext context) => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle caption(BuildContext context) => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}
