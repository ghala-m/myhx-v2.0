import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question_suggestion.dart';
import '../utils/app_logger.dart';

class QuestionSuggestionService {
  final _col = FirebaseFirestore.instance.collection('question_suggestions');

  Future<void> submit(QuestionSuggestion suggestion) async {
    try {
      await _col.add(suggestion.toJson());
    } catch (e) {
      AppLogger.e('Error submitting question suggestion', error: e);
      rethrow;
    }
  }

  /// A student's own submissions, newest first.
  Stream<List<QuestionSuggestion>> mySuggestions(String uid) {
    return _col
        .where('submittedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => QuestionSuggestion.fromDoc(d.id, d.data()))
            .toList());
  }

  /// Everything still awaiting a developer's decision.
  Stream<List<QuestionSuggestion>> pending() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => QuestionSuggestion.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> setStatus(String id, String status, {String? note}) async {
    try {
      await _col.doc(id).update({
        'status': status,
        if (note != null) 'reviewNote': note,
      });
    } catch (e) {
      AppLogger.e('Error updating suggestion status', error: e);
      rethrow;
    }
  }
}
