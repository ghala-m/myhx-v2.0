import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String uid;
  final String name;
  final String email;
  final String specialty;
  final String year;

  Doctor({
    required this.uid,
    required this.name,
    required this.email,
    required this.specialty,
    required this.year,
  });

  // Factory constructor to create a Doctor from a Firestore document
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Doctor(
      uid: doc.id,
      name: data['displayName'] ?? '',
      email: data['email'] ?? '',
      specialty: data['specialization'] ?? '',
      year: data['academicYear'] ?? '',
    );
  }

  // Factory constructor to create a Doctor from a Map and a UID
  factory Doctor.fromJson(Map<String, dynamic> data, String uid) {
    return Doctor(
      uid: uid,
      name: data["displayName"] ?? "",
      email: data["email"] ?? "",
      specialty: data["specialization"] ?? "",
      year: data["academicYear"] ?? "",
    );
  }

  // Convert a Doctor object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'specialty': specialty,
      'year': year,
    };
  }
}

