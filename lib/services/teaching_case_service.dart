import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/teaching_case.dart';
import '../utils/app_logger.dart';

class TeachingCaseService {
  final _col = FirebaseFirestore.instance.collection('teaching_cases');

  Future<void> share(TeachingCase teachingCase) async {
    try {
      await _col.add(teachingCase.toJson());
    } catch (e) {
      AppLogger.e('Error sharing teaching case', error: e);
      rethrow;
    }
  }

  /// Every teaching case in the app, browsable by any signed-in user —
  /// safe because it never carries real patient identifiers.
  Stream<List<TeachingCase>> all() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TeachingCase.fromDoc(d.id, d.data())).toList());
  }

  Stream<List<TeachingCase>> mine(String doctorId) {
    return _col
        .where('sourceDoctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TeachingCase.fromDoc(d.id, d.data())).toList());
  }

  Future<void> retract(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      AppLogger.e('Error retracting teaching case', error: e);
      rethrow;
    }
  }
}
