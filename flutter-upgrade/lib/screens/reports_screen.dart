import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import 'patient_record_screen.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/doctor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("All Reports")),
        body: const Center(child: Text("Please log in to view reports.")),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("All Reports"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 60, color: colors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'هذه الميزة ستطلق رسميًا في الإصدار القادم.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
