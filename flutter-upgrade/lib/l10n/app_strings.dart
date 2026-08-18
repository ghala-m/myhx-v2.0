import 'package:flutter/widgets.dart';

/// Lightweight bilingual (English / Arabic) string table for myhx.
///
/// Usage:  `S.of(context).t('dashboard')`
class S {
  final Locale locale;
  const S(this.locale);

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static S of(BuildContext context) => S(Localizations.localeOf(context));

  bool get isArabic => locale.languageCode == 'ar';

  String t(String key) {
    final table = isArabic ? _ar : _en;
    return table[key] ?? _en[key] ?? key;
  }

  static const Map<String, String> _en = {
    // General
    'appName': 'myhx',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'retry': 'Retry',
    'close': 'Close',
    'next': 'Next',
    'back': 'Back',
    'done': 'Done',
    'loading': 'Loading…',
    'noData': 'Nothing here yet',
    'required': 'Required',
    'optional': 'Optional',

    // Auth
    'login': 'Log in',
    'signup': 'Create account',
    'logout': 'Log out',
    'email': 'Email',
    'password': 'Password',
    'forgotPassword': 'Forgot password?',

    // Navigation
    'dashboard': 'Dashboard',
    'patients': 'Patients',
    'reports': 'Reports',
    'analytics': 'Analytics',
    'settings': 'Settings',

    // Patients
    'addPatient': 'Add patient',
    'patientName': 'Patient name',
    'age': 'Age',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'department': 'Department',
    'ward': 'Ward',
    'room': 'Room',
    'notes': 'Notes',
    'recentPatients': 'Recent patients',
    'allPatients': 'All patients',
    'timeline': 'Timeline',

    // History
    'medicalHistory': 'Medical history',
    'chiefComplaint': 'Chief complaint',
    'symptoms': 'Symptoms',
    'progress': 'Progress',
    'summary': 'Summary',
    'startDictation': 'Start dictation',
    'stopDictation': 'Stop dictation',
    'listening': 'Listening…',
    'voiceUnavailable': 'Voice input is not available on this device',

    // AI
    'aiAnalysis': 'AI analysis',
    'differential': 'Differential diagnosis',
    'redFlags': 'Red flags',
    'noRedFlags': 'No red flags detected',
    'recommendations': 'Recommendations',
    'soapNote': 'SOAP note',
    'subjective': 'Subjective',
    'objective': 'Objective',
    'assessment': 'Assessment',
    'plan': 'Plan',
    'riskLevel': 'Risk level',
    'confidence': 'Confidence',
    'urgent': 'Urgent',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
    'aiDisclaimer':
        'AI output is decision support only. Always apply your own clinical judgement.',

    // Analytics
    'totalPatients': 'Total patients',
    'completedHistories': 'Completed histories',
    'urgentCases': 'Urgent cases',
    'thisWeek': 'This week',
    'byDepartment': 'By department',
    'byRisk': 'By risk',
    'ageDistribution': 'Age distribution',
    'activity': 'Activity',

    // Offline
    'offline': 'Offline',
    'offlineBanner': 'You are offline — changes are saved on this device',
    'syncing': 'Syncing…',
    'synced': 'All changes synced',
    'pendingChanges': 'pending changes',
    'syncNow': 'Sync now',

    // Settings
    'language': 'Language',
    'theme': 'Appearance',
    'lightMode': 'Light',
    'darkMode': 'Dark',
    'systemMode': 'System',
    'account': 'Account',
    'about': 'About',
  };

  static const Map<String, String> _ar = {
    'appName': 'myhx',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'edit': 'تعديل',
    'search': 'بحث',
    'retry': 'إعادة المحاولة',
    'close': 'إغلاق',
    'next': 'التالي',
    'back': 'رجوع',
    'done': 'تم',
    'loading': 'جارٍ التحميل…',
    'noData': 'لا توجد بيانات بعد',
    'required': 'مطلوب',
    'optional': 'اختياري',

    'login': 'تسجيل الدخول',
    'signup': 'إنشاء حساب',
    'logout': 'تسجيل الخروج',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'forgotPassword': 'نسيت كلمة المرور؟',

    'dashboard': 'الرئيسية',
    'patients': 'المرضى',
    'reports': 'التقارير',
    'analytics': 'الإحصائيات',
    'settings': 'الإعدادات',

    'addPatient': 'إضافة مريض',
    'patientName': 'اسم المريض',
    'age': 'العمر',
    'gender': 'الجنس',
    'male': 'ذكر',
    'female': 'أنثى',
    'department': 'القسم',
    'ward': 'الجناح',
    'room': 'الغرفة',
    'notes': 'ملاحظات',
    'recentPatients': 'المرضى الأخيرون',
    'allPatients': 'جميع المرضى',
    'timeline': 'الخط الزمني',

    'medicalHistory': 'التاريخ المرضي',
    'chiefComplaint': 'الشكوى الرئيسية',
    'symptoms': 'الأعراض',
    'progress': 'التقدم',
    'summary': 'الملخص',
    'startDictation': 'بدء الإملاء الصوتي',
    'stopDictation': 'إيقاف الإملاء',
    'listening': 'يتم الاستماع…',
    'voiceUnavailable': 'الإدخال الصوتي غير متاح على هذا الجهاز',

    'aiAnalysis': 'تحليل الذكاء الاصطناعي',
    'differential': 'التشخيص التفريقي',
    'redFlags': 'علامات الخطر',
    'noRedFlags': 'لا توجد علامات خطر',
    'recommendations': 'التوصيات',
    'soapNote': 'ملاحظة SOAP',
    'subjective': 'ذاتي',
    'objective': 'موضوعي',
    'assessment': 'التقييم',
    'plan': 'الخطة',
    'riskLevel': 'مستوى الخطورة',
    'confidence': 'نسبة الثقة',
    'urgent': 'عاجل',
    'high': 'مرتفع',
    'medium': 'متوسط',
    'low': 'منخفض',
    'aiDisclaimer':
        'نتائج الذكاء الاصطناعي للمساعدة في القرار فقط. اعتمد دائماً على حكمك السريري.',

    'totalPatients': 'إجمالي المرضى',
    'completedHistories': 'التواريخ المكتملة',
    'urgentCases': 'الحالات العاجلة',
    'thisWeek': 'هذا الأسبوع',
    'byDepartment': 'حسب القسم',
    'byRisk': 'حسب الخطورة',
    'ageDistribution': 'توزيع الأعمار',
    'activity': 'النشاط',

    'offline': 'غير متصل',
    'offlineBanner': 'أنت غير متصل — يتم حفظ التغييرات على الجهاز',
    'syncing': 'جارٍ المزامنة…',
    'synced': 'تمت مزامنة جميع التغييرات',
    'pendingChanges': 'تغييرات معلّقة',
    'syncNow': 'مزامنة الآن',

    'language': 'اللغة',
    'theme': 'المظهر',
    'lightMode': 'فاتح',
    'darkMode': 'داكن',
    'systemMode': 'حسب النظام',
    'account': 'الحساب',
    'about': 'حول التطبيق',
  };
}

/// Convenience extension so screens can write `context.tr('dashboard')`.
extension AppStringsX on BuildContext {
  String tr(String key) => S.of(this).t(key);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
