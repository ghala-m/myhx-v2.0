import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../widgets/app_card.dart';
import 'my_reviews_screen.dart';
import 'quiz_screen.dart';
import 'submit_question_screen.dart';

/// The student-facing 'Learn' destination — takes the slot doctors see as
/// 'Insights' (AnalyticsScreen). Starts with a self-review quiz; mentor
/// feedback is planned to land here next.
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final arabic = context.watch<LocaleProvider>().isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(arabic ? 'التعلّم' : 'Learn')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(Icons.quiz_rounded,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabic ? 'اختبار مراجعة ذاتية' : 'Self-review quiz',
                          style: AppTypography.titleMedium(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          arabic
                              ? 'أسئلة مبنية على نفس منطق التحليل السريري في التطبيق'
                              : 'Questions drawn from the app\'s own clinical reasoning',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(Icons.forum_outlined,
                        color: theme.colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabic ? 'مراجعة المشرف' : 'Mentor feedback',
                          style: AppTypography.titleMedium(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          arabic
                              ? 'تعليقات مشرفك على الحالات اللي أرسلتها'
                              : 'Feedback from your supervisor on cases you\'ve submitted',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubmitQuestionScreen()),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        color: theme.colorScheme.onTertiaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabic ? 'اقترح سؤالًا' : 'Suggest a question',
                          style: AppTypography.titleMedium(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          arabic
                              ? 'أضف سؤالًا منظّمًا أو الصق نوت بوك ليحوّله المبرمج لأسئلة'
                              : 'Add a structured question, or paste a notebook for a developer to convert',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
