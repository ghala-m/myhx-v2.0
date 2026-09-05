import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart'; // استيراد نموذج البيانات

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveAnalysisResult({
    required String patientId,
    required AnalysisResult result,
  }) async {
    try {
      // استخدام toJson() لتحويل الكائنات إلى Map لتخزينها في Firestore
      await _firestore.collection('patients').doc(patientId).update({
        'medical_summary': {
          'summary': result.summary,
          'diagnoses': result.diagnoses.map((d) => d.toJson()).toList(),
          'purposes': result.purposes, // إضافة purposes إلى الحفظ في Firestore
          'recommendations': result.recommendations,
          'createdAt': FieldValue.serverTimestamp(), // إضافة طابع زمني
        }
      });
      print("Analysis result saved to Firebase for patient $patientId");
    } catch (e) {
      print("Error saving to Firebase: $e");
      // يمكنك رمي استثناء هنا للتعامل معه في الواجهة
      throw Exception("Could not save results to Firebase.");
    }
  }
}

