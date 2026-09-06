import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';

/// Surfaces patients flagged urgent — either by a doctor's own manual
/// judgement, or automatically by the system when a clinical analysis
/// comes back Urgent/High risk (see [Patient.isUrgent]/[Patient.urgentSource]).
class UrgentCasesBanner extends StatelessWidget {
  const UrgentCasesBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<Patient>>(
      future: DatabaseService().getPatients(user.uid),
      builder: (context, snapshot) {
        final urgent =
            (snapshot.data ?? const <Patient>[]).where((p) => p.isUrgent).toList();
        if (urgent.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Icon(Icons.priority_high_rounded,
                    color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    urgent.length == 1
                        ? '1 patient marked urgent needs review'
                        : '${urgent.length} patients marked urgent need review',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.error),
              ],
            ),
          ),
        );
      },
    );
  }
}
