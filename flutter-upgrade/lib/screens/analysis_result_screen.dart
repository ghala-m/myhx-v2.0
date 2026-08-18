import 'package:flutter/material.dart';
import '../models/patient.dart';
// لا نحتاج إلى استيراد patient_record_screen هنا بعد الآن

class AnalysisResultScreen extends StatefulWidget {
  final Patient patient;
  final Map<String, dynamic> analysis; // نتائج التحليل من الذكاء الاصطناعي

  const AnalysisResultScreen({
    super.key,
    required this.patient,
    required this.analysis,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        centerTitle: true,
        automaticallyImplyLeading: false, // إخفاء زر الرجوع التلقائي
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة ملخص المريض
            _buildPatientSummaryCard(theme, colors),
            const SizedBox(height: 24),

            // قسم التشخيصات المحتملة
            _buildSectionHeader('Differential Diagnosis', Icons.medical_information_outlined, colors),
            _buildDiagnosisList(theme, colors),
            const SizedBox(height: 24),

            // قسم التوصيات
            _buildSectionHeader('Recommendations', Icons.recommend_outlined, colors),
            _buildRecommendationsList(theme, colors), // <-- الدالة المكتملة
            const SizedBox(height: 40),

            // زر تحميل التقرير
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Download Full Report (PDF)'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF generation from this screen is under development.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // زر العودة إلى لوحة التحكم
            TextButton(
              onPressed: () {
                // العودة إلى شاشة لوحة التحكم الرئيسية وحذف كل الشاشات السابقة
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Back to Dashboard', style: TextStyle(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surface,
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
                  Text(widget.patient.name, style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.patient.age} years • ${widget.patient.gender}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.onBackground)),
        ],
      ),
    );
  }

  Widget _buildDiagnosisList(ThemeData theme, ColorScheme colors) {
    final List<String> diagnoses = List<String>.from(widget.analysis['differential_diagnosis'] ?? []);
    if (diagnoses.isEmpty) {
      return const Card(child: ListTile(title: Text('No differential diagnoses available.')));
    }
    return Card(
      color: colors.surface,
      clipBehavior: Clip.antiAlias, // لمنع العناصر من الخروج عن الحواف الدائرية
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: diagnoses.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            title: Text(diagnoses[index], style: TextStyle(color: colors.onSurface)),
          );
        },
        separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
      ),
    );
  }

  // --- الدالة المكتملة ---
  Widget _buildRecommendationsList(ThemeData theme, ColorScheme colors) {
    final List<String> recommendations = List<String>.from(widget.analysis['recommendations'] ?? []);
    if (recommendations.isEmpty) {
      return const Card(child: ListTile(title: Text('No specific recommendations available.')));
    }
    return Card(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: recommendations.map((rec) {
            return ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green.shade600),
              title: Text(rec, style: TextStyle(color: colors.onSurface)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
