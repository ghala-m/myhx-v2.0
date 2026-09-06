import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';
import 'add_patient_screen.dart';
import 'patient_record_screen.dart';

/// Full searchable patient list — what used to be the second tab of the
/// old dashboard, now its own destination.
class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  State<PatientsTab> createState() => PatientsTabState();
}

class PatientsTabState extends State<PatientsTab> {
  final _db = DatabaseService();
  final _searchController = TextEditingController();

  late Future<List<Patient>> _patientsFuture;
  List<Patient> _all = [];
  List<Patient> _filtered = [];

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetch();
  }

  Future<List<Patient>> _fetch() async {
    final user = AuthService().currentUser;
    if (user == null) return [];
    final patients = await _db.getPatients(user.uid);
    if (mounted) setState(() { _all = patients; _filtered = patients; });
    return patients;
  }

  /// Called from the shell after adding a patient elsewhere, so this tab
  /// reflects it without the user having to pull-to-refresh.
  void refresh() => setState(() => _patientsFuture = _fetch());

  void _runFilter(String keyword) {
    final lower = keyword.toLowerCase();
    setState(() {
      _filtered = lower.isEmpty
          ? _all
          : _all.where((p) => p.name.toLowerCase().contains(lower)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Patient>>(
      future: _patientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_all.isEmpty) {
          return _emptyState(context);
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _runFilter,
                        decoration: const InputDecoration(
                          hintText: 'Search patients by name...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _filtered.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _patientCard(context, _filtered[index]),
                      ),
                    )
                  : Center(
                      child: Text('No patients found',
                          style: AppTypography.bodyLarge(context)),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('No patients yet', style: AppTypography.titleLarge(context)),
            const SizedBox(height: AppSpacing.sm),
            Text('Add your first patient to get started.',
                style: AppTypography.bodyLarge(context),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPatientScreen()),
                );
                refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add patient'),
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
            radius: 26,
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
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text('${patient.age} years • ${patient.gender}',
                    style: AppTypography.bodyMedium(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
