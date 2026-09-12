import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_attempt.dart';
import '../utils/app_logger.dart';

class QuizAttemptService {
  final _col = FirebaseFirestore.instance.collection('quiz_attempts');

  Future<void> record(QuizAttempt attempt) async {
    try {
      await _col.add(attempt.toJson());
    } catch (e) {
      AppLogger.e('Error recording quiz attempt', error: e);
    }
  }

  Stream<List<QuizAttempt>> myAttempts(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => QuizAttempt.fromDoc(d.id, d.data())).toList());
  }
}
