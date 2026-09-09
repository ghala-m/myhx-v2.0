import 'package:cloud_firestore/cloud_firestore.dart';

/// A question a student proposes for the department question bank, or a
/// free-form "notebook" note they want turned into one or more questions
/// by a developer. See services/question_suggestion_service.dart and
/// screens/submit_question_screen.dart (student) /
/// question_editor_screen.dart (developer review).
class QuestionSuggestion {
  final String id;
  final String submittedBy;
  final String submittedByName;
  final String department; // department id, or '' for notebook notes not tied to one
  final String type; // 'question' | 'notebook'
  final String status; // 'pending' | 'approved' | 'rejected'

  // Used when type == 'question'
  final String en;
  final String ar;
  final String questionType; // text/textarea/boolean/select/number
  final List<String> options;
  final bool critical;

  // Used when type == 'notebook'
  final String notebookText;

  final String? reviewNote;
  final DateTime createdAt;

  const QuestionSuggestion({
    required this.id,
    required this.submittedBy,
    required this.submittedByName,
    required this.department,
    required this.type,
    required this.status,
    this.en = '',
    this.ar = '',
    this.questionType = 'text',
    this.options = const [],
    this.critical = false,
    this.notebookText = '',
    this.reviewNote,
    required this.createdAt,
  });

  factory QuestionSuggestion.fromDoc(String id, Map<String, dynamic> json) {
    return QuestionSuggestion(
      id: id,
      submittedBy: json['submittedBy'] ?? '',
      submittedByName: json['submittedByName'] ?? '',
      department: json['department'] ?? '',
      type: json['type'] ?? 'question',
      status: json['status'] ?? 'pending',
      en: json['en'] ?? '',
      ar: json['ar'] ?? '',
      questionType: json['questionType'] ?? 'text',
      options: ((json['options'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      critical: json['critical'] == true,
      notebookText: json['notebookText'] ?? '',
      reviewNote: json['reviewNote'],
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'department': department,
        'type': type,
        'status': status,
        'en': en,
        'ar': ar,
        'questionType': questionType,
        'options': options,
        'critical': critical,
        'notebookText': notebookText,
        if (reviewNote != null) 'reviewNote': reviewNote,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
