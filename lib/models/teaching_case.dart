import 'package:cloud_firestore/cloud_firestore.dart';

/// A fully de-identified copy of a past case, shared for teaching. No
/// name, exact age, ward/room, or any other identifier survives — only
/// the clinical content. Created entirely client-side by the owning
/// doctor from their own patient record (no cross-doctor access needed,
/// since they only ever read their own data before stripping it), then
/// world-readable so any signed-in doctor/student can learn from it.
class TeachingCase {
  final String id;
  final String sourceDoctorId;
  final String department;
  final String ageRange; // e.g. "30-39", never an exact age
  final String gender;
  final String chiefComplaint;
  final String riskLevel;
  final String soapNote;
  final DateTime createdAt;

  const TeachingCase({
    required this.id,
    required this.sourceDoctorId,
    required this.department,
    required this.ageRange,
    required this.gender,
    required this.chiefComplaint,
    required this.riskLevel,
    required this.soapNote,
    required this.createdAt,
  });

  factory TeachingCase.fromDoc(String id, Map<String, dynamic> json) {
    return TeachingCase(
      id: id,
      sourceDoctorId: json['sourceDoctorId'] ?? '',
      department: json['department'] ?? '',
      ageRange: json['ageRange'] ?? '',
      gender: json['gender'] ?? '',
      chiefComplaint: json['chiefComplaint'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
      soapNote: json['soapNote'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceDoctorId': sourceDoctorId,
        'department': department,
        'ageRange': ageRange,
        'gender': gender,
        'chiefComplaint': chiefComplaint,
        'riskLevel': riskLevel,
        'soapNote': soapNote,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static String bucketAge(int age) {
    final start = (age ~/ 10) * 10;
    return '$start-${start + 9}';
  }
}
