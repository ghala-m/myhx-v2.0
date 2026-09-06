// Patient timeline + shareable QR card.
// lib/screens/patient_timeline_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_card.dart';
import 'patient_record_screen.dart';

class PatientTimelineScreen extends StatelessWidget {
  final Patient patient;

  const PatientTimelineScreen({super.key, required this.patient});

  static Color riskColor(String risk) {
    switch (risk) {
      case 'Urgent':
        return AppColors.error;
      case 'High':
        return AppColors.warning;
      case 'Medium':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  void _showQr(BuildContext context) {
    final payload = jsonEncode({
      'app': 'myhx',
      'patientId': patient.id,
      'name': patient.name,
      'age': patient.age,
      'gender': patient.gender,
      'department': patient.department,
      'ward': patient.wardNumber,
      'room': patient.roomNumber,
    });

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(patient.name,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            QrImageView(
              data: payload,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(ctx).isArabic
                  ? 'امسح الرمز لفتح ملف المريض على جهاز آخر'
                  : 'Scan to open this patient on another device',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final arabic = S.of(context).isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(arabic ? 'المسار الزمني' : 'Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'QR',
            onPressed: () => _showQr(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getReportsForPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? const [];
          if (reports.isEmpty) {
            return Center(
              child: Text(arabic ? 'لا توجد تقارير بعد' : 'No reports yet'),
            );
          }

          return Column(
            children: [
              if (reports.length >= 2) _trendChart(context, reports, arabic),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
              final report = reports[index];
              final ai = (report['aiAnalysis'] as Map?)?.cast<String, dynamic>() ?? {};
              final risk = (ai['risk_level'] as String?) ?? 'Low';
              final date = (report['createdAt'] as Timestamp?)?.toDate();
              final isLast = index == reports.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(top: 22),
                          decoration: BoxDecoration(
                            color: riskColor(risk),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PatientRecordScreen(
                                reportId: report['reportId'] as String,
                                patient: patient,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      date != null
                                          ? DateFormat('dd MMM yyyy · HH:mm')
                                              .format(date)
                                          : '—',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: riskColor(risk)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      risk,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: riskColor(risk),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _summary(ai, arabic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _trendChart(
      BuildContext context, List<Map<String, dynamic>> reportsDesc, bool arabic) {
    // reportsDesc is newest-first (matches the timeline list below);
    // the chart reads left-to-right chronologically, so reverse it.
    final chronological = reportsDesc.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < chronological.length; i++) {
      final ai = (chronological[i]['aiAnalysis'] as Map?)?.cast<String, dynamic>() ?? {};
      final risk = (ai['risk_level'] as String?) ?? 'Low';
      spots.add(FlSpot(i.toDouble(), _riskScore(risk)));
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              arabic ? 'تطور الخطورة عبر الزيارات' : 'Risk trend across visits',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: 0.5,
                  maxY: 4.5,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const labels = {
                            1: 'Low',
                            2: 'Medium',
                            3: 'High',
                            4: 'Urgent',
                          };
                          final label = labels[value.round()];
                          if (label == null || value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(label,
                              style: theme.textTheme.labelSmall);
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final date =
                            (chronological[s.x.toInt()]['createdAt'] as Timestamp?)
                                ?.toDate();
                        return LineTooltipItem(
                          date != null
                              ? DateFormat('dd MMM').format(date)
                              : '',
                          theme.textTheme.labelSmall ?? const TextStyle(),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: theme.colorScheme.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: riskColor(_scoreToRisk(spot.y)),
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _riskScore(String risk) {
    switch (risk) {
      case 'Urgent':
        return 4;
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      default:
        return 1;
    }
  }

  String _scoreToRisk(double score) {
    switch (score.round()) {
      case 4:
        return 'Urgent';
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _summary(Map<String, dynamic> ai, bool arabic) {
    final dx = ai['differential_diagnosis'];
    if (dx is List && dx.isNotEmpty) {
      final first = dx.first;
      if (first is Map) {
        return (first['diagnosis'] ?? first['dx'] ?? '').toString();
      }
      return first.toString();
    }
    return arabic ? 'تقرير تاريخ مرضي' : 'Medical history report';
  }
}
