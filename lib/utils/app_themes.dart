import 'package:flutter/material.dart';

/// A selectable colour palette for the app.
class AppPalette {
  final String id;
  final String nameEn;
  final String nameAr;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;

  const AppPalette({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
  });

  String name(bool arabic) => arabic ? nameAr : nameEn;

  LinearGradient get gradient => LinearGradient(
        colors: [primaryLight, primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradient => LinearGradient(
        colors: [primary, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppPalettes {
  AppPalettes._();

  static const teal = AppPalette(
    id: 'teal',
    nameEn: 'Clinical Teal',
    nameAr: 'أزرق طبي',
    primary: Color(0xFF00A9B8),
    primaryDark: Color(0xFF007A86),
    primaryLight: Color(0xFF5DD6E3),
    secondary: Color(0xFF6366F1),
  );

  static const indigo = AppPalette(
    id: 'indigo',
    nameEn: 'Deep Indigo',
    nameAr: 'نيلي عميق',
    primary: Color(0xFF4F46E5),
    primaryDark: Color(0xFF3730A3),
    primaryLight: Color(0xFF818CF8),
    secondary: Color(0xFF06B6D4),
  );

  static const emerald = AppPalette(
    id: 'emerald',
    nameEn: 'Emerald Ward',
    nameAr: 'أخضر زمردي',
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF047857),
    primaryLight: Color(0xFF34D399),
    secondary: Color(0xFF0EA5E9),
  );

  static const rose = AppPalette(
    id: 'rose',
    nameEn: 'Rose Clinic',
    nameAr: 'وردي هادئ',
    primary: Color(0xFFE11D48),
    primaryDark: Color(0xFF9F1239),
    primaryLight: Color(0xFFFB7185),
    secondary: Color(0xFF7C3AED),
  );

  static const amber = AppPalette(
    id: 'amber',
    nameEn: 'Warm Amber',
    nameAr: 'كهرماني دافئ',
    primary: Color(0xFFD97706),
    primaryDark: Color(0xFF92400E),
    primaryLight: Color(0xFFFBBF24),
    secondary: Color(0xFF0F766E),
  );

  static const slate = AppPalette(
    id: 'slate',
    nameEn: 'Graphite',
    nameAr: 'رمادي جرافيت',
    primary: Color(0xFF334155),
    primaryDark: Color(0xFF0F172A),
    primaryLight: Color(0xFF64748B),
    secondary: Color(0xFF0891B2),
  );

  static const List<AppPalette> all = [teal, indigo, emerald, rose, amber, slate];

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => teal);
}
