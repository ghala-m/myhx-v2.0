import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_role.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/role_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/urgent_cases_banner.dart';
import 'add_patient_screen.dart';
import 'patient_record_screen.dart';

/// The app's home tab. Same layout skeleton for everyone (greeting, then a
/// role-specific body), but what's inside adapts to whether the signed-in
/// account is a doctor or a student — a busy clinician and a student on
/// placement need very different things from the first screen they see.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onSeeAllPatients});

  final VoidCallback onSeeAllPatients;

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final _db = DatabaseService();
  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetchPatients();
  }

  Future<List<Patient>> _fetchPatients() async {
    final user = AuthService().currentUser;
    if (user == null) return [];
    return _db.getPatients(user.uid);
  }

  void refresh() => setState(() => _patientsFuture = _fetchPatients());

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleService>();
    final arabic = context.watch<LocaleProvider>().isArabic;
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    final isDoctor = roles.role == AppRole.doctor;

    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _greeting(context, isDoctor, displayName, arabic),
          const SizedBox(height: AppSpacing.lg),
          if (isDoctor && context.watch<NotificationPreferencesService>().isEnabled)
            UrgentCasesBanner(onTap: widget.onSeeAllPatients)
          else if (!isDoctor)
            _studentProgressCard(context, arabic),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<List<Patient>>(
            future: _patientsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final patients = snapshot.data ?? const [];
              return _recentSection(context, patients, isDoctor, arabic);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _newEncounterButton(context, arabic),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _greeting(
      BuildContext context, bool isDoctor, String? displayName, bool arabic) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? (arabic ? 'صباح الخير' : 'Good morning')
        : (hour < 18
            ? (arabic ? 'مساء الخير' : 'Good afternoon')
            : (arabic ? 'مساء الخير' : 'Good evening'));
    final name = (displayName == null || displayName.trim().isEmpty)
        ? (isDoctor ? (arabic ? 'دكتور' : 'Doctor') : (arabic ? 'طالب' : 'Student'))
        : displayName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeGreeting, style: AppTypography.bodyLarge(context)),
              const SizedBox(height: 2),
              Text(name, style: AppTypography.displayMedium(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _studentProgressCard(BuildContext context, bool arabic) {
    return FutureBuilder<List<Patient>>(
      future: _patientsFuture,
      builder: (context, snapshot) {
        final patients = snapshot.data ?? const [];
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final thisWeek = patients
            .where((p) => p.createdAt.isAfter(startOfWeek))
            .length;

        return AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arabic ? 'هذا الأسبوع' : 'This week',
                      style: AppTypography.caption(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arabic ? '$thisWeek حالة أُخذت' : '$thisWeek cases taken',
                      style: AppTypography.titleMedium(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.school_outlined,
                  size: 32, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        );
      },
    );
  }

  Widget _recentSection(BuildContext context, List<Patient> patients,
      bool isDoctor, bool arabic) {
    final recent = patients.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              arabic ? 'المرضى الأخيرون' : 'Recent patients',
              style: AppTypography.titleLarge(context),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onSeeAllPatients,
              child: Text(arabic ? 'عرض الكل' : 'View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (recent.isEmpty)
          _emptyState(context, arabic)
        else
          ...recent.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _patientCard(context, p),
              )),
      ],
    );
  }

  Widget _emptyState(BuildContext context, bool arabic) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              arabic ? 'لا يوجد مرضى بعد' : 'No patients yet',
              style: AppTypography.titleMedium(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(BuildContext context, Patient patient) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientRecordScreen(patient: patient, reportId: ''),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              patient.name.trim().isEmpty
                  ? '?'
                  : patient.name
                      .split(' ')
                      .where((w) => w.isNotEmpty)
                      .map((n) => n[0])
                      .take(2)
                      .join()
                      .toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(patient.name,
                          style: AppTypography.titleMedium(context),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (patient.isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('${patient.age} • ${patient.gender}',
                    style: AppTypography.caption(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newEncounterButton(BuildContext context, bool arabic) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          );
          refresh();
        },
        icon: const Icon(Icons.add),
        label: Text(arabic ? 'حالة جديدة' : 'New encounter'),
      ),
    );
  }
}
