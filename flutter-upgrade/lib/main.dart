import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/offline_service.dart';
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

  final offlineService = OfflineService();
  await offlineService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(ThemeMode.system)),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: offlineService),
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

    return MaterialApp(
      title: 'myhx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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
