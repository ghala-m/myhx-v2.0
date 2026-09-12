import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/app_role.dart';
import '../models/case_referral.dart';
import '../models/patient.dart';
import '../models/review_request.dart';
import '../models/teaching_case.dart';
import '../services/case_referral_service.dart';
import '../services/database_service.dart';
import '../services/review_service.dart';
import '../services/role_service.dart';
import '../services/teaching_case_service.dart';
import '../utils/app_spacing.dart';
import '../widgets/translated_text.dart';



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

class _PatientRecordScreenState extends State<PatientRecordScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final ReviewService _reviewService = ReviewService();
  bool _isGeneratingPdf = false;
  bool _isSubmittingReview = false;
  late Future<Map<String, dynamic>?> _reportFuture;
  late bool _isUrgent;
  late String? _urgentSource;
  bool _isTogglingUrgent = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _reportFuture = _dbService.getLatestMedicalReport(widget.patient.id);
    _isUrgent = widget.patient.isUrgent;
    _urgentSource = widget.patient.urgentSource;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitForReview(String reportId, Map<String, dynamic> ai) async {
    final auth = widget.patient.doctorId;
    setState(() => _isSubmittingReview = true);
    try {
      final soap = _asMap(ai['soap_note']) ?? {};
      final soapText = 'S: ${soap['subjective'] ?? ''}\n'
          'O: ${soap['objective'] ?? ''}\n'
          'A: ${soap['assessment'] ?? ''}\n'
          'P: ${soap['plan'] ?? ''}';
      final risk = (ai['risk_level'] ?? ai['riskLevel'] ?? '').toString();

      await _reviewService.submitForReview(ReviewRequest(
        id: '',
        studentId: auth,
        studentName: 'Student', // يعرض المشرف اسم الطالب من حسابه لاحقًا
        patientId: widget.patient.id,
        reportId: reportId,
        patientName: widget.patient.name,
        department: widget.patient.department,
        chiefComplaint: widget.patient.symptoms.isNotEmpty
            ? widget.patient.symptoms.join(', ')
            : '',
        riskLevel: risk,
        soapNote: soapText,
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Submitted for mentor review'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _toggleUrgent() async {
    final next = !_isUrgent;
    setState(() {
      _isUrgent = next;
      _urgentSource = next ? 'manual' : null;
      _isTogglingUrgent = true;
    });
    try {
      await _dbService.setPatientUrgent(widget.patient.id, next);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUrgent = !next; // تراجع عن التغيير عند الفشل
          _urgentSource = widget.patient.urgentSource;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingUrgent = false);
    }
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
            tooltip: _isUrgent ? 'Unmark urgent' : 'Mark as urgent',
            icon: _isTogglingUrgent
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isUrgent
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                    color: _isUrgent ? colors.error : null,
                  ),
            onPressed: _isTogglingUrgent ? null : _toggleUrgent,
          ),
          IconButton(
            tooltip: 'QR',
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => _showQr(context),
          ),
          IconButton(
            tooltip: 'Share case',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _showShareSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Record'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _recordTab(theme, colors),
          _timelineTab(theme, colors),
        ],
      ),
    );
  }

  Widget _recordTab(ThemeData theme, ColorScheme colors) {
    return FutureBuilder<Map<String, dynamic>?>(
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
                  const SizedBox(height: AppSpacing.md),
                  if (context.watch<RoleService>().role == AppRole.student &&
                      data?['reportId'] != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmittingReview
                            ? null
                            : () => _submitForReview(
                                data!['reportId'] as String, ai),
                        icon: _isSubmittingReview
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.forum_outlined),
                        label: const Text('Submit for mentor review'),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (history != null && history.isNotEmpty)
                  _historySection(theme, colors, history),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      );
  }

  Widget _timelineTab(ThemeData theme, ColorScheme colors) {
    final arabic = S.of(context).isArabic;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getReportsForPatient(widget.patient.id),
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
                  final ai = (report['aiAnalysis'] as Map?)
                          ?.cast<String, dynamic>() ??
                      {};
                  final risk = (ai['risk_level'] as String?) ?? 'Low';
                  final date = (report['createdAt'] as Timestamp?)?.toDate();
                  final isLast = index == reports.length - 1;
                  final isCurrent = report['reportId'] == widget.reportId;

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
                                color: _riskColor(risk, colors),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: colors.outlineVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Opacity(
                              opacity: isCurrent ? 1 : 0.85,
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: isCurrent
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PatientRecordScreen(
                                                reportId:
                                                    report['reportId']
                                                        as String,
                                                patient: widget.patient,
                                              ),
                                            ),
                                          ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                date != null
                                                    ? DateFormat(
                                                            'dd MMM yyyy · HH:mm')
                                                        .format(date)
                                                    : '—',
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _riskColor(
                                                        risk, colors)
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                risk,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: _riskColor(
                                                      risk, colors),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _timelineSummary(ai, arabic),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
    );
  }

  Widget _trendChart(BuildContext context,
      List<Map<String, dynamic>> reportsDesc, bool arabic) {
    final chronological = reportsDesc.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < chronological.length; i++) {
      final ai = (chronological[i]['aiAnalysis'] as Map?)
              ?.cast<String, dynamic>() ??
          {};
      final risk = (ai['risk_level'] as String?) ?? 'Low';
      spots.add(FlSpot(i.toDouble(), _riskScore(risk)));
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabic
                    ? 'تطور الخطورة عبر الزيارات'
                    : 'Risk trend across visits',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
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
                            if (label == null ||
                                value != value.roundToDouble()) {
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
                        getTooltipItems: (touchedSpots) =>
                            touchedSpots.map((s) {
                          final date = (chronological[s.x.toInt()]
                                  ['createdAt'] as Timestamp?)
                              ?.toDate();
                          return LineTooltipItem(
                            date != null ? DateFormat('dd MMM').format(date) : '',
                            theme.textTheme.labelSmall ?? const TextStyle(),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: colors.primary,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: _riskColor(_scoreToRisk(spot.y), colors),
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  String _timelineSummary(Map<String, dynamic> ai, bool arabic) {
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

  void _showQr(BuildContext context) {
    final p = widget.patient;
    final payload = jsonEncode({
      'app': 'myhx',
      'patientId': p.id,
      'name': p.name,
      'age': p.age,
      'gender': p.gender,
      'department': p.department,
      'ward': p.wardNumber,
      'room': p.roomNumber,
    });

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.name,
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

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Refer to another doctor/student'),
              subtitle: const Text('Transfers the full real case — needs their acceptance'),
              onTap: () {
                Navigator.of(ctx).pop();
                _referDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Share for teaching (anonymized)'),
              subtitle: const Text('No name, exact age, or other identifier — visible to everyone'),
              onTap: () {
                Navigator.of(ctx).pop();
                _shareForTeaching(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _referDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Refer this case'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "Enter the recipient's account ID (find it in their Settings)."),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Recipient's account ID",
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final toId = controller.text.trim();
                if (toId.isEmpty) return;
                if (toId == widget.patient.doctorId) {
                  setDialogState(() => error = "That's your own ID");
                  return;
                }
                try {
                  await CaseReferralService().refer(CaseReferral(
                    id: '',
                    patientId: widget.patient.id,
                    fromDoctorId: widget.patient.doctorId,
                    fromDoctorName:
                        FirebaseAuth.instance.currentUser?.displayName ??
                            'A colleague',
                    toDoctorId: toId,
                    patientNamePreview: widget.patient.name,
                    department: widget.patient.department,
                    status: 'pending',
                    createdAt: DateTime.now(),
                  ));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Referral sent — awaiting acceptance'),
                    ));
                  }
                } catch (e) {
                  setDialogState(() => error = 'Failed: $e');
                }
              },
              child: const Text('Send referral'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareForTeaching(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share for teaching?'),
        content: const Text(
          'A de-identified copy (department, age range, gender, chief '
          'complaint, SOAP note only — no name or exact age) will become '
          'visible to every doctor and student in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final report = await _reportFuture;
    final ai = _asMap(report?['aiAnalysis']) ?? {};
    final soap = _asMap(ai['soap_note']) ?? {};
    final soapText = 'S: ${soap['subjective'] ?? ''}\n'
        'O: ${soap['objective'] ?? ''}\n'
        'A: ${soap['assessment'] ?? ''}\n'
        'P: ${soap['plan'] ?? ''}';

    try {
      await TeachingCaseService().share(TeachingCase(
        id: '',
        sourceDoctorId: widget.patient.doctorId,
        department: widget.patient.department,
        ageRange: TeachingCase.bucketAge(widget.patient.age),
        gender: widget.patient.gender,
        chiefComplaint: widget.patient.symptoms.isNotEmpty
            ? widget.patient.symptoms.join(', ')
            : '',
        riskLevel: (ai['risk_level'] ?? '').toString(),
        soapNote: soapText,
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shared as a teaching case'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
                if (risk.isNotEmpty || _isUrgent) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (risk.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _riskColor(risk, colors).withValues(alpha: 0.15),
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
                        const SizedBox(width: 6),
                      ],
                      if (_isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _urgentSource == 'system'
                                ? 'Urgent • auto-flagged'
                                : 'Urgent • marked by you',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
