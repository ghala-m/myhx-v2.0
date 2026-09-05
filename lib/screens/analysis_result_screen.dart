import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../services/clinical_ai_service.dart';
import '../services/share_service.dart';
import '../utils/app_spacing.dart';

/// Displays the output of the clinical reasoning engine: risk banner,
/// red flags, ranked differential, recommended workup and the SOAP note.
class AnalysisResultScreen extends StatefulWidget {
  final Patient patient;
  final Map<String, dynamic> analysis;
  final List<Map<String, dynamic>> medicalHistory;

  const AnalysisResultScreen({
    super.key,
    required this.patient,
    required this.analysis,
    this.medicalHistory = const [],
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  late final ClinicalAnalysis _analysis = _parse(widget.analysis);

  /// Parses the stored map, tolerating the legacy shape where
  /// `differential_diagnosis` / `recommendations` were plain string lists.
  ClinicalAnalysis _parse(Map<String, dynamic> raw) {
    final parsed = ClinicalAnalysis.fromJson(raw);
    if (parsed.differential.isNotEmpty) return parsed;

    final legacy = (raw['differential_diagnosis'] as List?) ?? const [];
    final items = legacy
        .whereType<String>()
        .map((d) => DifferentialItem(
              diagnosis: d,
              probability: 0,
              rationale: '',
            ))
        .toList();
    if (items.isEmpty) return parsed;

    return ClinicalAnalysis(
      riskLevel: parsed.riskLevel,
      confidencePercent: parsed.confidencePercent,
      differential: items,
      redFlags: parsed.redFlags,
      recommendedWorkup: parsed.recommendedWorkup,
      recommendations: parsed.recommendations,
      soapNote: parsed.soapNote,
      generatedAt: parsed.generatedAt,
    );
  }

  Color _riskColor(ColorScheme colors) {
    switch (_analysis.riskLevel) {
      case 'Urgent':
        return const Color(0xFFD32F2F);
      case 'High':
        return const Color(0xFFEF6C00);
      case 'Medium':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Clinical Analysis'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Share / print report',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => ShareService().showShareOptions(
              context: context,
              patient: widget.patient,
              medicalHistory: widget.medicalHistory,
              aiAnalysis: widget.analysis,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _riskBanner(theme, colors),
          const SizedBox(height: AppSpacing.md),
          _patientCard(theme, colors),
          if (_analysis.redFlags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionHeader('Red Flags', Icons.warning_amber_rounded, colors,
                color: const Color(0xFFD32F2F)),
            ..._analysis.redFlags.map((f) => _redFlagTile(f, theme)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _sectionHeader(
              'Differential Diagnosis', Icons.medical_information_outlined, colors),
          _differentialCard(theme, colors),
          if (_analysis.recommendedWorkup.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionHeader('Recommended Workup', Icons.science_outlined, colors),
            _bulletCard(_analysis.recommendedWorkup, Icons.biotech_outlined,
                colors.primary, theme, colors),
          ],
          if (_analysis.recommendations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionHeader('Recommendations', Icons.recommend_outlined, colors),
            _bulletCard(_analysis.recommendations, Icons.check_circle_outline,
                const Color(0xFF2E7D32), theme, colors),
          ],
          const SizedBox(height: AppSpacing.lg),
          _sectionHeader('SOAP Note', Icons.description_outlined, colors),
          _soapCard(theme, colors),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export full report (PDF)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => ShareService().showShareOptions(
              context: context,
              patient: widget.patient,
              medicalHistory: widget.medicalHistory,
              aiAnalysis: widget.analysis,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _riskBanner(ThemeData theme, ColorScheme colors) {
    final color = _riskColor(colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            _analysis.isUrgent
                ? Icons.priority_high_rounded
                : Icons.verified_outlined,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_analysis.riskLevel} risk',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Model confidence ${_analysis.confidencePercent}%'
                  '${_analysis.redFlags.isEmpty ? '' : ' • ${_analysis.redFlags.length} red flag(s)'}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text(widget.patient.name.isEmpty
                  ? '?'
                  : widget.patient.name.characters.first.toUpperCase()),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patient.name, style: theme.textTheme.titleMedium),
                  Text(
                    '${widget.patient.age} yrs • ${widget.patient.gender} • ${widget.patient.department}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ColorScheme colors,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color ?? colors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color ?? colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _redFlagTile(RedFlag flag, ThemeData theme) {
    final color =
        flag.isCritical ? const Color(0xFFD32F2F) : const Color(0xFFEF6C00);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flag.label,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(flag.action, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _differentialCard(ThemeData theme, ColorScheme colors) {
    if (_analysis.differential.isEmpty) {
      return const Card(
        child: ListTile(title: Text('No differential diagnoses available.')),
      );
    }
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: _analysis.differential.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.diagnosis,
                            style: theme.textTheme.titleSmall),
                      ),
                      if (item.percent > 0)
                        Text('${item.percent}%',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: colors.primary)),
                    ],
                  ),
                  if (item.percent > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: item.percent / 100,
                        minHeight: 6,
                        backgroundColor:
                            colors.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  if (item.rationale.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.rationale,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                  if (item.supportingFindings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.supportingFindings
                          .map((f) => Chip(
                                label: Text(f,
                                    style: theme.textTheme.labelSmall),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _bulletCard(List<String> items, IconData icon, Color iconColor,
      ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: items
              .map((item) => ListTile(
                    dense: true,
                    leading: Icon(icon, color: iconColor, size: 20),
                    title: Text(item, style: theme.textTheme.bodyMedium),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _soapCard(ThemeData theme, ColorScheme colors) {
    final soap = _analysis.soapNote;
    final sections = <String, String>{
      'Subjective': soap.subjective,
      'Objective': soap.objective,
      'Assessment': soap.assessment,
      'Plan': soap.plan,
    }..removeWhere((_, v) => v.trim().isEmpty);

    if (sections.isEmpty) {
      return const Card(
        child: ListTile(title: Text('No SOAP note generated.')),
      );
    }

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sections.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 4),
                      Text(e.value, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copy SOAP note'),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: soap.toPlainText()));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SOAP note copied')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
