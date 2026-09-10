import 'package:cloud_firestore/cloud_firestore.dart';

/// A request to transfer real, full care of a patient to another
/// doctor/student. Unlike [TeachingCase], nothing is de-identified here —
/// by design, since this is a genuine handoff of care. That's exactly
/// why it's a two-step request/accept flow instead of an instant copy:
/// the receiving account must explicitly accept before any real data
/// moves, and the actual copy is performed server-side (see
/// functions/index.js: onCaseReferralAccepted) using the Admin SDK, which
/// is the only thing allowed to read across two different doctors'
/// patient data — the Flutter client never gets cross-account read
/// access at any point.
class CaseReferral {
  final String id;
  final String patientId;
  final String fromDoctorId;
  final String fromDoctorName;
  final String toDoctorId;
  final String patientNamePreview;
  final String department;
  final String status; // 'pending' | 'accepted' | 'declined'
  final String? newPatientId; // filled in by the Cloud Function once accepted
  final DateTime createdAt;

  const CaseReferral({
    required this.id,
    required this.patientId,
    required this.fromDoctorId,
    required this.fromDoctorName,
    required this.toDoctorId,
    required this.patientNamePreview,
    required this.department,
    required this.status,
    this.newPatientId,
    required this.createdAt,
  });

  factory CaseReferral.fromDoc(String id, Map<String, dynamic> json) {
    return CaseReferral(
      id: id,
      patientId: json['patientId'] ?? '',
      fromDoctorId: json['fromDoctorId'] ?? '',
      fromDoctorName: json['fromDoctorName'] ?? '',
      toDoctorId: json['toDoctorId'] ?? '',
      patientNamePreview: json['patientNamePreview'] ?? '',
      department: json['department'] ?? '',
      status: json['status'] ?? 'pending',
      newPatientId: json['newPatientId'],
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'fromDoctorId': fromDoctorId,
        'fromDoctorName': fromDoctorName,
        'toDoctorId': toDoctorId,
        'patientNamePreview': patientNamePreview,
        'department': department,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
