import '../services/database_service.dart';
import '../services/question_suggestion_service.dart';
import '../services/quiz_attempt_service.dart';
import '../services/teaching_case_service.dart';

/// A snapshot of a student's progress, computed on the fly from data
/// that already exists (patients taken, quiz attempts, suggestions,
/// teaching cases shared) — no separate points ledger to keep in sync
/// or get out of date.
class StudentProgressStats {
  final int casesTaken;
  final int quizAttempts;
  final double quizAverage; // 0.0-1.0
  final int approvedSuggestions;
  final int teachingCasesShared;
  final int streakDays;

  const StudentProgressStats({
    required this.casesTaken,
    required this.quizAttempts,
    required this.quizAverage,
    required this.approvedSuggestions,
    required this.teachingCasesShared,
    required this.streakDays,
  });

  static const empty = StudentProgressStats(
    casesTaken: 0,
    quizAttempts: 0,
    quizAverage: 0,
    approvedSuggestions: 0,
    teachingCasesShared: 0,
    streakDays: 0,
  );

  /// Simple, transparent points formula — every input is something the
  /// student can see elsewhere in the app, nothing hidden.
  int get points =>
      casesTaken * 10 +
      (quizAttempts * quizAverage * 5).round() +
      approvedSuggestions * 15 +
      teachingCasesShared * 10;

  List<String> get badges {
    final list = <String>[];
    if (casesTaken >= 10) list.add('10 cases taken');
    if (casesTaken >= 50) list.add('50 cases taken');
    if (quizAttempts >= 3 && quizAverage >= 0.9) list.add('Quiz master');
    if (approvedSuggestions >= 1) list.add('Contributor');
    if (teachingCasesShared >= 1) list.add('Educator');
    if (streakDays >= 7) list.add('7-day streak');
    return list;
  }
}

class ProgressService {
  final _db = DatabaseService();
  final _quizzes = QuizAttemptService();
  final _suggestions = QuestionSuggestionService();
  final _teaching = TeachingCaseService();

  Future<StudentProgressStats> forUser(String uid) async {
    final patients = await _db.getPatients(uid);
    final attempts = await _quizzes.myAttempts(uid).first;
    final suggestions = await _suggestions.mySuggestions(uid).first;
    final teaching = await _teaching.mine(uid).first;

    final quizAverage = attempts.isEmpty
        ? 0.0
        : attempts.map((a) => a.percent).reduce((a, b) => a + b) /
            attempts.length;

    return StudentProgressStats(
      casesTaken: patients.length,
      quizAttempts: attempts.length,
      quizAverage: quizAverage,
      approvedSuggestions:
          suggestions.where((s) => s.status == 'approved').length,
      teachingCasesShared: teaching.length,
      streakDays: _streak(patients.map((p) => p.createdAt).toList()),
    );
  }

  int _streak(List<DateTime> timestamps) {
    final days = timestamps.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    if (days.isEmpty) return 0;

    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    // Allow "yesterday" as the anchor too, so the streak doesn't look
    // reset just because the student hasn't acted yet today.
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
