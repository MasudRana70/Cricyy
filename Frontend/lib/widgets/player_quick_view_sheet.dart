// lib/widgets/player_quick_view_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/app_constants.dart';
import '../providers/player_provider.dart';
import '../providers/match_provider.dart';
import '../services/player_stats_aggregator.dart';
import 'player_performance_chart.dart';

void showPlayerQuickView(BuildContext context, String playerName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlayerQuickViewSheet(playerName: playerName),
  );
}

class _PlayerQuickViewSheet extends StatelessWidget {
  final String playerName;

  const _PlayerQuickViewSheet({required this.playerName});

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<PlayerProvider>();
    final matchProv = context.watch<MatchProvider>();

    final cleanName = playerName.trim().toLowerCase();
    final profile = playerProv.profiles.where(
      (p) => p.player.name.trim().toLowerCase() == cleanName,
    ).firstOrNull;

    // Check if player has active match stats
    final currentInn = matchProv.currentInnings;
    final liveBatter = currentInn?.battersUsed.where(
      (b) => b.playerName.trim().toLowerCase() == cleanName,
    ).firstOrNull;
    final liveBowler = currentInn?.bowlersUsed.where(
      (b) => b.playerName.trim().toLowerCase() == cleanName,
    ).firstOrNull;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Player Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      playerName.trim().isNotEmpty ? playerName.trim()[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerName,
                        style: AppTextStyles.headline2.copyWith(fontSize: 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (profile != null) ...[
                            _buildRoleChip(profile),
                            const SizedBox(width: 8),
                            Text(
                              '${profile.battingStats.totalMatches} matches',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active Match',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textHint),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Live Match Snapshot (if currently playing)
            if (liveBatter != null || liveBowler != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Match Performance', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (liveBatter != null)
                          Expanded(
                            child: Text(
                              '🏏 ${liveBatter.runs}* (${liveBatter.balls}b) • ${liveBatter.fours}×4 • ${liveBatter.sixes}×6',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                            ),
                          ),
                        if (liveBowler != null)
                          Expanded(
                            child: Text(
                              '🎯 ${liveBowler.wickets}/${liveBowler.runs} (${liveBowler.oversDisplay} ov)',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Career Highlights
            if (profile != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏏 Career Batting', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                          const SizedBox(height: 4),
                          Text('${profile.battingStats.totalRuns} Runs', style: AppTextStyles.scoreSmall.copyWith(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text('Avg: ${profile.battingStats.battingAverage?.toStringAsFixed(1) ?? "-"} • SR: ${profile.battingStats.strikeRate.toStringAsFixed(0)}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎯 Career Bowling', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                          const SizedBox(height: 4),
                          Text('${profile.bowlingStats.totalWickets} Wkts', style: AppTextStyles.scoreSmall.copyWith(fontSize: 18, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text('Eco: ${profile.bowlingStats.economyRate.toStringAsFixed(1)} • ${profile.bowlingStats.overs} ov', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Interactive Performance Graph
              PlayerPerformanceChart(performances: profile.matchPerformances),
              const SizedBox(height: 16),

              // Full Profile Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    playerProv.loadPlayerProfile(profile.player.id);
                    Navigator.pushNamed(
                      context,
                      AppConstants.routePlayerProfile,
                      arguments: profile.player.id,
                    );
                  },
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  label: const Text('View Full Player Profile & Breakdown'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              // First match without previous saved matches
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  'This player is playing their inaugural match! Once the match completes or continues, their full career graph and trends will appear here.',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(PlayerAggregatedProfile profile) {
    final bat = profile.battingStats;
    final bowl = profile.bowlingStats;

    final String role;
    final Color roleBg;
    final Color roleColor;
    if (bat.totalRuns > 0 && bowl.totalWickets > 0) {
      role = 'All-Rounder';
      roleBg = Colors.amber.shade50;
      roleColor = Colors.amber.shade900;
    } else if (bowl.overs > 0 || bowl.totalWickets > 0) {
      role = 'Bowler';
      roleBg = Colors.blue.shade50;
      roleColor = Colors.blue.shade800;
    } else {
      role = 'Batter';
      roleBg = Colors.green.shade50;
      roleColor = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: roleBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: roleColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
