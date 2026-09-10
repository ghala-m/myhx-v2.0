import 'package:flutter/material.dart';

import '../data/departments.dart';
import '../models/teaching_case.dart';
import '../services/teaching_case_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';

/// Browsable, fully de-identified past cases any signed-in user can
/// learn from — no name, exact age, or other identifier is ever present
/// (see models/teaching_case.dart for exactly what's stored).
class TeachingCasesScreen extends StatelessWidget {
  const TeachingCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TeachingCaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Teaching cases')),
      body: StreamBuilder<List<TeachingCase>>(
        stream: service.all(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No teaching cases shared yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              final dept = Departments.byId(c.department);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _TeachingCaseSheet(teachingCase: c),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(dept?.nameEn ?? c.department,
                                style: AppTypography.titleMedium(context)),
                          ),
                          if (c.riskLevel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c.riskLevel,
                                  style: const TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${c.ageRange} • ${c.gender}',
                          style: AppTypography.caption(context)),
                      if (c.chiefComplaint.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(c.chiefComplaint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium(context)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TeachingCaseSheet extends StatelessWidget {
  const _TeachingCaseSheet({required this.teachingCase});

  final TeachingCase teachingCase;

  @override
  Widget build(BuildContext context) {
    final dept = Departments.byId(teachingCase.department);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dept?.nameEn ?? teachingCase.department,
                style: AppTypography.titleLarge(context)),
            const SizedBox(height: 4),
            Text('${teachingCase.ageRange} • ${teachingCase.gender}',
                style: AppTypography.caption(context)),
            const SizedBox(height: AppSpacing.md),
            if (teachingCase.chiefComplaint.isNotEmpty) ...[
              Text('Chief complaint',
                  style: AppTypography.titleMedium(context)),
              Text(teachingCase.chiefComplaint,
                  style: AppTypography.bodyMedium(context)),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text('SOAP note', style: AppTypography.titleMedium(context)),
            Text(teachingCase.soapNote,
                style: AppTypography.bodyMedium(context)),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
