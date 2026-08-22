import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';
import 'patient_record_screen.dart';

/// Real reports list for the signed-in doctor.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  String _query = '';

  DateTime? _createdAt(Map<String, dynamic> r) {
    final v = r['createdAt'];
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _riskOf(Map<String, dynamic> r) {
    final ai = r['aiAnalysis'];
    if (ai is Map && ai['riskLevel'] is String) {
      return (ai['riskLevel'] as String).toLowerCase();
    }
    return '';
  }

  Color _riskColor(String risk, ColorScheme c) {
    switch (risk) {
      case 'urgent':
        return c.error;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.green;
      default:
        return c.primary;
    }
  }

  String _formatDate(DateTime? d, BuildContext context) {
    if (d == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _open(Map<String, dynamic> report) {
    final raw = report['patientData'];
    if (raw is! Map) return;
    try {
      final patient = Patient.fromJson(Map<String, dynamic>.from(raw));
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PatientRecordScreen(
          patient: patient,
          reportId: report['reportId']?.toString() ?? '',
        ),
      ));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('noData'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('reports'))),
        body: Center(child: Text(context.tr('login'))),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(context.tr('reports'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.tr('search'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getReportsForDoctor(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colors.error)),
                    ),
                  );
                }

                final all = snapshot.data ?? const <Map<String, dynamic>>[];
                final reports = _query.isEmpty
                    ? all
                    : all
                        .where((r) => (r['patientName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_query))
                        .toList();

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 56,
                            color: colors.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(height: AppSpacing.md),
                        Text(context.tr('noData'),
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final r = reports[i];
                    final name = (r['patientName'] ?? '').toString();
                    final risk = _riskOf(r);
                    final date = _createdAt(r);
                    final dept = (r['patientDepartment'] ?? '').toString();
                    final age = r['patientAge'];

                    return Material(
                      color: colors.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        onTap: () => _open(r),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    colors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  name.isEmpty ? '?' : name[0].toUpperCase(),
                                  style: TextStyle(color: colors.primary),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty
                                          ? context.tr('patientName')
                                          : name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (age != null)
                                          '$age ${context.tr('age')}',
                                        if (dept.isNotEmpty) dept,
                                      ].join(' • '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_formatDate(date, context),
                                      style: theme.textTheme.bodySmall),
                                  if (risk.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _riskColor(risk, colors)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        context.tr(risk),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: _riskColor(risk, colors),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
