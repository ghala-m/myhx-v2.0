import 'package:cloud_firestore/cloud_firestore.dart';

/// A case a student has submitted for a doctor/developer to review.
/// The report content is intentionally denormalized onto this document
/// (patientName, department, chiefComplaint, riskLevel, soapNote) so a
/// reviewing doctor never needs read access to the student's /patients
/// document or report — they only ever see this snapshot.
class ReviewRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String patientId;
  final String reportId;
  final String patientName;
  final String department;
  final String chiefComplaint;
  final String riskLevel;
  final String soapNote;
  final DateTime createdAt;

  const ReviewRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.patientId,
    required this.reportId,
    required this.patientName,
    required this.department,
    required this.chiefComplaint,
    required this.riskLevel,
    required this.soapNote,
    required this.createdAt,
  });

  factory ReviewRequest.fromDoc(String id, Map<String, dynamic> json) {
    return ReviewRequest(
      id: id,
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      patientId: json['patientId'] ?? '',
      reportId: json['reportId'] ?? '',
      patientName: json['patientName'] ?? '',
      department: json['department'] ?? '',
      chiefComplaint: json['chiefComplaint'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
      soapNote: json['soapNote'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'patientId': patientId,
        'reportId': reportId,
        'patientName': patientName,
        'department': department,
        'chiefComplaint': chiefComplaint,
        'riskLevel': riskLevel,
        'soapNote': soapNote,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// A single piece of feedback left by a doctor/developer on a
/// [ReviewRequest]. Immutable once written.
class MentorReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  const MentorReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MentorReview.fromDoc(String id, Map<String, dynamic> json) {
    return MentorReview(
      id: id,
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
