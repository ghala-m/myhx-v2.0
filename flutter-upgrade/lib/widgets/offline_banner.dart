import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/offline_service.dart';
import '../utils/app_spacing.dart';

/// High-contrast status strip: offline state, pending writes and sync progress.
///
/// Uses solid, saturated backgrounds (not pale containers) so it stays legible
/// on both light and dark themes.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final theme = Theme.of(context);

    final bool syncing = offline.syncState == SyncState.syncing;
    if (offline.isOnline && !offline.hasPending && !syncing) {
      return const SizedBox.shrink();
    }

    late final Color bg;
    late final IconData icon;
    late final String message;
    const Color fg = Color(0xFFFFFFFF);

    if (offline.isOffline) {
      bg = const Color(0xFFB3261E); // solid red — unmistakable
      icon = Icons.wifi_off_rounded;
      message = offline.hasPending
          ? '${context.tr('offlineBanner')} · ${offline.pendingCount} ${context.tr('pendingChanges')}'
          : context.tr('offlineBanner');
    } else if (syncing) {
      bg = const Color(0xFF0F766E); // deep teal
      icon = Icons.sync_rounded;
      message = '${context.tr('syncing')} (${offline.pendingCount})';
    } else {
      bg = const Color(0xFF92400E); // amber-900
      icon = Icons.schedule_rounded;
      message = '${offline.pendingCount} ${context.tr('pendingChanges')}';
    }

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              if (syncing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              else
                Icon(icon, size: 20, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              if (!syncing)
                TextButton(
                  onPressed: () {
                    if (offline.isOffline) {
                      offline.refreshConnectivity();
                    } else {
                      offline.sync();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    backgroundColor: const Color(0x33FFFFFF),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    offline.isOffline
                        ? context.tr('retry')
                        : context.tr('syncNow'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
