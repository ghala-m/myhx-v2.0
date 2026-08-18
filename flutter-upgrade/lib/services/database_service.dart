import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart'; // استيراد نموذج المريض

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // تصحيح: استخدام FirebaseFirestore.instance

  // الحصول على مرجع (reference) لمجموعة المرضى في Firestore
  CollectionReference get _patientsCollection => _firestore.collection('patients');

  // --- دالة لإضافة مريض جديد ---
  Future<String> addPatient(Patient patient) async {
    try {
      // دع Firestore يولد معرف المستند تلقائيًا
      final docRef = await _patientsCollection.add(patient.toJson());
      // تحديث معرف المريض في الكائن المحلي بمعرف Firestore
      // هذا يضمن أن معرف المريض في الكائن المحلي هو نفسه معرف المستند في Firestore
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Error adding patient: $e');
      rethrow;
    }
  }

  // --- دالة لجلب قائمة كل المرضى لطبيب معين ---
  Future<List<Patient>> getPatients(String doctorId) async {
    try {
      final snapshot = await _patientsCollection
          .where('doctorId', isEqualTo: doctorId) // تصفية حسب معرف الطبيب
          .orderBy('createdAt', descending: true)
          .get();

      // تحويل كل مستند (document) إلى كائن Patient
      return snapshot.docs.map((doc) {
        return Patient.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting patients: $e');
      return []; // إرجاع قائمة فارغة في حال حدوث خطأ
    }
  }

  // --- دالة لتحديث بيانات مريض (مثل حالته) ---
  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    try {
      await _patientsCollection.doc(patientId).update(dataToUpdate);
    } catch (e) {
      print('Error updating patient: $e');
      rethrow;
    }
  }

  // --- دالة لحذف مريض ---
  Future<void> deletePatient(String patientId) async {
    try {
      await _patientsCollection.doc(patientId).delete();
    } catch (e) {
      print('Error deleting patient: $e');
      rethrow;
    }
  }

  // --- دالة لإنشاء تقرير طبي جديد ---
  Future<String> createReport({
    required String doctorId,
    required String patientId,
    required Map<String, dynamic> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
    required Patient patient,
  }) async {
    print("=== createReport START ===");
    print("Doctor ID: $doctorId");
    print("Patient ID: $patientId");
    print("Patient Name: ${patient.name}");
    
    // التحقق من صحة patientId
    if (patientId.isEmpty) {
      print("ERROR: patientId is empty!");
      throw Exception("Patient ID cannot be empty");
    }
    
    try {
      // التحقق من وجود المريض أولاً
      final patientDoc = await _patientsCollection.doc(patientId).get();
      if (!patientDoc.exists) {
        print("ERROR: Patient document does not exist for patientId: $patientId");
        throw Exception("Patient not found in database");
      }
      print("Patient document exists, proceeding with report creation...");
      
      final reportRef = _patientsCollection
          .doc(patientId)
          .collection("reports")
          .doc();
      final reportId = reportRef.id;

      print('Creating report with ID: $reportId');
      print('Medical History keys: ${medicalHistory.keys.toList()}');
      print('Medical History values count: ${medicalHistory.length}');
      print('AI Analysis: ${aiAnalysis != null ? "Present" : "Null"}');
      
      final reportData = {
        "reportId": reportId,
        "doctorId": doctorId,
        "patientId": patientId,
        "medicalHistory": medicalHistory,
        "aiAnalysis": aiAnalysis ?? {},
        "createdAt": FieldValue.serverTimestamp(),
      };

      print("Writing report to Firestore...");
      await reportRef.set(reportData);
      print("Report created successfully!");
      print("=== createReport END (SUCCESS) ===");
      return reportId;
    } catch (e, stackTrace) {
      print("ERROR in createReport: $e");
      print("Stack trace: $stackTrace");
      print("=== createReport END (ERROR) ===");
      rethrow;
    }
  }

  // --- دالة لجلب تقرير طبي محدد بواسطة reportId ---
  Future<Map<String, dynamic>?> getMedicalReportById(String reportId) async {
    try {
      // Assuming reportId is the document ID within the medical_histories collection
      final docSnapshot = await _firestore.collection("medical_histories").doc(reportId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print("Error getting medical report by ID: $e");
      return null;
    }
  }

  // --- دالة لجلب أحدث تقرير طبي لمريض معين (جديدة) ---
  Future<Map<String, dynamic>?> getLatestMedicalReport(String patientId) async {
    print("=== getLatestMedicalReport START ===");
    print("Attempting to get latest medical report for patientId: $patientId");
    
    // التحقق من صحة patientId
    if (patientId.isEmpty) {
      print("ERROR: patientId is empty!");
      return null;
    }
    
    try {
      // التحقق من وجود المريض أولاً
      final patientDoc = await _patientsCollection.doc(patientId).get();
      if (!patientDoc.exists) {
        print("ERROR: Patient document does not exist for patientId: $patientId");
        return null;
      }
      print("Patient document exists: ${patientDoc.data()}");
      
      // جلب التقارير
      final reportsCollection = _patientsCollection
          .doc(patientId)
          .collection('reports');
      
      print("Querying reports collection...");
      final querySnapshot = await reportsCollection
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      print("Query completed. Number of documents found: ${querySnapshot.docs.length}");
      
      if (querySnapshot.docs.isNotEmpty) {
        final reportData = querySnapshot.docs.first.data();
        print("Found latest medical report for patientId: $patientId");
        print("Report ID: ${querySnapshot.docs.first.id}");
        print("Report data keys: ${reportData.keys.toList()}");
        print("Medical History exists: ${reportData.containsKey('medicalHistory')}");
        print("AI Analysis exists: ${reportData.containsKey('aiAnalysis')}");
        
        // التحقق من وجود البيانات المطلوبة
        if (!reportData.containsKey('medicalHistory') && !reportData.containsKey('aiAnalysis')) {
          print("WARNING: Report exists but contains no medicalHistory or aiAnalysis");
        }
        
        print("=== getLatestMedicalReport END (SUCCESS) ===");
        return reportData;
      }
      
      print("No reports found for patientId: $patientId");
      print("=== getLatestMedicalReport END (NO DATA) ===");
      return null; // لا يوجد تقرير لهذا المريض
    } catch (e, stackTrace) {
      print("ERROR in getLatestMedicalReport for patientId: $patientId");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      print("=== getLatestMedicalReport END (ERROR) ===");
      return null;
    }
  }

  // --- دالة لجلب التقارير الخاصة بطبيب معين ---
  Stream<List<Map<String, dynamic>>> getReportsForDoctor(String doctorId) {
    // هذا الاستعلام يجلب التقارير مباشرة من جميع المرضى التابعين للطبيب
    // يتطلب أن يكون هناك حقل 'doctorId' في كل تقرير لتصفية فعالة
    return _patientsCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((patientSnapshot) async {
          List<Map<String, dynamic>> allReports = [];
          for (var doc in patientSnapshot.docs) {
            final patientId = doc.id;
            final reportsSnapshot = await _patientsCollection
                .doc(patientId)
                .collection("reports")
                .orderBy("createdAt", descending: true)
                .get();
            for (var reportDoc in reportsSnapshot.docs) {
              allReports.add(reportDoc.data());
            }
          }
          // Sort all reports by createdAt descending
          allReports.sort((a, b) {
            final aTime =
                (a["createdAt"] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime =
                (b["createdAt"] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
          return allReports;
        });
  }

  // --- دالة لجلب بروفايل الطبيب ---
  Future<Map<String, dynamic>?> getDoctorProfile(String uid) async {
    try {      final doc = await _firestore.collection('users').doc(uid).get();      return doc.data();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future getMedicalHistory(String id) async {}
}


