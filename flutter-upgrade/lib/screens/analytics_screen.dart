import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _loading = true;
  List<Patient> _patients = [];
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final patients = await _db.getPatients(user.uid);
      final reports = await _db.getReportsForDoctor(user.uid).first;
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('analytics'))),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _summaryRow(theme),
                        const SizedBox(height: AppSpacing.md),
                        _sectionCard(
                          theme,
                          'Weekly activity',
                          'Reports completed in the last 7 days',
                          SizedBox(height: 180, child: _activityChart(theme)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _sectionCard(
                          theme,
                          'Patients by department',
                          'Where your caseload sits',
                          _barList(theme, _analytics.byDepartment(_patients)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _sectionCard(
                          theme,
                          'Risk distribution',
                          'AI risk level across reports',
                          SizedBox(height: 180, child: _riskChart(theme)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _sectionCard(
                          theme,
                          'Age groups',
                          'Patient age distribution',
                          _barList(theme, _analytics.byAgeGroup(_patients)),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(ThemeData theme) {
    final urgent = _analytics.byRiskLevel(_reports)['Urgent'] ?? 0;
    return Row(
      children: [
        Expanded(child: _statTile(theme, 'Patients', '${_patients.length}',
            Icons.people_alt_rounded, theme.colorScheme.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _statTile(theme, 'Reports', '${_reports.length}',
            Icons.description_rounded, theme.colorScheme.tertiary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _statTile(theme, 'Urgent', '$urgent',
            Icons.priority_high_rounded, theme.colorScheme.error)),
      ],
    );
  }

  Widget _statTile(
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _sectionCard(
      ThemeData theme, String title, String subtitle, Widget child) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _activityChart(ThemeData theme) {
    final data = _analytics.weeklyActivity(_reports);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxY = data.fold<int>(1, (m, e) => e.value > m ? e.value : m);

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[data[i].key.weekday - 1],
                      style: theme.textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].value.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(6),
                color: theme.colorScheme.primary,
              )
            ]),
        ],
      ),
    );
  }

  Widget _riskChart(ThemeData theme) {
    final risks = _analytics.byRiskLevel(_reports);
    final total = risks.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Center(
        child: Text('No reports yet',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    final colors = <String, Color>{
      'Urgent': theme.colorScheme.error,
      'High': theme.colorScheme.tertiary,
      'Medium': theme.colorScheme.secondary,
      'Low': theme.colorScheme.primary,
    };

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: [
                for (final entry in risks.entries)
                  if (entry.value > 0)
                    PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      radius: 46,
                      color: colors[entry.key],
                      titleStyle: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final entry in risks.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[entry.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${entry.key} (${entry.value})',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _barList(ThemeData theme, Map<String, int> data) {
    if (data.isEmpty) {
      return Text('No data yet',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final max = data.values.fold<int>(1, (m, v) => v > m ? v : m);
    return Column(
      children: [
        for (final entry in data.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(entry.key,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: entry.value / max,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${entry.value}', style: theme.textTheme.labelMedium),
              ],
            ),
          ),
      ],
    );
  }
}
