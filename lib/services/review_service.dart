import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review_request.dart';
import '../utils/app_logger.dart';

/// Handles submitting cases for mentor review and reading back the
/// resulting feedback. See firestore.rules for the access model: a
/// request/review is create-then-read-only, and the reviewer never needs
/// direct access to the student's /patients data because the request
/// carries a denormalized snapshot.
class ReviewService {
  final _requests = FirebaseFirestore.instance.collection('review_requests');

  Future<String> submitForReview(ReviewRequest request) async {
    try {
      final doc = await _requests.add(request.toJson());
      return doc.id;
    } catch (e) {
      AppLogger.e('Error submitting case for review', error: e);
      rethrow;
    }
  }

  /// Cases a specific student has submitted, newest first.
  Stream<List<ReviewRequest>> myRequests(String studentId) {
    return _requests
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ReviewRequest.fromDoc(d.id, d.data()))
            .toList());
  }

  /// All submitted cases across every student, for the doctor review
  /// queue. Newest first; the queue screen itself filters out ones that
  /// already have a review.
  Stream<List<ReviewRequest>> allRequests() {
    return _requests
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ReviewRequest.fromDoc(d.id, d.data()))
            .toList());
  }

  Stream<List<MentorReview>> reviewsFor(String requestId) {
    return _requests
        .doc(requestId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MentorReview.fromDoc(d.id, d.data())).toList());
  }

  Future<void> submitReview(String requestId, MentorReview review) async {
    try {
      await _requests.doc(requestId).collection('reviews').add(review.toJson());
    } catch (e) {
      AppLogger.e('Error submitting mentor review', error: e);
      rethrow;
    }
  }
}
