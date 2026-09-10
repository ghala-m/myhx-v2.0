import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/case_referral.dart';
import '../services/case_referral_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_card.dart';

/// Incoming referrals to accept/decline, and outgoing ones this account
/// sent, with live status. Accepting doesn't copy anything itself — it
/// just flips a status field; the actual patient-data copy happens
/// server-side (functions/index.js: onCaseReferralAccepted).
class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  final _service = CaseReferralService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _respond(CaseReferral r, bool accept) async {
    try {
      await _service.respond(r.id, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(accept
              ? 'Accepted — the patient will appear in your list shortly'
              : 'Declined'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : TabBarView(
              controller: _tabController,
              children: [
                _list(_service.receivedBy(user.uid), incoming: true),
                _list(_service.sentBy(user.uid), incoming: false),
              ],
            ),
    );
  }

  Widget _list(Stream<List<CaseReferral>> stream, {required bool incoming}) {
    return StreamBuilder<List<CaseReferral>>(
      stream: stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('Nothing here yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            final statusColor = switch (r.status) {
              'accepted' => Colors.green,
              'declined' => Theme.of(context).colorScheme.error,
              _ => Colors.orange,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incoming
                                ? 'From ${r.fromDoctorName}'
                                : r.patientNamePreview,
                            style: AppTypography.titleMedium(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.status,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Text(r.department, style: AppTypography.caption(context)),
                    if (incoming && r.status == 'pending') ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _respond(r, false),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _respond(r, true),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
