import 'package:flutter/material.dart';
import '../services/api_service.dart'; // استيراد الخدمات
import '../services/firebase_service.dart';

class MedicalHistorySummaryPage extends StatefulWidget {
  final String medicalHistoryText;
  final String patientId; // معرف المريض لتخزين البيانات

  const MedicalHistorySummaryPage({
    Key? key,
    required this.medicalHistoryText,
    required this.patientId,
  }) : super(key: key);

  @override
  _MedicalHistorySummaryPageState createState() => _MedicalHistorySummaryPageState();
}

class _MedicalHistorySummaryPageState extends State<MedicalHistorySummaryPage> {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  
  Future<AnalysisResult>? _analysisResult;
  AnalysisResult? _cachedResult; // لتخزين النتيجة بعد تحميلها

  @override
  void initState() {
    super.initState();
    // بدء عملية التحليل عند تحميل الصفحة
    _analysisResult = _apiService.analyzeMedicalHistory(widget.medicalHistoryText);
  }

  void _saveToFirebase() async {
    if (_cachedResult != null) {
      try {
        await _firebaseService.saveAnalysisResult(
          patientId: widget.patientId,
          result: _cachedResult!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis saved to Firebase successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving to Firebase: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Summary'),
        actions: [
          // إظهار زر الحفظ فقط بعد تحميل البيانات بنجاح
          if (_cachedResult != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveToFirebase,
              tooltip: 'Save to Firebase',
            ),
        ],
      ),
      body: FutureBuilder<AnalysisResult>(
        future: _analysisResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // تخزين النتيجة لاستخدامها في الحفظ
            _cachedResult = snapshot.data;
            final result = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Summary'),
                  const SizedBox(height: 8),
                  Text(
                    result.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Top 5 Possible Diagnoses'),
                  const SizedBox(height: 8),
                  if (result.diagnoses.isEmpty)
                    const Text("No specific diagnoses identified.")
                  else
                    ...result.diagnoses.map((d) => _buildDiagnosisTile(d)).toList(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('AI Purpose Analysis'), // قسم جديد
                  const SizedBox(height: 8),
                  if (result.purposes.isEmpty)
                    const Text("No specific purposes identified.")
                  else
                    ...result.purposes.map((p) => Text('• $p')).toList(),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Recommendations'),
                  const SizedBox(height: 8),
                  ...result.recommendations.entries.map(
                    (e) => Text('• ${e.value}'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDiagnosisTile(Diagnosis diagnosis) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(diagnosis.word, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Type: ${diagnosis.entity}'),
        trailing: Text(
          'Score: ${(diagnosis.score * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: diagnosis.score > 0.8 ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
