// Quick specialty-template history (تاريخ سريع حسب التخصص)
// lib/screens/quick_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/specialty_templates.dart';
import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/clinical_ai_service.dart';
import '../services/database_service.dart';
import '../services/feedback_service.dart';
import '../utils/english_input.dart';
import '../utils/app_colors.dart';
import '../utils/app_logger.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/voice_input_button.dart';
import 'patient_record_screen.dart';
import 'history_mode_screen.dart';

class QuickHistoryScreen extends StatefulWidget {
  final Patient patient;
  final SpecialtyTemplate template;

  const QuickHistoryScreen({
    super.key,
    required this.patient,
    required this.template,
  });

  @override
  State<QuickHistoryScreen> createState() => _QuickHistoryScreenState();
}

class _QuickHistoryScreenState extends State<QuickHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  final ClinicalAIService _ai = ClinicalAIService();

  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  TextEditingController _controllerFor(String id) =>
      _controllers.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _answered =>
      _answers.values.where((v) => v != null && v.toString().trim().isNotEmpty).length;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final arabic = S.of(context).isArabic;
      final history = <String, dynamic>{
        'template_id': widget.template.id,
        'template_name': widget.template.name(arabic),
        'mode': 'quick',
      };
      final symptoms = <String>[];

      for (final q in widget.template.questions) {
        final value = _answers[q.id];
        if (value == null || value.toString().trim().isEmpty) continue;
        history[q.label(false)] = value;
        if (value is bool) {
          if (value) symptoms.add(q.en);
        } else {
          symptoms.add(value.toString());
        }
      }

      final analysis = await _ai.analyze(
        symptoms: symptoms,
        patient: widget.patient,
        answers: history,
        chiefComplaint: symptoms.isNotEmpty ? symptoms.first : null,
      );

      final reportId = await _db.createReport(
        doctorId: user.uid,
        patientId: widget.patient.id,
        patient: widget.patient,
        medicalHistory: history,
        aiAnalysis: analysis.toJson(),
      );

      // تصعيد تلقائي: لو التحليل السريري أظهر خطورة عاجلة/عالية، يضع
      // النظام علامة "طارئ" على المريض تلقائيًا.
      if (analysis.riskLevel == 'Urgent' || analysis.riskLevel == 'High') {
        try {
          await _db.setPatientUrgent(widget.patient.id, true, source: 'system');
        } catch (e) {
          AppLogger.e('Failed to auto-flag patient as urgent', error: e);
        }
      }

      if (!mounted) return;
      context.read<FeedbackService>().success();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              PatientRecordScreen(reportId: reportId, patient: widget.patient),
        ),
      );
    } catch (e) {
      if (mounted) {
        context.read<FeedbackService>().error();
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic = S.of(context).isArabic;
    final theme = Theme.of(context);
    final total = widget.template.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name(arabic)),
        actions: [
          IconButton(
            tooltip: arabic ? 'تغيير مجموعة الأسئلة' : 'Change question set',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HistoryModeScreen(patient: widget.patient),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            color: AppColors.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.patient.name} · $_answered / $total',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...widget.template.questions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildQuestion(q, arabic),
              )),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: context.tr('save'),
            icon: Icons.check_circle_outline,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
            width: double.infinity,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildQuestion(TemplateQuestion q, bool arabic) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(q.label(arabic),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (q.critical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Text(
                    'Critical',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInput(q, arabic),
        ],
      ),
    );
  }

  Widget _buildInput(TemplateQuestion q, bool arabic) {
    switch (q.type) {
      case 'boolean':
        final value = _answers[q.id] as bool?;
        return Row(
          children: [
            for (final entry in {true: 'Yes / نعم', false: 'No / لا'}.entries)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: value == entry.key,
                  onSelected: (_) => setState(() => _answers[q.id] = entry.key),
                ),
              ),
          ],
        );
      case 'select':
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: q.options
              .map((o) => ChoiceChip(
                    label: Text(o),
                    selected: _answers[q.id] == o,
                    onSelected: (_) => setState(() => _answers[q.id] = o),
                  ))
              .toList(),
        );
      case 'number':
        return TextField(
          controller: _controllerFor(q.id),
          keyboardType: TextInputType.number,
          inputFormatters: EnglishInput.formatters,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _answers[q.id] = v),
        );
      default:
        final isArea = q.type == 'textarea';
        final controller = _controllerFor(q.id);
        return TextField(
          controller: controller,
          maxLines: isArea ? 4 : 1,
          inputFormatters: EnglishInput.formatters,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: VoiceInputButton(
              arabic: arabic,
              onTranscript: (text) {
                controller.text = text;
                setState(() => _answers[q.id] = text);
              },
            ),
          ),
          onChanged: (v) => setState(() => _answers[q.id] = v),
        );
    }
  }
}
