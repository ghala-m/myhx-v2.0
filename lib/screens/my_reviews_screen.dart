import 'package:flutter/material.dart';

import '../models/review_request.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';

/// A student's own submitted cases, each expandable to show the mentor's
/// feedback once it arrives.
class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final reviewService = ReviewService();

    return Scaffold(
      appBar: AppBar(title: const Text('My submissions')),
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<List<ReviewRequest>>(
              stream: reviewService.myRequests(user.uid),
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
                          Icon(Icons.forum_outlined,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No cases submitted yet',
                            style: AppTypography.titleMedium(context),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Open any patient record and tap "Submit for mentor review".',
                            style: AppTypography.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: requests.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RequestCard(request: requests[i]),
                  ),
                );
              },
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ReviewRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.patientName,
                    style: AppTypography.titleMedium(context)),
              ),
              if (request.riskLevel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(request.riskLevel,
                      style: AppTypography.caption(context)),
                ),
            ],
          ),
          Text(request.department, style: AppTypography.caption(context)),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<List<MentorReview>>(
            stream: ReviewService().reviewsFor(request.id),
            builder: (context, snapshot) {
              final reviews = snapshot.data ?? const [];
              if (reviews.isEmpty) {
                return Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Awaiting review',
                        style: AppTypography.caption(context)),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reviews
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < r.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(r.reviewerName,
                                        style: AppTypography.caption(context)),
                                  ],
                                ),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r.comment,
                                      style:
                                          AppTypography.bodyMedium(context)),
                                ],
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
