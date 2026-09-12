import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/progress_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../widgets/app_card.dart';
import 'my_reviews_screen.dart';
import 'quiz_screen.dart';
import 'submit_question_screen.dart';
import 'teaching_cases_screen.dart';

/// The student-facing 'Learn' destination — takes the slot doctors see as
/// 'Insights' (AnalyticsScreen). Organized into clear sections: your
/// progress (streak, points, badges — all computed from real data, no
/// separate counter to fall out of sync), then Practice, Feedback, and
/// Contribute.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  final _progressService = ProgressService();
  late Future<StudentProgressStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<StudentProgressStats> _fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return StudentProgressStats.empty;
    return _progressService.forUser(user.uid);
  }

  void _refresh() => setState(() => _statsFuture = _fetchStats());

  @override
  Widget build(BuildContext context) {
    final arabic = context.watch<LocaleProvider>().isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(arabic ? 'التعلّم' : 'Learn')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            FutureBuilder<StudentProgressStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? StudentProgressStats.empty;
                return _progressHeader(context, stats, arabic);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionLabel(context, arabic ? 'التدريب' : 'Practice'),
            AppCard(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
                _refresh();
              },
              child: _row(
                context,
                icon: Icons.quiz_rounded,
                iconBg: theme.colorScheme.primaryContainer,
                iconColor: theme.colorScheme.primary,
                title: arabic ? 'اختبار مراجعة ذاتية' : 'Self-review quiz',
                subtitle: arabic
                    ? 'أسئلة مبنية على نفس منطق التحليل السريري في التطبيق'
                    : 'Questions drawn from the app\'s own clinical reasoning',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TeachingCasesScreen()),
              ),
              child: _row(
                context,
                icon: Icons.menu_book_outlined,
                iconBg: theme.colorScheme.primaryContainer,
                iconColor: theme.colorScheme.primary,
                title: arabic ? 'حالات تعليمية' : 'Teaching cases',
                subtitle: arabic
                    ? 'حالات حقيقية سابقة، بدون أي معلومة شخصية'
                    : 'Real past cases, fully de-identified',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionLabel(context, arabic ? 'الملاحظات' : 'Feedback'),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
              ),
              child: _row(
                context,
                icon: Icons.forum_outlined,
                iconBg: theme.colorScheme.secondaryContainer,
                iconColor: theme.colorScheme.onSecondaryContainer,
                title: arabic ? 'مراجعة المشرف' : 'Mentor feedback',
                subtitle: arabic
                    ? 'تعليقات مشرفك على الحالات اللي أرسلتها'
                    : 'Feedback from your supervisor on cases you\'ve submitted',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionLabel(context, arabic ? 'المساهمة' : 'Contribute'),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubmitQuestionScreen()),
              ),
              child: _row(
                context,
                icon: Icons.lightbulb_outline_rounded,
                iconBg: theme.colorScheme.tertiaryContainer,
                iconColor: theme.colorScheme.onTertiaryContainer,
                title: arabic ? 'اقترح سؤالًا' : 'Suggest a question',
                subtitle: arabic
                    ? 'أضف سؤالًا منظّمًا أو الصق نوت بوك ليحوّله المبرمج لأسئلة'
                    : 'Add a structured question, or paste a notebook for a developer to convert',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _progressHeader(
      BuildContext context, StudentProgressStats stats, bool arabic) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                arabic ? 'تقدّمك' : 'Your progress',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (stats.streakDays > 0)
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 2),
                    Text('${stats.streakDays}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _statChip(context, '${stats.casesTaken}',
                  arabic ? 'حالة' : 'cases'),
              const SizedBox(width: AppSpacing.md),
              _statChip(
                context,
                stats.quizAttempts == 0
                    ? '—'
                    : '${(stats.quizAverage * 100).round()}%',
                arabic ? 'متوسط الاختبار' : 'quiz avg',
              ),
              const SizedBox(width: AppSpacing.md),
              _statChip(context, '${stats.points}',
                  arabic ? 'نقطة' : 'points'),
            ],
          ),
          if (stats.badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stats.badges
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption(context).copyWith(letterSpacing: 1),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium(context)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption(context)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}
