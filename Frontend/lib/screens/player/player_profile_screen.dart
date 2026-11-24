// lib/screens/player/player_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../providers/player_provider.dart';
import '../../models/player_model.dart';
import '../../services/player_stats_aggregator.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/player_performance_chart.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayerProfile(widget.playerId);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profile = prov.selectedProfile;
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Player Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 56, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('Player Not Found', style: AppTextStyles.headline3),
                    const SizedBox(height: 8),
                    Text(
                      'No match records found for this player.',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final player = profile.player;
        final batting = profile.battingStats;
        final bowling = profile.bowlingStats;
        final performances = profile.matchPerformances;

        return Scaffold(
          backgroundColor: AppColors.neoBackground,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  _ProfileSliverAppBar(
                    player: player,
                    batting: batting,
                    bowling: bowling,
                  ),
                  SliverPersistentHeader(
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tab,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Batting'),
                          Tab(text: 'Bowling'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ],
                body: TabBarView(
                  controller: _tab,
                  children: [
                    _OverviewTab(
                      batting: batting,
                      bowling: bowling,
                      performances: performances,
                    ),
                    _BattingTab(
                      stats: batting,
                      performances: performances,
                    ),
                    _BowlingTab(
                      stats: bowling,
                      performances: performances,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final PlayerModel player;
  final BattingStats batting;
  final BowlingStats bowling;

  const _ProfileSliverAppBar({
    required this.player,
    required this.batting,
    required this.bowling,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAllRounder = batting.totalRuns > 0 && bowling.totalWickets > 0;
    final bool isBowler = bowling.overs > 0 || bowling.totalWickets > 0;
    final String role = isAllRounder ? 'All-Rounder' : (isBowler ? 'Bowler' : 'Batter');

    final roleBg = isAllRounder
        ? Colors.amber.shade50
        : (isBowler ? Colors.blue.shade50 : Colors.green.shade50);
    final roleColor = isAllRounder
        ? Colors.amber.shade900
        : (isBowler ? Colors.blue.shade800 : Colors.green.shade800);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.neoBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.neoBackground,
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
          child: Row(
            children: [
              PlayerAvatar(name: player.name, size: 68, bgColor: AppColors.primaryDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      player.name,
                      style: AppTextStyles.headline2.copyWith(fontSize: 22),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: AppRadius.rFull,
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.rFull,
                          ),
                          child: Text(
                            '${batting.totalMatches} ${batting.totalMatches == 1 ? "Match" : "Matches"}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.neoBackground,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, color: AppColors.neoShadowDark.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final BattingStats batting;
  final BowlingStats bowling;
  final List<PlayerMatchPerformance> performances;

  const _OverviewTab({
    required this.batting,
    required this.bowling,
    required this.performances,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        // Visual Performance Graph
        if (performances.isNotEmpty) ...[
          PlayerPerformanceChart(performances: performances),
          AppSpacing.vGap(AppSpacing.xl),
        ],

        // Quick batting stats
        SectionHeader(title: 'Career Batting'),
        AppCard(
          child: Column(
            children: [
              Row(children: [
                _QuickStat('Matches', '${batting.totalMatches}'),
                _Divider(),
                _QuickStat('Runs', '${batting.totalRuns}'),
                _Divider(),
                _QuickStat('Average', batting.battingAverage?.toStringAsFixed(1) ?? '-'),
                _Divider(),
                _QuickStat('S/R', batting.strikeRate.toStringAsFixed(1)),
              ]),
              Divider(height: 20, color: AppColors.borderLight),
              Row(children: [
                _QuickStat('50s', '${batting.halfCenturies}'),
                _Divider(),
                _QuickStat('100s', '${batting.centuries}'),
                _Divider(),
                _QuickStat('4s', '${batting.totalFours}'),
                _Divider(),
                _QuickStat('6s', '${batting.totalSixes}'),
              ]),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),

        // Quick bowling stats
        SectionHeader(title: 'Career Bowling'),
        AppCard(
          child: Row(children: [
            _QuickStat('Wickets', '${bowling.totalWickets}'),
            _Divider(),
            _QuickStat('Average', bowling.bowlingAverage?.toStringAsFixed(1) ?? '-'),
            _Divider(),
            _QuickStat('Economy', bowling.economyRate.toStringAsFixed(1)),
            _Divider(),
            _QuickStat('Best', bowling.bestBowling ?? '-'),
          ]),
        ),
        AppSpacing.vGap(AppSpacing.xl),

        // Recent Match Performances
        SectionHeader(title: 'Match-by-Match History'),
        if (performances.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No match performances recorded yet.', style: AppTextStyles.body2),
          )
        else
          ...performances.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PerformanceCard(performance: p),
          )),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.scoreMedium.copyWith(fontSize: 18)),
          AppSpacing.vGap(2),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.borderLight);
  }
}

class _PerformanceCard extends StatelessWidget {
  final PlayerMatchPerformance performance;
  const _PerformanceCard({required this.performance});

  @override
  Widget build(BuildContext context) {
    final p = performance;
    final dateStr = '${p.matchDate.day}/${p.matchDate.month}/${p.matchDate.year}';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  p.format,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('vs ${p.opponentTeam}',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          Divider(height: 16, color: AppColors.borderLight),
          Row(
            children: [
              // Batting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batting', style: AppTextStyles.labelSmall),
                    AppSpacing.vGap(2),
                    if (p.didBat) ...[
                      Text(
                        '${p.battingRuns} (${p.ballsFaced}b) ${p.fours}×4 ${p.sixes}×6',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                      Text(
                        p.isNotOut ? 'Not Out' : (p.dismissalType ?? 'Out'),
                        style: AppTextStyles.caption.copyWith(
                          color: p.isNotOut ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Text('Did not bat', style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.borderLight),
              // Bowling
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bowling', style: AppTextStyles.labelSmall),
                      AppSpacing.vGap(2),
                      if (p.didBowl) ...[
                        Text(
                          '${p.wicketsTaken}/${p.runsConceded} (${p.oversBowled} ov)',
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                        ),
                        Text('Eco: ${p.economy.toStringAsFixed(2)}', style: AppTextStyles.caption),
                      ] else ...[
                        Text('Did not bowl', style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Batting Tab ───────────────────────────────────────────────────────────────
class _BattingTab extends StatelessWidget {
  final BattingStats stats;
  final List<PlayerMatchPerformance> performances;

  const _BattingTab({required this.stats, required this.performances});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final battingMatches = performances.where((p) => p.didBat).toList();

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        // Key numbers
        AppCard(
          child: Column(
            children: [
              _BigStatRow(label: 'Total Runs', value: '${s.totalRuns}', accent: true),
              Divider(height: 24, color: AppColors.borderLight),
              _GridStats(items: [
                {'label': 'Innings', 'value': '${s.battingInnings}'},
                {'label': 'Not Outs', 'value': '${s.notOuts}'},
                {'label': 'Average', 'value': s.battingAverage?.toStringAsFixed(2) ?? '-'},
                {'label': 'Strike Rate', 'value': s.strikeRate.toStringAsFixed(1)},
                {'label': 'Highest', 'value': '${s.highestScore}'},
                {'label': 'Balls Faced', 'value': '${s.totalBalls}'},
              ]),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.lg),

        // Milestones
        AppCard(
          child: Column(
            children: [
              _BigStatRow(label: 'Boundaries & Milestones', value: '${s.totalFours * 4 + s.totalSixes * 6} Runs'),
              Divider(height: 24, color: AppColors.borderLight),
              _GridStats(items: [
                {'label': '50s', 'value': '${s.halfCenturies}'},
                {'label': '100s', 'value': '${s.centuries}'},
                {'label': 'Fours (4s)', 'value': '${s.totalFours}'},
                {'label': 'Sixes (6s)', 'value': '${s.totalSixes}'},
                {'label': 'Boundary %', 'value': s.totalRuns > 0 ? '${((s.totalFours * 4 + s.totalSixes * 6) / s.totalRuns * 100).toStringAsFixed(1)}%' : '0%'},
                {'label': 'Dot Ball %', 'value': s.totalBalls > 0 ? '${(((s.totalBalls - s.totalRuns).clamp(0, s.totalBalls)) / s.totalBalls * 100).toStringAsFixed(0)}%' : '-'},
              ]),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),

        // Inning by Inning breakdown
        SectionHeader(title: 'Innings Breakdown'),
        if (battingMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Player has not batted in any recorded match yet.', style: AppTextStyles.body2),
          )
        else
          ...battingMatches.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('vs ${p.opponentTeam} (${p.format})', style: AppTextStyles.bodyBold),
                        const SizedBox(height: 2),
                        Text(
                          p.isNotOut ? 'Not Out' : (p.dismissalType ?? 'Dismissed'),
                          style: AppTextStyles.caption.copyWith(
                            color: p.isNotOut ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.battingRuns}* (${p.ballsFaced})'.replaceAll('*', p.isNotOut ? '*' : ''),
                        style: AppTextStyles.scoreSmall,
                      ),
                      Text(
                        '${p.fours}×4  ${p.sixes}×6  SR ${(p.ballsFaced > 0 ? (p.battingRuns / p.ballsFaced * 100) : 0).toStringAsFixed(0)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }
}

// ── Bowling Tab ───────────────────────────────────────────────────────────────
class _BowlingTab extends StatelessWidget {
  final BowlingStats stats;
  final List<PlayerMatchPerformance> performances;

  const _BowlingTab({required this.stats, required this.performances});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final bowlingMatches = performances.where((p) => p.didBowl).toList();

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        AppCard(
          child: Column(
            children: [
              _BigStatRow(label: 'Total Wickets', value: '${s.totalWickets}', accent: true),
              Divider(height: 24, color: AppColors.borderLight),
              _GridStats(items: [
                {'label': 'Innings', 'value': '${s.bowlingInnings}'},
                {'label': 'Overs', 'value': '${s.overs}'},
                {'label': 'Runs', 'value': '${s.totalRunsConceded}'},
                {'label': 'Maidens', 'value': '${s.maidens}'},
                {'label': 'Average', 'value': s.bowlingAverage?.toStringAsFixed(2) ?? '-'},
                {'label': 'Economy', 'value': s.economyRate.toStringAsFixed(2)},
              ]),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.lg),

        AppCard(
          child: Column(
            children: [
              _BigStatRow(label: 'Best Bowling', value: s.bestBowling ?? '-'),
              Divider(height: 24, color: AppColors.borderLight),
              _GridStats(items: [
                {'label': 'Strike Rate', 'value': s.bowlingStrikeRate?.toStringAsFixed(1) ?? '-'},
                {'label': '3-Wkt Hauls', 'value': '${s.threeWicketHauls}'},
                {'label': '4-Wkt Hauls', 'value': '${s.fourWicketHauls}'},
                {'label': '5-Wkt Hauls', 'value': '${s.fiveWicketHauls}'},
              ]),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),

        SectionHeader(title: 'Spell Breakdown'),
        if (bowlingMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Player has not bowled in any recorded match yet.', style: AppTextStyles.body2),
          )
        else
          ...bowlingMatches.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('vs ${p.opponentTeam} (${p.format})', style: AppTextStyles.bodyBold),
                        const SizedBox(height: 2),
                        Text(
                          '${p.oversBowled} overs • ${p.maidens} maidens',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.wicketsTaken} / ${p.runsConceded}',
                        style: AppTextStyles.scoreSmall.copyWith(color: AppColors.primary),
                      ),
                      Text(
                        'Eco: ${p.economy.toStringAsFixed(2)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }
}

class _BigStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _BigStatRow({required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.body2),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.scoreMedium.copyWith(
            color: accent ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GridStats extends StatelessWidget {
  final List<Map<String, String>> items;
  const _GridStats({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      children: items.map((item) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item['value']!, style: AppTextStyles.scoreSmall),
          AppSpacing.vGap(2),
          Text(item['label']!, style: AppTextStyles.labelSmall),
        ],
      )).toList(),
    );
  }
}
