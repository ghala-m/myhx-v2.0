// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:myhx_app/screens/login_screen.dart'; // تم تصحيح المسار
import 'package:myhx_app/screens/main_shell.dart';
import 'package:myhx_app/services/auth_service.dart'; // تم تصحيح المسار

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // الوصول إلى AuthService

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // المستخدم مسجل للدخول
          return const MainShell();
        } else {
          // المستخدم غير مسجل للدخول
          return const LoginScreen();
        }
      },
    );
  }
}
