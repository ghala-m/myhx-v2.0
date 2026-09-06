import 'package:flutter/material.dart';

import '../data/departments.dart';
import '../data/specialty_templates.dart';
import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/question_bank_service.dart';
import 'quick_history_screen.dart';

/// The single entry point after adding a patient. No decision screen, no
/// extra tap: it loads the department-tailored question set (the
/// recommended default for that patient's department, merged from
/// DepartmentQuestions + any developer customisations in the question
/// bank) and lands the user straight in it.
///
/// The old HistoryModeScreen (full history / quick specialty templates /
/// a different department's questions) is still one tap away via the
/// "change question set" icon in QuickHistoryScreen's app bar — it just
/// isn't forced on every single patient anymore.
class HistoryEntryScreen extends StatefulWidget {
  final Patient patient;

  const HistoryEntryScreen({super.key, required this.patient});

  @override
  State<HistoryEntryScreen> createState() => _HistoryEntryScreenState();
}

class _HistoryEntryScreenState extends State<HistoryEntryScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndContinue();
  }

  Future<void> _loadAndContinue() async {
    final dept = Departments.byId(widget.patient.department) ??
        Departments.match(widget.patient.department);
    final id = dept?.id ?? widget.patient.department;
    final questions = await QuestionBankService.instance.forDepartment(id);

    if (!mounted) return;

    final template = SpecialtyTemplate(
      id: id,
      nameEn: dept?.nameEn ?? widget.patient.department,
      nameAr: dept?.nameAr ?? widget.patient.department,
      icon: dept?.icon ?? 'local_hospital',
      questions: questions,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            QuickHistoryScreen(patient: widget.patient, template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabic = S.of(context).isArabic;
    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              arabic
                  ? 'تجهيز أسئلة القسم...'
                  : 'Preparing department questions...',
            ),
          ],
        ),
      ),
    );
  }
}
