import 'package:flutter/material.dart';
import '../models/patient.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../services/database_service.dart'; // Import database service
import '../services/share_service.dart'; // Import share service

class PatientRecordScreen extends StatefulWidget {
  final Patient patient;
  // We no longer receive medicalHistory and aiAnalysis directly, but will fetch them
  final String reportId; // reportId might be needed if we want to fetch a specific report

  const PatientRecordScreen({
    super.key,
    required this.patient,
    required this.reportId, // Make reportId required if it will be used to fetch a specific report
  });

  @override
  State<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> {
  bool _isGeneratingPdf = false;
  final DatabaseService _dbService = DatabaseService(); // Create an instance of the database service
  final ShareService _shareService = ShareService(); // Create an instance of the share service

  // Variable to store the Future that will fetch the medical report
  late Future<Map<String, dynamic>?> _latestMedicalReportFuture;

  @override
  void initState() {
    super.initState();
    print("PatientRecordScreen initState: patientId = ${widget.patient.id}, reportId = ${widget.reportId}");
    // Fetch the latest medical report for the patient when the screen initializes
    _latestMedicalReportFuture = _dbService.getLatestMedicalReport(widget.patient.id);
  }

  Future<void> _generateAndPrintPdf(Map<String, dynamic>? medicalHistory, Map<String, dynamic>? aiAnalysis) async {
    setState(() { _isGeneratingPdf = true; });
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text('Medical Report: ${widget.patient.name}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              pw.Text('Patient Information', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Name: ${widget.patient.name}'),
              pw.Text('Age: ${widget.patient.age} years'),
              pw.Text('Gender: ${widget.patient.gender}'),
              pw.Text('Department: ${widget.patient.department}'),
              pw.Text('Ward/Room: ${widget.patient.wardNumber} / ${widget.patient.roomNumber}'),
              pw.SizedBox(height: 20),
              if (medicalHistory != null) ...[
                pw.Text('Medical History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...medicalHistory.entries.map((e) => pw.Text('${e.key.replaceAll('_', ' ').toUpperCase()}: ${e.value}')),
                pw.SizedBox(height: 20),
              ],
              if (aiAnalysis != null) ...[
                pw.Text('AI Analysis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Diagnoses: ${(aiAnalysis['differential_diagnosis'] as List? ?? []).join(', ')}', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Recommendations: ${(aiAnalysis['recommendations'] as List? ?? []).join(', ')}', style: pw.TextStyle(fontSize: 12)),
              ],
            ];
          },
        ),
      );

      // Print the file directly
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Medical_Report_${widget.patient.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent for printing successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isGeneratingPdf = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.patient.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>?>( // New FutureBuilder for print and share buttons
            future: _latestMedicalReportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (snapshot.hasData && snapshot.data != null) {
                print("Snapshot data in PatientRecordScreen: ${snapshot.data}");
                print("Snapshot data in PatientRecordScreen (main FutureBuilder): ${snapshot.data}");
                final medicalHistory = snapshot.data!["medicalHistory"] as Map<String, dynamic>?;
                final aiAnalysis = snapshot.data!["aiAnalysis"] as Map<String, dynamic>?;
                print("Medical History (main FutureBuilder) after extraction: $medicalHistory");
                print("AI Analysis (main FutureBuilder) after extraction: $aiAnalysis");
                print("Medical History after extraction: $medicalHistory");
                print("AI Analysis after extraction: $aiAnalysis");
                
                // Share button
                return Row(
                  children: [

                    // Print button
                    IconButton(
                      icon: _isGeneratingPdf ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.print_outlined),
                      onPressed: _isGeneratingPdf ? null : () => _generateAndPrintPdf(medicalHistory, aiAnalysis),
                      tooltip: "Print Report",
                    ),
                  ],
                );
              }
              return const SizedBox.shrink(); // No report, do not display print or share button
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientSummaryCard(theme, colors),
            const SizedBox(height: 24),
            // --- Use FutureBuilder to fetch and display medical history and AI analysis ---
            FutureBuilder<Map<String, dynamic>?>(
              future: _latestMedicalReportFuture,
              builder: (context, snapshot) {
                print("=== FutureBuilder State ===");
                print("Connection state: ${snapshot.connectionState}");
                print("Has error: ${snapshot.hasError}");
                print("Has data: ${snapshot.hasData}");
                print("Data: ${snapshot.data}");
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading medical data...'),
                        ],
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  print("ERROR in FutureBuilder: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 60, color: colors.error),
                          const SizedBox(height: 16),
                          Text('An error occurred while loading data', style: theme.textTheme.titleMedium?.copyWith(color: colors.error)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _latestMedicalReportFuture = _dbService.getLatestMedicalReport(widget.patient.id);
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data == null) {
                  print("No data found for patient: ${widget.patient.id}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 60, color: colors.onSurface.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No medical history for this patient', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Please add a new medical history from the control panel', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          Text('Patient ID: ${widget.patient.id}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final medicalHistory = snapshot.data!['medicalHistory'] as Map<String, dynamic>?;
                final aiAnalysis = snapshot.data!['aiAnalysis'] as Map<String, dynamic>?;
                
                print("Medical History: $medicalHistory");
                print("AI Analysis: $aiAnalysis");

                // If data exists but is empty
                if ((medicalHistory == null || medicalHistory.isEmpty) && 
                    (aiAnalysis == null || aiAnalysis.isEmpty)) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 60, color: colors.primary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('Medical Report is Empty', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('The report exists but contains no data', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medicalHistory != null && medicalHistory.isNotEmpty) ...[
                      _buildSectionHeader('Medical History', Icons.history_edu_outlined, colors),
                      _buildHistoryDetailsCard(theme, colors, medicalHistory),
                      const SizedBox(height: 24),
                    ],
                    if (aiAnalysis != null && aiAnalysis.isNotEmpty) ...[
                      _buildSectionHeader('AI Analysis', Icons.psychology_outlined, colors),
                      _buildAiAnalysisCard(theme, colors, aiAnalysis),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: colors.primary, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patient.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('${widget.patient.age} years • ${widget.patient.department}', style: theme.textTheme.bodyMedium),
                  Text('Ward: ${widget.patient.wardNumber} / Room: ${widget.patient.roomNumber}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailsCard(ThemeData theme, ColorScheme colors, Map<String, dynamic> history) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: history.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: Text('${entry.key.replaceAll('_', ' ').toUpperCase()}:', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text(entry.value.toString())),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard(ThemeData theme, ColorScheme colors, Map<String, dynamic> analysis) {
    final List<String> diagnoses = List<String>.from(analysis['differential_diagnosis'] ?? []);
    final List<String> recommendations = List<String>.from(analysis['recommendations'] ?? []);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (diagnoses.isNotEmpty) ...[
              Text('Differential Diagnoses:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: diagnoses.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ', style: theme.textTheme.bodyLarge),
                      Expanded(child: Text(diagnoses[index], style: theme.textTheme.bodyLarge)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (recommendations.isNotEmpty) ...[
              Text('Recommendations:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommendations.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ', style: theme.textTheme.bodyLarge),
                      Expanded(child: Text(recommendations[index], style: theme.textTheme.bodyLarge)),
                    ],
                  ),
                ),
              ),
            ],
            if (diagnoses.isEmpty && recommendations.isEmpty) ...[
              Text('No AI analysis data available.', style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

