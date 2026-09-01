// Choose how to take the history: quick specialty template or full questionnaire.
// lib/screens/history_mode_screen.dart

import 'package:flutter/material.dart';

import '../data/specialty_templates.dart';
import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_card.dart';
import 'dynamic_medical_history_screen.dart';
import 'quick_history_screen.dart';

class HistoryModeScreen extends StatelessWidget {
  final Patient patient;

  const HistoryModeScreen({super.key, required this.patient});

  static const Map<String, IconData> _icons = {
    'favorite': Icons.favorite,
    'medical_services': Icons.medical_services,
    'child_care': Icons.child_care,
    'healing': Icons.healing,
    'psychology': Icons.psychology,
    'pregnant_woman': Icons.pregnant_woman,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabic = S.of(context).isArabic;
    final suggested = SpecialtyTemplates.forDepartment(patient.department);
    final templates = [
      if (suggested != null) suggested,
      ...SpecialtyTemplates.all.where((t) => t.id != suggested?.id),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            arabic ? 'كيف تريد أخذ التاريخ المرضي؟' : 'How do you want to take the history?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DynamicMedicalHistoryScreen(
                  patient: {
                    'id': patient.id,
                    'name': patient.name,
                    'age': patient.age,
                    'gender': patient.gender,
                    'department': patient.department,
                  },
                  department: patient.department,
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        QuickHistoryScreen(patient: patient, template: t),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_icons[t.icon] ?? Icons.medical_information,
                        color: AppColors.primary),
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
