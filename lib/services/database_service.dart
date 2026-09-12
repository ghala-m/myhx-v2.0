import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart'; // استيراد نموذج المريض
import '../utils/app_logger.dart';

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
      AppLogger.d('Error adding patient: $e');
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
      AppLogger.d('Error getting patients: $e');
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
      AppLogger.d('Error updating patient: $e');
      rethrow;
    }
  }

  // --- دالة لوضع/إزالة وسم "طارئ" على مريض ---
  // source: 'manual' عند تقييم الطبيب اليدوي، أو 'system' عند التصعيد
  // التلقائي بعد تحليل سريري بخطورة Urgent/High. عند الإزالة اليدوية
  // (value=false) يُمسح المصدر أيضًا.
  Future<void> setPatientUrgent(
    String patientId,
    bool value, {
    String source = 'manual',
  }) async {
    try {
      await _patientsCollection.doc(patientId).update({
        'isUrgent': value,
        'urgentSource': value ? source : null,
      });
    } catch (e) {
      AppLogger.e('Error setting patient urgent flag', error: e);
      rethrow;
    }
  }

  // --- دالة لحذف مريض ---
  Future<void> deletePatient(String patientId) async {
    try {
      await _patientsCollection.doc(patientId).delete();
    } catch (e) {
      AppLogger.d('Error deleting patient: $e');
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
    AppLogger.d("=== createReport START ===");
    AppLogger.d("Doctor ID: $doctorId");
    AppLogger.d("Patient ID: $patientId");
    AppLogger.d("Patient Name: ${patient.name}");
    
    // التحقق من صحة patientId
    if (patientId.isEmpty) {
      AppLogger.d("ERROR: patientId is empty!");
      throw Exception("Patient ID cannot be empty");
    }
    
    try {
      // التحقق من وجود المريض أولاً
      final patientDoc = await _patientsCollection.doc(patientId).get();
      if (!patientDoc.exists) {
        AppLogger.d("ERROR: Patient document does not exist for patientId: $patientId");
        throw Exception("Patient not found in database");
      }
      AppLogger.d("Patient document exists, proceeding with report creation...");
      
      final reportRef = _patientsCollection
          .doc(patientId)
          .collection("reports")
          .doc();
      final reportId = reportRef.id;

      AppLogger.d('Creating report with ID: $reportId');
      AppLogger.d('Medical History keys: ${medicalHistory.keys.toList()}');
      AppLogger.d('Medical History values count: ${medicalHistory.length}');
      AppLogger.d('AI Analysis: ${aiAnalysis != null ? "Present" : "Null"}');
      
      final reportData = {
        "reportId": reportId,
        "doctorId": doctorId,
        "patientId": patientId,
        "medicalHistory": medicalHistory,
        "aiAnalysis": aiAnalysis ?? {},
        "createdAt": FieldValue.serverTimestamp(),
      };

      AppLogger.d("Writing report to Firestore...");
      await reportRef.set(reportData);
      AppLogger.d("Report created successfully!");
      AppLogger.d("=== createReport END (SUCCESS) ===");
      return reportId;
    } catch (e, stackTrace) {
      AppLogger.d("ERROR in createReport: $e");
      AppLogger.d("Stack trace: $stackTrace");
      AppLogger.d("=== createReport END (ERROR) ===");
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
      AppLogger.d("Error getting medical report by ID: $e");
      return null;
    }
  }

  // --- دالة لجلب أحدث تقرير طبي لمريض معين (جديدة) ---
  Future<Map<String, dynamic>?> getLatestMedicalReport(String patientId) async {
    AppLogger.d("=== getLatestMedicalReport START ===");
    AppLogger.d("Attempting to get latest medical report for patientId: $patientId");
    
    // التحقق من صحة patientId
    if (patientId.isEmpty) {
      AppLogger.d("ERROR: patientId is empty!");
      return null;
    }
    
    try {
      // التحقق من وجود المريض أولاً
      final patientDoc = await _patientsCollection.doc(patientId).get();
      if (!patientDoc.exists) {
        AppLogger.d("ERROR: Patient document does not exist for patientId: $patientId");
        return null;
      }
      AppLogger.d("Patient document exists: ${patientDoc.data()}");
      
      // جلب التقارير
      final reportsCollection = _patientsCollection
          .doc(patientId)
          .collection('reports');
      
      AppLogger.d("Querying reports collection...");
      final querySnapshot = await reportsCollection
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      AppLogger.d("Query completed. Number of documents found: ${querySnapshot.docs.length}");
      
      if (querySnapshot.docs.isNotEmpty) {
        final reportData = querySnapshot.docs.first.data();
        AppLogger.d("Found latest medical report for patientId: $patientId");
        AppLogger.d("Report ID: ${querySnapshot.docs.first.id}");
        AppLogger.d("Report data keys: ${reportData.keys.toList()}");
        AppLogger.d("Medical History exists: ${reportData.containsKey('medicalHistory')}");
        AppLogger.d("AI Analysis exists: ${reportData.containsKey('aiAnalysis')}");
        
        // التحقق من وجود البيانات المطلوبة
        if (!reportData.containsKey('medicalHistory') && !reportData.containsKey('aiAnalysis')) {
          AppLogger.d("WARNING: Report exists but contains no medicalHistory or aiAnalysis");
        }
        
        AppLogger.d("=== getLatestMedicalReport END (SUCCESS) ===");
        return reportData;
      }
      
      AppLogger.d("No reports found for patientId: $patientId");
      AppLogger.d("=== getLatestMedicalReport END (NO DATA) ===");
      return null; // لا يوجد تقرير لهذا المريض
    } catch (e, stackTrace) {
      AppLogger.d("ERROR in getLatestMedicalReport for patientId: $patientId");
      AppLogger.d("Error: $e");
      AppLogger.d("Stack trace: $stackTrace");
      AppLogger.d("=== getLatestMedicalReport END (ERROR) ===");
      return null;
    }
  }

  // --- دالة لجلب التقارير الخاصة بطبيب معين ---
  // --- دالة لجلب التقارير الخاصة بطبيب معين (مع بيانات المريض مدمجة) ---
  //
  // ملاحظة أداء: كل تقرير يُخزَّن أصلاً وعليه حقل 'doctorId'، لذلك نستخدم
  // collectionGroup query واحد لكل التقارير + استعلام واحد لكل مرضى الطبيب،
  // ثم نربطهما في الذاكرة. المجموع: استعلامان ثابتان بغض النظر عن عدد
  // المرضى — بدلاً من النمط القديم (استعلام لكل مرضى الطبيب) + (استعلام
  // منفصل لكل مريض على حدة لتقاريره)، وهو نمط N+1 كان يبطئ الأداء ويرفع
  // تكلفة قراءات Firestore مع نمو عدد المرضى.
  // يتطلب هذا فهرسًا مركّبًا على مجموعة 'reports' (doctorId ASC,
  // createdAt DESC) — راجع firestore.indexes.json.
  Stream<List<Map<String, dynamic>>> getReportsForDoctor(String doctorId) {
    final reportsStream = _firestore
        .collectionGroup('reports')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return reportsStream.asyncMap((snapshot) async {
      final patientsSnapshot =
          await _patientsCollection.where('doctorId', isEqualTo: doctorId).get();
      final patientsById = {
        for (final doc in patientsSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final patientId = doc.reference.parent.parent?.id ?? '';
        final patientData = patientsById[patientId];
        return {
          ...data,
          'reportId': doc.id,
          'patientId': patientId,
          'patientName': patientData?['name'] ?? '',
          'patientAge': patientData?['age'],
          'patientGender': patientData?['gender'] ?? '',
          'patientDepartment': patientData?['department'] ?? '',
          'patientData': patientData,
        };
      }).toList();
    });
  }

  // --- دالة لجلب بروفايل الطبيب ---
  Future<Map<String, dynamic>?> getDoctorProfile(String uid) async {
    try {      final doc = await _firestore.collection('users').doc(uid).get();      return doc.data();
    } catch (e) {
      AppLogger.d(e);
      return null;
    }
  }

  Future getMedicalHistory(String id) async {}

  // --- تدفق تقارير مريض واحد (Timeline) ---
  Stream<List<Map<String, dynamic>>> getReportsForPatient(String patientId) {
    return _patientsCollection
        .doc(patientId)
        .collection("reports")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'reportId': d.id, 'patientId': patientId})
            .toList());
  }
}
