// lib/screens/scorecard/scorecard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import '../../models/innings_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/player_quick_view_sheet.dart';
import '../../widgets/match_delete_helper.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<MatchProvider>();
      final matchArg = ModalRoute.of(context)?.settings.arguments as MatchModel?;
      if (matchArg != null) {
        prov.selectMatch(matchArg);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: _buildAppBar(),
      body: Consumer<MatchProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final inn1 = prov.firstInnings ?? prov.currentInnings;
          final inn2 = prov.secondInnings;

          if (inn1 == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No Scorecard Data', style: AppTextStyles.headline3),
                    const SizedBox(height: 8),
                    Text('Select or start a match to view its full scorecard.',
                        style: AppTextStyles.body2, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _MatchSummaryHeader(
                      inn1: inn1,
                      inn2: inn2,
                    ),
                  ),
                  TabBar(
                    controller: _tab,
                    tabs: [
                      Tab(text: '${inn1.battingTeamName} (1st Inn)'),
                      Tab(text: inn2 != null ? '${inn2.battingTeamName} (2nd Inn)' : '2nd Innings'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _InningsScorecard(innings: inn1),
                        inn2 != null
                            ? _InningsScorecard(innings: inn2)
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: () => prov.refreshMatches(silent: false),
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          '2nd innings has not started yet.\nTarget will be ${inn1.totalRuns + 1} runs.',
                                          style: AppTextStyles.body2,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Full Scorecard'),
      actions: [
        Consumer<MatchProvider>(
          builder: (context, prov, _) {
            final match = prov.selectedMatch;
            if (!prov.canDeleteMatch(match)) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Delete match',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () async {
                final deleted = await confirmAndDeleteMatch(context, match!);
                if (deleted && context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class _MatchSummaryHeader extends StatelessWidget {
  final InningsModel inn1;
  final InningsModel? inn2;

  const _MatchSummaryHeader({required this.inn1, this.inn2});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>().selectedMatch;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inn1.battingTeamName, style: AppTextStyles.bodyBold),
                    AppSpacing.vGap(2),
                    Text(inn1.scoreDisplay, style: AppTextStyles.scoreMedium.copyWith(fontSize: 22)),
                    Text('${inn1.oversDisplay} Ov', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('vs', style: AppTextStyles.body2),
                  AppSpacing.vGap(AppSpacing.xs),
                  NeoCard(
                    style: NeoStyle.inset,
                    borderRadius: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(match?.format ?? 'T20',
                        style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(inn1.bowlingTeamName, style: AppTextStyles.bodyBold),
                    AppSpacing.vGap(2),
                    if (inn2 != null) ...[
                      Text(inn2!.scoreDisplay, style: AppTextStyles.scoreMedium.copyWith(fontSize: 22)),
                      Text('${inn2!.oversDisplay} Ov', style: AppTextStyles.caption),
                    ] else ...[
                      Text(
                        'Target: ${inn1.totalRuns + 1}',
                        style: AppTextStyles.body2.copyWith(fontStyle: FontStyle.italic, color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (match?.result != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: AppRadius.rSM,
              ),
              child: Text(
                match!.result!.description ?? 'Match Completed',
                style: AppTextStyles.body2.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InningsScorecard extends StatelessWidget {
  final InningsModel innings;
  const _InningsScorecard({required this.innings});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<MatchProvider>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshMatches(silent: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        children: [
        // Batting table
        const SectionHeader(title: 'Batting'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _TableHeader(columns: ['Batter', 'R', 'B', '4s', '6s', 'SR']),
              ...innings.battersUsed.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                return _BattingRow(
                  batter: b,
                  isAlternate: i.isOdd,
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text('Extras', style: AppTextStyles.body2),
                    const Spacer(),
                    Text(
                      '${innings.extras.total} '
                      '(w ${innings.extras.wides}, nb ${innings.extras.noBalls}, '
                      'b ${innings.extras.byes}, lb ${innings.extras.legByes})',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.borderLight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text('Total', style: AppTextStyles.bodyBold),
                    const Spacer(),
                    Text('${innings.scoreDisplay}  (${innings.oversDisplay} Ov)',
                        style: AppTextStyles.bodyBold),
                  ],
                ),
              ),
            ],
          ),
        ),

        AppSpacing.vGap(AppSpacing.xl),

        // Bowling table
        const SectionHeader(title: 'Bowling'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _TableHeader(columns: ['Bowler', 'O', 'M', 'R', 'W', 'Eco']),
              ...innings.bowlersUsed.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                return _BowlingRow(bowler: b, isAlternate: i.isOdd);
              }),
            ],
          ),
        ),

        AppSpacing.vGap(AppSpacing.xl),

        // Fall of Wickets
        if (innings.fallOfWickets.isNotEmpty) ...[
          const SectionHeader(title: 'Fall of Wickets'),
          AppCard(
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: innings.fallOfWickets.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppRadius.rMD,
                ),
                child: Text(
                  '${f.wicketNumber}-${f.score} (${f.playerName}, ${f.overDisplay})',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              )).toList(),
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),
        ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;
  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neoPressed,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: columns.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return isFirst
              ? Expanded(child: Text(e.value, style: AppTextStyles.tableHeader))
              : SizedBox(
                  width: 36,
                  child: Text(e.value, style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                );
        }).toList(),
      ),
    );
  }
}

class _BattingRow extends StatelessWidget {
  final BatterState batter;
  final bool isAlternate;
  const _BattingRow({required this.batter, required this.isAlternate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPlayerQuickView(context, batter.playerName),
      child: Container(
        color: isAlternate ? AppColors.surfaceVariant.withValues(alpha: 0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(batter.playerName,
                            style: AppTextStyles.tableCell.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.bar_chart_rounded, size: 12, color: AppColors.textHint),
                    ],
                  ),
                  Text(
                    batter.isOut
                        ? (batter.dismissalType ?? 'out')
                        : 'not out',
                    style: AppTextStyles.caption,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _Cell(text: batter.runs.toString(), bold: true),
            _Cell(text: batter.balls.toString()),
            _Cell(text: batter.fours.toString()),
            _Cell(text: batter.sixes.toString()),
            _Cell(
              text: batter.strikeRate.toStringAsFixed(1),
              color: batter.strikeRate > 150 ? AppColors.success : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BowlingRow extends StatelessWidget {
  final BowlerState bowler;
  final bool isAlternate;
  const _BowlingRow({required this.bowler, required this.isAlternate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPlayerQuickView(context, bowler.playerName),
      child: Container(
        color: isAlternate ? AppColors.surfaceVariant.withValues(alpha: 0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(bowler.playerName,
                        style: AppTextStyles.tableCell.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bar_chart_rounded, size: 12, color: AppColors.textHint),
                ],
              ),
            ),
            _Cell(text: bowler.oversDisplay),
            _Cell(text: bowler.maidens.toString()),
            _Cell(text: bowler.runs.toString()),
            _Cell(text: bowler.wickets.toString(), bold: true,
                color: bowler.wickets >= 3 ? AppColors.success : null),
            _Cell(
              text: bowler.economy.toStringAsFixed(1),
              color: bowler.economy < 7 ? AppColors.success
                  : bowler.economy > 10 ? AppColors.error : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  const _Cell({required this.text, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        style: (bold ? AppTextStyles.tableCellBold : AppTextStyles.tableCell)
            .copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}
