/// A single self-review multiple-choice question, generated from the same
/// clinical rules [ClinicalAIService] uses for live analysis — see
/// [ClinicalAIService.generateQuiz].
class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
