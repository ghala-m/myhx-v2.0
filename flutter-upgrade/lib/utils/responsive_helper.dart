import 'package:flutter/material.dart';

class ResponsiveHelper {
  // نقاط التوقف للشاشات المختلفة
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // التحقق من نوع الجهاز
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // الحصول على نوع الجهاز كنص
  static String getDeviceType(BuildContext context) {
    if (isMobile(context)) return 'Mobile';
    if (isTablet(context)) return 'Tablet';
    return 'Desktop';
  }

  // الحصول على عدد الأعمدة المناسب للشبكة
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  // الحصول على الحشو المناسب
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  // الحصول على عرض المحتوى الأقصى
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }

  // الحصول على حجم الخط المناسب
  static double getFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) return baseFontSize;
    if (isTablet(context)) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }

  // الحصول على حجم الأيقونة المناسب
  static double getIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) return baseIconSize;
    if (isTablet(context)) return baseIconSize * 1.2;
    return baseIconSize * 1.4;
  }

  // الحصول على ارتفاع شريط التطبيق
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return kToolbarHeight;
    if (isTablet(context)) return kToolbarHeight * 1.2;
    return kToolbarHeight * 1.4;
  }

  // الحصول على حجم الصورة الرمزية
  static double getAvatarRadius(BuildContext context, double baseRadius) {
    if (isMobile(context)) return baseRadius;
    if (isTablet(context)) return baseRadius * 1.3;
    return baseRadius * 1.5;
  }

  // الحصول على المسافة بين العناصر
  static double getSpacing(BuildContext context, double baseSpacing) {
    if (isMobile(context)) return baseSpacing;
    if (isTablet(context)) return baseSpacing * 1.2;
    return baseSpacing * 1.5;
  }

  // الحصول على نصف قطر الحواف
  static double getBorderRadius(BuildContext context, double baseBorderRadius) {
    if (isMobile(context)) return baseBorderRadius;
    if (isTablet(context)) return baseBorderRadius * 1.2;
    return baseBorderRadius * 1.4;
  }

  // التحقق من الاتجاه
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // الحصول على عدد العناصر في الصف للقوائم
  static int getListItemsPerRow(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 2 : 1;
    }
    if (isTablet(context)) {
      return isLandscape(context) ? 3 : 2;
    }
    return isLandscape(context) ? 4 : 3;
  }

  // الحصول على حجم البطاقة المناسب
  static Size getCardSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (isMobile(context)) {
      return Size(screenSize.width - 32, 120);
    }
    if (isTablet(context)) {
      return Size((screenSize.width - 64) / 2, 140);
    }
    return Size((screenSize.width - 96) / 3, 160);
  }

  // الحصول على نمط التخطيط للوحة التحكم
  static String getDashboardLayout(BuildContext context) {
    if (isMobile(context)) return 'single_column';
    if (isTablet(context)) return 'two_column';
    return 'three_column';
  }

  // الحصول على حجم النافذة المنبثقة
  static Size getDialogSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (isMobile(context)) {
      return Size(screenSize.width * 0.9, screenSize.height * 0.8);
    }
    if (isTablet(context)) {
      return Size(screenSize.width * 0.7, screenSize.height * 0.7);
    }
    return Size(screenSize.width * 0.5, screenSize.height * 0.6);
  }

  // widget مساعد للتخطيط المتجاوب
  static Widget responsiveBuilder(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // widget للحاوية المتجاوبة
  static Widget responsiveContainer(
    BuildContext context, {
    required Widget child,
    bool centerContent = true,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: getMaxContentWidth(context),
      ),
      padding: getScreenPadding(context),
      child: centerContent ? Center(child: child) : child,
    );
  }
}

// Extension لتسهيل الاستخدام
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  String get deviceType => ResponsiveHelper.getDeviceType(this);
  
  EdgeInsets get screenPadding => ResponsiveHelper.getScreenPadding(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  
  double fontSize(double base) => ResponsiveHelper.getFontSize(this, base);
  double iconSize(double base) => ResponsiveHelper.getIconSize(this, base);
  double spacing(double base) => ResponsiveHelper.getSpacing(this, base);
  double borderRadius(double base) => ResponsiveHelper.getBorderRadius(this, base);
}

