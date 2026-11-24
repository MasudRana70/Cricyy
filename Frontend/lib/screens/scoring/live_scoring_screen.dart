// lib/screens/scoring/live_scoring_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../core/app_constants.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import '../../models/innings_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/player_quick_view_sheet.dart';
import '../../widgets/match_delete_helper.dart';

class LiveScoringScreen extends StatefulWidget {
  const LiveScoringScreen({super.key});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<MatchProvider>();
      final matchArg = ModalRoute.of(context)?.settings.arguments as MatchModel?;
      if (matchArg != null) {
        prov.selectMatch(matchArg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      body: Consumer<MatchProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.currentInnings == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_cricket, size: 56, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No Live Match Active', style: AppTextStyles.headline3),
                    const SizedBox(height: 8),
                    Text(
                      'Please start a new match or select an ongoing match from the dashboard.',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.routeCreateMatch),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Match'),
                    ),
                  ],
                ),
              ),
            );
          }
          final innings = prov.currentInnings!;
          return Column(
            children: [
              _ScoreHeader(innings: innings),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => prov.refreshMatches(silent: false),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          children: [
                            _CurrentPlayersCard(innings: innings),
                            AppSpacing.vGap(AppSpacing.md),
                            _ScoringPanel(innings: innings),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Score Header ──────────────────────────────────────────────────────────────
class _ScoreHeader extends StatelessWidget {
  final InningsModel innings;
  const _ScoreHeader({required this.innings});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>().selectedMatch;
    final totalOvers = match?.totalOvers ?? 20;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neoShadowDark,
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 16,
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 19),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${innings.battingTeamName} vs ${innings.bowlingTeamName} • Inn ${innings.inningsNumber}',
                      style: AppTextStyles.label.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (context.watch<MatchProvider>().canDeleteMatch(match))
                    GestureDetector(
                      onTap: () async {
                        final deleted = await confirmAndDeleteMatch(context, match!);
                        if (deleted && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                      ),
                    )
                  else
                    const SizedBox(width: 28),
                ],
              ),
          const SizedBox(height: 14),

          // Main score & Overs
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(innings.battingTeamName,
                        style: AppTextStyles.body2.copyWith(color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(
                      innings.scoreDisplay,
                      style: AppTextStyles.scoreLarge.copyWith(color: Colors.white, fontSize: 48),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ov ${innings.oversDisplay} / $totalOvers',
                    style: AppTextStyles.scoreSmall.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  _buildRunRateRow(innings, totalOvers),
                ],
              ),
            ],
          ),

          // Target banner for 2nd innings
          if (innings.target != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: AppRadius.rSM,
              ),
              child: Text(
                'Target: ${innings.target} runs • Need ${innings.target! - innings.totalRuns} runs to win',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Over progress dots bar
          const SizedBox(height: 10),
          _OverProgressBar(currentBall: innings.currentBallInOver),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunRateRow(InningsModel innings, int totalOvers) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RateChip(label: 'CRR', value: innings.currentRunRate.toStringAsFixed(2)),
        if (innings.target != null) ...[
          const SizedBox(width: 6),
          _RateChip(
            label: 'RRR',
            value: _calculateRRR(innings, totalOvers),
          ),
        ],
      ],
    );
  }

  String _calculateRRR(InningsModel innings, int totalOvers) {
    if (innings.target == null) return '0.00';
    final remainingRuns = innings.target! - innings.totalRuns;
    final totalBalls = totalOvers * 6;
    final remainingBalls = totalBalls - innings.totalLegalBalls;
    if (remainingBalls <= 0) return remainingRuns <= 0 ? '0.00' : '∞';
    final rrr = (remainingRuns / (remainingBalls / 6));
    return rrr.toStringAsFixed(2);
  }
}

class _RateChip extends StatelessWidget {
  final String label;
  final String value;
  const _RateChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.rFull,
      ),
      child: Text('$label $value',
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
    );
  }
}

