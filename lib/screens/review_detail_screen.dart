import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_request.dart';
import '../services/review_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';

/// The denormalized case snapshot a student submitted, plus a form for
/// the doctor to leave a rating + comment. Existing reviews (from any
/// reviewer) are shown above the form.
class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({super.key, required this.request});

  final ReviewRequest request;

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _submitting = true);
    try {
      await _reviewService.submitReview(
        widget.request.id,
        MentorReview(
          id: '',
          reviewerId: user.uid,
          reviewerName: user.displayName ?? 'Doctor',
          rating: _rating,
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Feedback sent')));
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: Text(r.patientName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.department} • ${r.studentName}',
                      style: AppTypography.caption(context)),
                  if (r.riskLevel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Risk: ${r.riskLevel}',
                        style: AppTypography.bodyMedium(context)),
                  ],
                  if (r.chiefComplaint.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Chief complaint',
                        style: AppTypography.titleMedium(context)),
                    Text(r.chiefComplaint,
                        style: AppTypography.bodyMedium(context)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text('SOAP note', style: AppTypography.titleMedium(context)),
                  Text(r.soapNote, style: AppTypography.bodyMedium(context)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<List<MentorReview>>(
              stream: _reviewService.reviewsFor(r.id),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? const [];
                if (reviews.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Existing feedback',
                        style: AppTypography.titleMedium(context)),
                    const SizedBox(height: AppSpacing.sm),
                    ...reviews.map((rev) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < rev.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(rev.reviewerName,
                                        style: AppTypography.caption(context)),
                                  ],
                                ),
                                if (rev.comment.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(rev.comment,
                                      style: AppTypography.bodyMedium(context)),
                                ],
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),
            Text('Leave feedback', style: AppTypography.titleMedium(context)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What did they do well? What should they check next time?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
