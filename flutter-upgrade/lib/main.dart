import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/offline_service.dart';
import 'services/feedback_service.dart';
import 'services/role_service.dart';
import 'utils/theme_provider.dart';
import 'utils/locale_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final feedbackService = FeedbackService();
  await feedbackService.load();

  final roleService = RoleService();
  await roleService.load();

  final offlineService = OfflineService();
  await offlineService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: offlineService),
        ChangeNotifierProvider.value(value: feedbackService),
        ChangeNotifierProvider.value(value: roleService),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: const MyHxApp(),
    ),
  );
}

class MyHxApp extends StatelessWidget {
  const MyHxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final palette = themeProvider.palette;

    return MaterialApp(
      title: 'myhx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightOf(palette),
      darkTheme: AppTheme.darkOf(palette),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection:
            localeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthWrapper(),
    );
  }
}