class _OverProgressBar extends StatelessWidget {
  final int currentBall; // 0-5
  const _OverProgressBar({required this.currentBall});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        final filled = i < currentBall;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: filled ? Colors.white : Colors.white.withValues(alpha: 0.3),
              borderRadius: AppRadius.rFull,
            ),
          ),
        );
      }),
    );
  }
}

// ── Current Players Card (Batters & Bowler) ──────────────────────────────────
class _CurrentPlayersCard extends StatelessWidget {
  final InningsModel innings;
  const _CurrentPlayersCard({required this.innings});

  @override
  Widget build(BuildContext context) {
    final striker    = innings.striker;
    final nonStriker = innings.nonStriker;
    final bowler     = innings.currentBowler;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header with Side Change / Swap Strike Button
          Row(
            children: [
              Text(
                'BATTERS',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              // Prominent Side Change / Swap Strike Button as requested
              InkWell(
                onTap: () {
                  context.read<MatchProvider>().swapStrike();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Strike swapped! (Side change applied)'),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.rFull,
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Side Change / Swap Strike',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Two Batters
          Row(
            children: [
              if (striker != null)
                Expanded(child: _BatterInfo(batter: striker, isStriker: true)),
              Container(
                width: 1,
                height: 50,
                color: AppColors.borderLight,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              if (nonStriker != null)
                Expanded(child: _BatterInfo(batter: nonStriker, isStriker: false)),
            ],
          ),
          Divider(height: 20, color: AppColors.borderLight),

          // Bowler with Change Bowler Action
          Row(
            children: [
              if (bowler != null)
                Expanded(child: _BowlerInfo(bowler: bowler)),
              TextButton.icon(
                onPressed: () => _showChangeBowlerDialog(context),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Change Bowler'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangeBowlerDialog(BuildContext context) {
    final prov = context.read<MatchProvider>();
    final ctrl = TextEditingController();
    final usedBowlers = prov.currentInnings?.bowlersUsed ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Bowler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'New Bowler Name',
                hintText: 'e.g. Mustafiz',
              ),
            ),
            if (usedBowlers.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Or pick previous bowler:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: usedBowlers.map((b) => ActionChip(
                  label: Text('${b.playerName} (${b.oversDisplay} ov)'),
                  onPressed: () {
                    prov.setNextBowler(b.playerName);
                    Navigator.pop(ctx);
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                prov.setNextBowler(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _BatterInfo extends StatelessWidget {
  final BatterState batter;
  final bool isStriker;
  const _BatterInfo({required this.batter, required this.isStriker});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPlayerQuickView(context, batter.playerName),
      borderRadius: AppRadius.rSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          children: [
            PlayerAvatar(name: batter.playerName, size: 36),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          batter.playerName,
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.primary),
                      if (isStriker) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.rFull,
                          ),
                          child: Text(
                            'STRIKE',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${batter.runs} (${batter.balls}) • ${batter.fours}×4 • ${batter.sixes}×6',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BowlerInfo extends StatelessWidget {
  final BowlerState bowler;
  const _BowlerInfo({required this.bowler});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPlayerQuickView(context, bowler.playerName),
      borderRadius: AppRadius.rSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          children: [
            const Icon(Icons.sports, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bowler.playerName,
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'O: ${bowler.oversDisplay} • M: ${bowler.maidens} • R: ${bowler.runs} • W: ${bowler.wickets} (Eco ${bowler.economy.toStringAsFixed(1)})',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scoring Panel ─────────────────────────────────────────────────────────────
class _ScoringPanel extends StatefulWidget {
  final InningsModel innings;
  const _ScoringPanel({required this.innings});

  @override
  State<_ScoringPanel> createState() => _ScoringPanelState();
}

class _ScoringPanelState extends State<_ScoringPanel> {
  String? _selectedExtra; // null, 'wide', 'no_ball', 'bye', 'leg_bye'

  static const _extraOptions = [
    {'label': 'Wide',    'value': 'wide'},
    {'label': 'No Ball', 'value': 'no_ball'},
    {'label': 'Bye',     'value': 'bye'},
    {'label': 'Leg Bye', 'value': 'leg_bye'},
  ];

  static const _dismissalTypes = [
    'Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped',
    'Hit Wicket', 'Obstructing', 'Timed Out', 'Retired Out',
  ];

  void _handleBall({required int runs}) {
    final prov = context.read<MatchProvider>();
    final extra = _selectedExtra ?? 'none';

    final result = prov.recordBall(
      runs: runs,
      extraType: extra,
    );

    setState(() {
      _selectedExtra = null;
    });

    _processBallResult(result);
  }

  void _processBallResult(BallResult result) {
    if (!mounted) return;

    if (result.matchCompleted) {
      _showMatchCompletedDialog(result.message ?? 'Match Completed!');
    } else if (result.inningsCompleted) {
      _showInningsCompletedDialog(result.message ?? 'Innings Completed!');
    } else if (result.overCompleted) {
      _showOverCompletedDialog();
    }
  }

  void _showOverCompletedDialog() {
    final prov = context.read<MatchProvider>();
    final ctrl = TextEditingController();
    final usedBowlers = prov.currentInnings?.bowlersUsed ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Over Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overs bowled: ${prov.currentInnings?.completedOvers}. Strike rotated for the new over.\n\nWho will bowl the next over?',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Next Bowler Name',
                hintText: 'e.g. Bowler 2',
              ),
            ),
            if (usedBowlers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Or select previous bowler:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: usedBowlers.map((b) => ActionChip(
                  label: Text(b.playerName),
                  onPressed: () {
                    prov.setNextBowler(b.playerName);
                    Navigator.pop(ctx);
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                prov.setNextBowler(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Continue Over'),
          ),
        ],
      ),
    );
  }

  void _showInningsCompletedDialog(String message) {
    final prov = context.read<MatchProvider>();
    final sCtrl = TextEditingController(text: 'Batter 1');
    final nsCtrl = TextEditingController(text: 'Batter 2');
    final bCtrl = TextEditingController(text: 'Bowler 1');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('1st Innings Complete! 🏁'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: AppTextStyles.bodyBold),
              const Divider(height: 24),
              const Text('Enter 2nd Innings Opening Players:'),
              const SizedBox(height: 10),
              TextField(
                controller: sCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Chasing Striker Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nsCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Chasing Non-Striker Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Opening Bowler Name'),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              prov.startSecondInnings(
                strikerName: sCtrl.text.trim(),
                nonStrikerName: nsCtrl.text.trim(),
                openingBowlerName: bCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Start 2nd Innings'),
          ),
        ],
      ),
    );
  }

  void _showMatchCompletedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🏆 Match Ended!'),
        content: Text(message, style: AppTextStyles.headline3.copyWith(color: AppColors.primary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // back to home
            },
            child: const Text('Home Dashboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppConstants.routeScorecard);
            },
            child: const Text('View Full Scorecard'),
          ),
        ],
      ),
    );
  }

  void _showWicketModal(BuildContext context) {
    final prov = context.read<MatchProvider>();
    final striker = prov.currentInnings?.striker?.playerName ?? 'Striker';
    final nonStriker = prov.currentInnings?.nonStriker?.playerName ?? 'Non-Striker';

    String selectedDismissal = 'Bowled';
    bool outIsStriker = true;
    final nextBatterCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.rFull),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.flag, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Wicket Details', style: AppTextStyles.headline3),
                ],
              ),
              const SizedBox(height: 14),

              // Who got out selector
              const Text('Who is out?'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(striker),
                      selected: outIsStriker,
                      onSelected: (v) => setModalState(() => outIsStriker = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(nonStriker),
                      selected: !outIsStriker,
                      onSelected: (v) => setModalState(() => outIsStriker = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dismissal type
              const Text('Dismissal Type:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _dismissalTypes.map((d) {
                  final sel = selectedDismissal == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: sel,
                    onSelected: (v) => setModalState(() => selectedDismissal = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Next Batter Name
              TextField(
                controller: nextBatterCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Next Batter Name',
                  hintText: 'e.g. Batter 3',
                  prefixIcon: Icon(Icons.person_add_alt),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final result = prov.recordBall(
                      runs: 0,
                      extraType: 'none',
                      isWicket: true,
                      dismissalType: selectedDismissal.toLowerCase().replaceAll(' ', '_'),
                      outIsStriker: outIsStriker,
                      newBatterName: nextBatterCtrl.text.trim(),
                    );
                    _processBallResult(result);
                  },
                  child: const Text('Confirm Wicket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MatchProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-time this over ball-by-ball history
        _LastBallsRow(balls: widget.innings.thisOverBalls),
        AppSpacing.vGap(AppSpacing.md),

        // Runs buttons (0, 1, 2, 3, 4, 6)
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Runs', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
                  const Spacer(),
                  if (_selectedExtra != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: AppRadius.rFull,
                      ),
                      child: Text(
                        'Extra: ${_selectedExtra!.toUpperCase()} + Tap Runs',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RunButton(value: '0', color: AppColors.dot,     bgColor: AppColors.neoPressed, onTap: () => _handleBall(runs: 0)),
                  const SizedBox(width: 8),
                  _RunButton(value: '1', color: AppColors.run,     bgColor: AppColors.successLight, onTap: () => _handleBall(runs: 1)),
                  const SizedBox(width: 8),
                  _RunButton(value: '2', color: AppColors.run,     bgColor: AppColors.successLight, onTap: () => _handleBall(runs: 2)),
                  const SizedBox(width: 8),
                  _RunButton(value: '3', color: AppColors.run,     bgColor: AppColors.successLight, onTap: () => _handleBall(runs: 3)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RunButton(value: '4', color: AppColors.boundary, bgColor: AppColors.primaryLight, flex: 2, onTap: () => _handleBall(runs: 4)),
                  const SizedBox(width: 8),
                  _RunButton(value: '6', color: AppColors.six,      bgColor: const Color(0xFFF3E8FF), flex: 2, onTap: () => _handleBall(runs: 6)),
                ],
              ),
            ],
          ),
        ),

        AppSpacing.vGap(AppSpacing.md),

        // Extras Chips + Wicket Action
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extras (Tap then tap runs)', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _extraOptions.map((opt) {
                        final val = opt['value']!;
                        final sel = _selectedExtra == val;
                        return NeoPillButton(
                          label: opt['label']!,
                          selected: sel,
                          selectedColor: AppColors.warning,
                          onTap: () {
                            setState(() {
                              _selectedExtra = sel ? null : val;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Wicket button — neomorphic red
            GestureDetector(
              onTap: () => _showWicketModal(context),
              child: Container(
                width: 80,
                height: 94,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.wicket, Color(0xFF8B0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.rLG,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.wicket.withValues(alpha: 0.42),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, size: 24, color: Colors.white),
                    const SizedBox(height: 2),
                    Text('W', style: AppTextStyles.scoringButton.copyWith(color: Colors.white, fontSize: 26)),
                    Text('Wicket', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),

        AppSpacing.vGap(AppSpacing.md),

        // Bottom Action Bar: Undo & View Scorecard
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: prov.canUndo
                    ? () {
                        prov.undoBall();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Previous ball undone'),
                            duration: Duration(milliseconds: 700),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Undo Ball'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppConstants.routeScorecard),
                icon: const Icon(Icons.table_rows_outlined, size: 18),
                label: Text('Full Scorecard', style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RunButton extends StatefulWidget {
  final String value;
  final Color color;
  final Color bgColor;
  final int flex;
  final VoidCallback onTap;

  const _RunButton({
    required this.value,
    required this.color,
    required this.bgColor,
    this.flex = 1,
    required this.onTap,
  });

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  Color.lerp(widget.color, Colors.black, 0.18)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.38),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.value,
                style: AppTextStyles.scoringButton.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastBallsRow extends StatelessWidget {
  final List<String> balls;
  const _LastBallsRow({required this.balls});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text('This over:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          if (balls.isEmpty)
            Text('First ball of the over...', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic))
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: balls.map((b) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ScoreBadge.forValue(b, size: 30),
                  )).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
