import 'package:cloud_firestore/cloud_firestore.dart';

/// A completed self-review quiz attempt, so progress can actually be
/// tracked (average score, attempt count, streaks) instead of the
/// result vanishing the moment the screen closes.
class QuizAttempt {
  final String id;
  final String userId;
  final int correctCount;
  final int totalQuestions;
  final DateTime createdAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.correctCount,
    required this.totalQuestions,
    required this.createdAt,
  });

  double get percent =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  factory QuizAttempt.fromDoc(String id, Map<String, dynamic> json) {
    return QuizAttempt(
      id: id,
      userId: json['userId'] ?? '',
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'correctCount': correctCount,
        'totalQuestions': totalQuestions,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
