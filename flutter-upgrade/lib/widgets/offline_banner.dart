import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/offline_service.dart';
import '../utils/app_spacing.dart';

/// Thin status strip: shows offline state and pending/sync progress.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bool syncing = offline.syncState == SyncState.syncing;
    if (offline.isOnline && !offline.hasPending && !syncing) {
      return const SizedBox.shrink();
    }

    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String message;

    if (offline.isOffline) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
      icon = Icons.cloud_off_rounded;
      message = offline.hasPending
          ? 'Offline — ${offline.pendingCount} change(s) will sync later'
          : 'Offline — showing cached data';
    } else if (syncing) {
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
      icon = Icons.sync_rounded;
      message = 'Syncing ${offline.pendingCount} change(s)…';
    } else {
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
      icon = Icons.schedule_rounded;
      message = '${offline.pendingCount} change(s) pending sync';
    }

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (syncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else
              Icon(icon, size: 18, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
            if (offline.isOnline && offline.hasPending && !syncing)
              TextButton(
                onPressed: offline.sync,
                style: TextButton.styleFrom(foregroundColor: fg),
                child: const Text('Sync now'),
              ),
          ],
        ),
      ),
    );
  }
}
