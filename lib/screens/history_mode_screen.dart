// Choose how to take the history: department question bank, quick specialty
// template, or the full adaptive questionnaire.
// lib/screens/history_mode_screen.dart

import 'package:flutter/material.dart';

import '../data/departments.dart';
import '../data/specialty_templates.dart';
import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/question_bank_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/department_icons.dart';
import '../widgets/app_card.dart';
import 'dynamic_medical_history_screen.dart';
import 'quick_history_screen.dart';

class HistoryModeScreen extends StatefulWidget {
  final Patient patient;

  const HistoryModeScreen({super.key, required this.patient});

  @override
  State<HistoryModeScreen> createState() => _HistoryModeScreenState();
}

class _HistoryModeScreenState extends State<HistoryModeScreen> {
  SpecialtyTemplate? _departmentTemplate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartmentQuestions();
  }

  Future<void> _loadDepartmentQuestions() async {
    final dept = Departments.byId(widget.patient.department) ??
        Departments.match(widget.patient.department);
    final id = dept?.id ?? widget.patient.department;
    final questions = await QuestionBankService.instance.forDepartment(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _departmentTemplate = SpecialtyTemplate(
        id: id,
        nameEn: dept?.nameEn ?? widget.patient.department,
        nameAr: dept?.nameAr ?? widget.patient.department,
        icon: dept?.icon ?? 'local_hospital',
        questions: questions,
      );
    });
  }

  void _openTemplate(SpecialtyTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuickHistoryScreen(patient: widget.patient, template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabic = S.of(context).isArabic;
    final suggested = SpecialtyTemplates.forDepartment(widget.patient.department);
    final templates = [
      if (suggested != null) suggested,
      ...SpecialtyTemplates.all.where((t) => t.id != suggested?.id),
    ];
    final deptTemplate = _departmentTemplate;

    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            arabic
                ? 'كيف تريد أخذ التاريخ المرضي؟'
                : 'How do you want to take the history?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (deptTemplate != null && deptTemplate.questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                border: Border.all(color: AppColors.primary, width: 1.5),
                onTap: () => _openTemplate(deptTemplate),
                child: Row(
                  children: [
                    Icon(DepartmentIcons.resolve(deptTemplate.icon),
                        color: AppColors.primary, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arabic
                                ? 'أسئلة قسم ${deptTemplate.name(true)}'
                                : '${deptTemplate.name(false)} department questions',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            arabic
                                ? '${deptTemplate.questions.length} سؤال مخصص لهذا القسم'
                                : '${deptTemplate.questions.length} questions tailored to this department',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DynamicMedicalHistoryScreen(
                  patient: {
                    'id': widget.patient.id,
                    'name': widget.patient.name,
                    'age': widget.patient.age,
                    'gender': widget.patient.gender,
                    'department': widget.patient.department,
                  },
                  department: widget.patient.department,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: AppColors.primary, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(arabic ? 'التاريخ الكامل' : 'Full history',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        arabic
                            ? 'أسئلة ذكية متسلسلة تغطي كل الأنظمة'
                            : 'Adaptive step-by-step questionnaire, all systems',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            arabic ? 'تاريخ سريع حسب التخصص' : 'Quick history by specialty',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...templates.map((t) {
            final isSuggested = t.id == suggested?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                border: isSuggested
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
                onTap: () => _openTemplate(t),
                child: Row(
                  children: [
                    Icon(DepartmentIcons.resolve(t.icon), color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(t.name(arabic),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (isSuggested)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          arabic ? 'مقترح' : 'Suggested',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${t.questions.length}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
