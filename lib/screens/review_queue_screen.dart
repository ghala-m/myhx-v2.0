import 'package:flutter/material.dart';

import '../models/review_request.dart';
import '../services/review_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';
import 'review_detail_screen.dart';

/// Doctor-facing queue of every case any student has submitted for
/// review, across the whole app (not scoped to one supervisor — small
/// teaching setups don't usually need per-mentor assignment).
class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: StreamBuilder<List<ReviewRequest>>(
        stream: reviewService.allRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('No cases submitted yet',
                        style: AppTypography.titleMedium(context)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewDetailScreen(request: r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.patientName,
                                style: AppTypography.titleMedium(context)),
                            const SizedBox(height: 2),
                            Text('${r.department} • by ${r.studentName}',
                                style: AppTypography.caption(context)),
                          ],
                        ),
                      ),
                      StreamBuilder<List<MentorReview>>(
                        stream: reviewService.reviewsFor(r.id),
                        builder: (context, snap) {
                          final reviewed = (snap.data ?? []).isNotEmpty;
                          return Icon(
                            reviewed
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: reviewed ? Colors.green : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
