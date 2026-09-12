import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_role.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/progress_service.dart';
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
  const HomeTab({
    super.key,
    required this.onSeeAllPatients,
    required this.onOpenInsights,
  });

  final VoidCallback onSeeAllPatients;
  final VoidCallback onOpenInsights;

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final _db = DatabaseService();
  final _progressService = ProgressService();
  late Future<List<Patient>> _patientsFuture;
  Future<StudentProgressStats>? _statsFuture;

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

  Future<StudentProgressStats> _fetchStats(String uid) {
    return _statsFuture ??= _progressService.forUser(uid);
  }

  void refresh() => setState(() {
        _patientsFuture = _fetchPatients();
        _statsFuture = null;
      });

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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDoctor) _doctorStatsRow(context, patients, arabic),
                  if (isDoctor) const SizedBox(height: AppSpacing.md),
                  if (isDoctor &&
                      context.watch<NotificationPreferencesService>().isEnabled)
                    UrgentCasesBanner(onTap: widget.onSeeAllPatients),
                  if (!isDoctor) _studentProgressStrip(context, arabic),
                  const SizedBox(height: AppSpacing.lg),
                  _recentSection(context, patients, arabic),
                ],
              );
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

  Widget _doctorStatsRow(
      BuildContext context, List<Patient> patients, bool arabic) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek =
        patients.where((p) => p.createdAt.isAfter(startOfWeek)).length;
    final urgent = patients.where((p) => p.isUrgent).length;

    return Row(
      children: [
        Expanded(
          child: _statCard(context, '${patients.length}',
              arabic ? 'إجمالي المرضى' : 'Total patients',
              Icons.people_alt_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            context,
            '$urgent',
            arabic ? 'طارئ' : 'Urgent',
            Icons.local_fire_department_outlined,
            highlight: urgent > 0,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(context, '$thisWeek',
              arabic ? 'هذا الأسبوع' : 'This week',
              Icons.calendar_today_outlined),
        ),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String value, String label, IconData icon,
      {bool highlight = false}) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.error : theme.colorScheme.primary;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: AppTypography.titleLarge(context).copyWith(color: color)),
          Text(label, style: AppTypography.caption(context)),
        ],
      ),
    );
  }

  Widget _studentProgressStrip(BuildContext context, bool arabic) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<StudentProgressStats>(
      future: _fetchStats(user.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? StudentProgressStats.empty;
        final theme = Theme.of(context);
        return InkWell(
          onTap: widget.onOpenInsights,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                if (stats.streakDays > 0) ...[
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent),
                  const SizedBox(width: 4),
                  Text('${stats.streakDays}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    arabic
                        ? '${stats.points} نقطة • ${stats.casesTaken} حالة'
                        : '${stats.points} points • ${stats.casesTaken} cases',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recentSection(
      BuildContext context, List<Patient> patients, bool arabic) {
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
