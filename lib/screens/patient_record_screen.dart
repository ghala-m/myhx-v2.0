import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';
import '../widgets/translated_text.dart';
import 'patient_timeline_screen.dart';



/// Patient record: summary, medical history and clinical AI analysis.
///
/// All report values are rendered defensively — older reports store plain
/// strings while newer ones store nested maps/lists, so nothing is cast blindly.
class PatientRecordScreen extends StatefulWidget {
  final Patient patient;
  final String reportId;

  const PatientRecordScreen({
    super.key,
    required this.patient,
    required this.reportId,
  });

  @override
  State<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isGeneratingPdf = false;
  late Future<Map<String, dynamic>?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _dbService.getLatestMedicalReport(widget.patient.id);
  }

  // ------------------------------------------------------------ safe parsing

  Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  /// Turns any stored value (String, num, bool, List, Map) into readable text.
  String _stringify(dynamic value) {
    if (value == null) return '—';
    if (value is String) return value.isEmpty ? '—' : value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      if (value.isEmpty) return '—';
      return value.map(_stringify).join('، ');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${_label(e.key.toString())}: ${_stringify(e.value)}')
          .join(' — ');
    }
    return value.toString();
  }

  String _label(String key) =>
      key.replaceAll('_', ' ').trim().replaceRange(0, 1, key.isEmpty ? '' : key[0].toUpperCase());

  List<Map<String, dynamic>> _mapList(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map(_stringify).where((e) => e != '—').toList();
  }

  Color _riskColor(String risk, ColorScheme c) {
    switch (risk.toLowerCase()) {
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

  // --------------------------------------------------------------------- pdf

  Future<void> _printPdf(
      Map<String, dynamic>? history, Map<String, dynamic>? ai) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text('Medical Report: ${widget.patient.name}',
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Age: ${widget.patient.age}   Gender: ${widget.patient.gender}'),
          pw.Text('Department: ${widget.patient.department}'),
          pw.Text(
              'Ward/Room: ${widget.patient.wardNumber} / ${widget.patient.roomNumber}'),
          pw.SizedBox(height: 16),
          if (history != null && history.isNotEmpty) ...[
            pw.Text('Medical History',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...history.entries.map(
                (e) => pw.Text('${_label(e.key)}: ${_stringify(e.value)}')),
            pw.SizedBox(height: 16),
          ],
          if (ai != null && ai.isNotEmpty) ...[
            pw.Text('AI Analysis',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...ai.entries.map(
                (e) => pw.Text('${_label(e.key)}: ${_stringify(e.value)}')),
          ],
        ],
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // -------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(widget.patient.name),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Timeline & QR',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientTimelineScreen(patient: widget.patient),
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _reportFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data;
          final history = _asMap(data?['medicalHistory']);
          final ai = _asMap(data?['aiAnalysis']);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _summaryCard(theme, colors, history, ai),
              const SizedBox(height: AppSpacing.lg),
              if (waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _empty(theme, colors, Icons.error_outline_rounded,
                    '${snapshot.error}')
              else if ((history == null || history.isEmpty) &&
                  (ai == null || ai.isEmpty))
                _empty(theme, colors, Icons.assignment_late_outlined,
                    context.tr('noData'))
              else ...[
                if (ai != null && ai.isNotEmpty) ...[
                  _aiSection(theme, colors, ai),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (history != null && history.isNotEmpty)
                  _historySection(theme, colors, history),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(ThemeData theme, ColorScheme colors,
      Map<String, dynamic>? history, Map<String, dynamic>? ai) {
    final risk = (ai?['risk_level'] ?? ai?['riskLevel'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary.withValues(alpha: 0.15),
            child: Text(
              widget.patient.name.isEmpty
                  ? '?'
                  : widget.patient.name[0].toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.patient.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${widget.patient.age} • ${widget.patient.gender} • ${widget.patient.department}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${context.tr('ward')}: ${widget.patient.wardNumber} / ${context.tr('room')}: ${widget.patient.roomNumber}',
                  style: theme.textTheme.bodySmall,
                ),
                if (risk.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _riskColor(risk, colors).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${context.tr('riskLevel')}: $risk',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _riskColor(risk, colors),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('reports'),
            onPressed: _isGeneratingPdf ? null : () => _printPdf(history, ai),
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, ColorScheme colors, IconData icon,
          String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      );

  Widget _card(ColorScheme colors, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: child,
      );

  Widget _historySection(
      ThemeData theme, ColorScheme colors, Map<String, dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, colors, Icons.history_edu_outlined,
            context.tr('medicalHistory')),
        _card(
          colors,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: history.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(e.key),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    TranslatedText(_stringify(e.value),
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _aiSection(
      ThemeData theme, ColorScheme colors, Map<String, dynamic> ai) {
    final differential = _mapList(ai['differential_diagnosis']);
    final legacyDx = differential.isEmpty
        ? _stringList(ai['differential_diagnosis'])
        : const <String>[];
    final redFlags = _mapList(ai['red_flags']);
    final workup = _stringList(ai['recommended_workup']);
    final recs = _stringList(ai['recommendations']);
    final soap = _asMap(ai['soap_note']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, colors, Icons.psychology_outlined,
            context.tr('aiAnalysis')),
        if (redFlags.isNotEmpty) ...[
          _card(
            colors,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('redFlags'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: colors.error)),
                const SizedBox(height: 8),
                ...redFlags.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: colors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatedText(_stringify(f['label']),
                                    style: theme.textTheme.bodyMedium),
                                if (f['action'] != null)
                                  TranslatedText(_stringify(f['action']),
                                      style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (differential.isNotEmpty || legacyDx.isNotEmpty) ...[
          _card(
            colors,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('differential'),
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ...differential.map((d) {
                  final p = d['probability'];
                  final pct = p is num ? (p <= 1 ? p * 100 : p).round() : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TranslatedText(_stringify(d['diagnosis']),
                                  style: theme.textTheme.bodyMedium),
                            ),
                            if (pct != null)
                              Text('$pct%',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(color: colors.primary)),
                          ],
                        ),
                        if (pct != null) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 5,
                              backgroundColor:
                                  colors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                        if (d['rationale'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TranslatedText(_stringify(d['rationale']),
                                style: theme.textTheme.bodySmall),
                          ),
                      ],
                    ),
                  );
                }),
                ...legacyDx.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TranslatedText('• $d', style: theme.textTheme.bodyMedium),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (workup.isNotEmpty) ...[
          _card(colors, _bullets(theme, context.tr('recommendations'), workup)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (recs.isNotEmpty) ...[
          _card(colors, _bullets(theme, context.tr('recommendations'), recs)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (soap != null && soap.isNotEmpty)
          _card(
            colors,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('soapNote'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ...soap.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_label(e.key),
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: colors.primary)),
                          TranslatedText(_stringify(e.value),
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bullets(ThemeData theme, String title, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: TranslatedText('• $i', style: theme.textTheme.bodyMedium),
              )),
        ],
      );

  Widget _empty(
          ThemeData theme, ColorScheme colors, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 52, color: colors.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: AppSpacing.md),
            Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}
