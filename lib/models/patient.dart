class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final String? notes;
  final List<String> symptoms;
  final List<String> diagnoses;

  // --- الحقول التي تريدينها بشدة ---
  final String department;
  final String wardNumber;
  final String roomNumber;
  final String doctorId;

  // --- وسم الحالة الطارئة ---
  // isUrgent يجتمع فيه مصدران: تقييم الطبيب اليدوي، أو تحليل النظام
  // السريري التلقائي بعد أخذ التاريخ المرضي (عندما تكون الخطورة
  // Urgent/High). urgentSource يوضح مين وضع العلامة: 'manual' أو 'system'.
  final bool isUrgent;
  final String? urgentSource;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.dateOfBirth,
    required this.createdAt,
    this.notes,
    this.symptoms = const [],
    this.diagnoses = const [],
    // --- التأكد من أنها إجبارية ---
    required this.department,
    required this.wardNumber,
    required this.roomNumber,
    required this.doctorId,
    this.isUrgent = false,
    this.urgentSource,
  });

  // --- دالة التحويل من JSON (مهمة لقاعدة البيانات) ---
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      diagnoses: List<String>.from(json['diagnoses'] ?? []),
      // --- قراءة الحقول الجديدة من قاعدة البيانات ---
      department: json['department'] ?? 'General', // قيمة افتراضية للبيانات القديمة
      wardNumber: json['wardNumber'] ?? 'N/A',
      roomNumber: json['roomNumber'] ?? 'N/A',
      doctorId: json['doctorId'],
      isUrgent: json['isUrgent'] ?? false,
      urgentSource: json['urgentSource'],
    );
  }

  // --- دالة التحويل إلى JSON (مهمة لقاعدة البيانات) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'symptoms': symptoms,
      'diagnoses': diagnoses,
      // --- حفظ الحقول الجديدة في قاعدة البيانات ---
      'department': department,
      'wardNumber': wardNumber,
      'roomNumber': roomNumber,
      'doctorId': doctorId,
      'isUrgent': isUrgent,
      'urgentSource': urgentSource,
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? wardNumber,
    String? roomNumber,
    String? department,
    String? doctorId,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    String? notes,
    List<String>? symptoms,
    List<String>? diagnoses,
    bool? isUrgent,
    String? urgentSource,
    bool clearUrgentSource = false,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      diagnoses: diagnoses ?? this.diagnoses,
      department: department ?? this.department,
      wardNumber: wardNumber ?? this.wardNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      doctorId: doctorId ?? this.doctorId,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentSource:
          clearUrgentSource ? null : (urgentSource ?? this.urgentSource),
    );
  }
}
