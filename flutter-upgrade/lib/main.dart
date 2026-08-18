// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myhx_app/utils/theme_provider.dart'; 
import 'package:myhx_app/utils/theme.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:myhx_app/firebase_options.dart'; 
import 'package:myhx_app/auth_wrapper.dart'; 
import 'package:myhx_app/services/auth_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(ThemeMode.dark)),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'myhx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }
}
