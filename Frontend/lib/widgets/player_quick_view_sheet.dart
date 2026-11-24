// lib/widgets/player_quick_view_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/app_constants.dart';
import '../providers/player_provider.dart';
import '../providers/match_provider.dart';
import '../services/player_stats_aggregator.dart';
import 'neo_card.dart';
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

    final currentInn = matchProv.currentInnings;
    final liveBatter = currentInn?.battersUsed.where(
      (b) => b.playerName.trim().toLowerCase() == cleanName,
    ).firstOrNull;
    final liveBowler = currentInn?.bowlersUsed.where(
      (b) => b.playerName.trim().toLowerCase() == cleanName,
    ).firstOrNull;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.neoBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neoShadowDark,
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: NeoCard.raisedShadows(blur: 10, offset: 4),
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
                                  '${profile.battingStats.totalMatches} ${profile.battingStats.totalMatches == 1 ? "match" : "matches"}',
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
                    NeoIconButton(
                      icon: Icons.close_rounded,
                      size: 38,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Live Match Snapshot
                if (liveBatter != null || liveBowler != null) ...[
                  NeoCard(
                    style: NeoStyle.inset,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  '🏏 ${liveBatter.runs}${liveBatter.isOut ? "" : "*"} (${liveBatter.balls}b) • ${liveBatter.fours}×4 • ${liveBatter.sixes}×6',
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
                        child: NeoCard(
                          style: NeoStyle.inset,
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoCard(
                          style: NeoStyle.inset,
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
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

                  // Interactive Performance Graph
                  PlayerPerformanceChart(performances: profile.matchPerformances),
                  const SizedBox(height: 16),

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
                  NeoCard(
                    style: NeoStyle.inset,
                    child: const Center(
                      child: Text(
                        'This player is playing their inaugural match! Once deliveries are recorded, their career stats and performance graph will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
