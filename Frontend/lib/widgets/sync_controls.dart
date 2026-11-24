// lib/widgets/sync_controls.dart
//
// Shared cloud-sync indicator, auto-refresh toggle, manual refresh button,
// and server configuration modal for multi-user live updates.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../core/app_text_styles.dart';
import '../providers/match_provider.dart';
import 'neo_card.dart';

class SyncActionControls extends StatelessWidget {
  final bool compact;
  final Color? iconColor;
  final bool darkSurface;

  const SyncActionControls({
    super.key,
    this.compact = false,
    this.iconColor,
    this.darkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        final connected = prov.isCloudConnected;
        final autoOn = prov.autoRefreshEnabled;
        final refreshing = prov.isRefreshing;

        final statusColor = connected
            ? (autoOn ? AppColors.success : AppColors.primary)
            : AppColors.warning;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auto-refresh & Sync Status Pill
            Tooltip(
              message: autoOn
                  ? 'Auto-refresh ON (every 5s) • Tap for sync settings'
                  : 'Auto-refresh OFF • Tap for sync settings',
              child: GestureDetector(
                onTap: () => showSyncSettingsDialog(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: darkSurface
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.neoBackground,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: darkSurface
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                    boxShadow: darkSurface
                        ? null
                        : NeoCard.raisedShadows(blur: 7, offset: 3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        autoOn ? 'AUTO 5s' : 'MANUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: darkSurface ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Manual Refresh Button
            if (darkSurface)
              IconButton(
                tooltip: 'Refresh matches now',
                onPressed: refreshing ? null : () => prov.refreshMatches(silent: false),
                icon: refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, color: iconColor ?? Colors.white, size: 22),
              )
            else
              Tooltip(
                message: 'Refresh matches now',
                child: GestureDetector(
                  onTap: refreshing ? null : () => prov.refreshMatches(silent: false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.neoBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                      boxShadow: NeoCard.raisedShadows(blur: 8, offset: 3),
                    ),
                    child: Center(
                      child: refreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void showSyncSettingsDialog(BuildContext context) {
  final prov = context.read<MatchProvider>();
  final urlCtrl = TextEditingController(
    text: AppConstants.customOverrideUrl ?? '',
  );

  showDialog(
    context: context,
    builder: (ctx) => Consumer<MatchProvider>(
      builder: (ctx, p, _) {
        final lastSyncText = p.lastSyncedAt != null
            ? '${p.lastSyncedAt!.hour.toString().padLeft(2, '0')}:'
                '${p.lastSyncedAt!.minute.toString().padLeft(2, '0')}:'
                '${p.lastSyncedAt!.second.toString().padLeft(2, '0')}'
            : 'Not synced yet';

        return AlertDialog(
          backgroundColor: AppColors.neoBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                p.isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: p.isCloudConnected ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Live Multi-User Sync')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neoPressed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.isCloudConnected
                            ? 'Connected to shared server'
                            : 'Offline / Local mode (auto-retrying)',
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 13,
                          color: p.isCloudConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last sync: $lastSyncText',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Endpoint: ${AppConstants.baseUrl}',
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Auto-Refresh (Every 5s)', style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                  subtitle: Text(
                    'Automatically pulls live match scores & stats created by other users.',
                    style: AppTextStyles.caption,
                  ),
                  value: p.autoRefreshEnabled,
                  onChanged: (v) => p.toggleAutoRefresh(v),
                ),
                const Divider(height: 20),
                Text(
                  'Vercel Backend URL (Optional Override)',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    hintText: 'https://your-cricyy-api.vercel.app',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Leave empty to use default build/local server URL.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await p.refreshMatches(silent: false);
              },
              child: const Text('Refresh Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await p.setCustomServerUrl(urlCtrl.text);
              },
              child: const Text('Save & Sync'),
            ),
          ],
        );
      },
    ),
  );
}
