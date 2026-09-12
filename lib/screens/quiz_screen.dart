import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quiz_attempt.dart';
import '../models/quiz_question.dart';
import '../services/clinical_ai_service.dart';
import '../services/quiz_attempt_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';

/// A short self-review quiz generated from the exact same clinical rules
/// the app's analysis engine uses — see [ClinicalAIService.generateQuiz].
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions;
  int _index = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = ClinicalAIService().generateQuiz(count: 8);
  }

  void _selectOption(int i) {
    if (_answered) return;
    setState(() {
      _selectedOption = i;
      _answered = true;
      if (i == _questions[_index].correctIndex) _correctCount++;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      setState(() => _index++); // move past the end -> shows results
      _saveAttempt();
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _saveAttempt() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    QuizAttemptService().record(QuizAttempt(
      id: '',
      userId: user.uid,
      correctCount: _correctCount,
      totalQuestions: _questions.length,
      createdAt: DateTime.now(),
    ));
  }

  void _restart() {
    setState(() {
      _questions.shuffle();
      _index = 0;
      _correctCount = 0;
      _selectedOption = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Self-review quiz')),
        body: const Center(child: Text('No questions available right now.')),
      );
    }

    final finished = _index >= _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(finished
            ? 'Results'
            : 'Question ${_index + 1} of ${_questions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: finished ? _resultsView(context) : _questionView(context),
        ),
      ),
    );
  }

  Widget _questionView(BuildContext context) {
    final q = _questions[_index];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (_index) / _questions.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(q.prompt, style: AppTypography.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _optionTile(context, q, i),
          ),
        ),
        if (_answered) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedOption == q.correctIndex
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _selectedOption == q.correctIndex
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _selectedOption == q.correctIndex
                          ? 'Correct'
                          : 'Not quite',
                      style: AppTypography.titleMedium(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(q.explanation, style: AppTypography.bodyMedium(context)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _next,
              child: Text(_index == _questions.length - 1
                  ? 'See results'
                  : 'Next question'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionTile(BuildContext context, QuizQuestion q, int i) {
    final theme = Theme.of(context);
    Color? borderColor;
    Color? bgColor;
    IconData? trailingIcon;

    if (_answered) {
      if (i == q.correctIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.08);
        trailingIcon = Icons.check_circle_rounded;
      } else if (i == _selectedOption) {
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withValues(alpha: 0.08);
        trailingIcon = Icons.cancel_rounded;
      }
    }

    return InkWell(
      onTap: () => _selectOption(i),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor ?? theme.colorScheme.outlineVariant,
            width: borderColor != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(q.options[i], style: AppTypography.bodyLarge(context)),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: borderColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _resultsView(BuildContext context) {
    final total = _questions.length;
    final pct = (_correctCount / total * 100).round();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pct >= 70 ? Icons.emoji_events_rounded : Icons.school_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('$_correctCount / $total correct',
              style: AppTypography.displayMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          Text('$pct%', style: AppTypography.titleLarge(context)),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try another set'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
