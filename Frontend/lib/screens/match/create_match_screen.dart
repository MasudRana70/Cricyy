// lib/screens/match/create_match_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../core/app_constants.dart';
import '../../providers/match_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/section_header.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _team1Ctrl = TextEditingController(text: 'Team A');
  final _team2Ctrl = TextEditingController(text: 'Team B');
  String _format   = 'T20';
  int    _overs    = 20;
  int    _players  = 11;

  String? _tossWinner;
  String  _tossDecision = 'bat';

  final _strikerCtrl     = TextEditingController(text: 'Striker');
  final _nonStrikerCtrl  = TextEditingController(text: 'Non-Striker');
  final _bowlerCtrl      = TextEditingController(text: 'Opening Bowler');

  static const _formatOvers = {'T10': 10, 'T20': 20, 'ODI': 50, 'CUSTOM': 20};

  String get team1Name => _team1Ctrl.text.trim().isEmpty ? 'Team A' : _team1Ctrl.text.trim();
  String get team2Name => _team2Ctrl.text.trim().isEmpty ? 'Team B' : _team2Ctrl.text.trim();

  String get effectiveTossWinner => _tossWinner ?? team1Name;

  String get battingTeam {
    if (_tossDecision == 'bat') {
      return effectiveTossWinner;
    } else {
      return effectiveTossWinner == team1Name ? team2Name : team1Name;
    }
  }

  String get bowlingTeam {
    return battingTeam == team1Name ? team2Name : team1Name;
  }

  @override
  void dispose() {
    _team1Ctrl.dispose();
    _team2Ctrl.dispose();
    _strikerCtrl.dispose();
    _nonStrikerCtrl.dispose();
    _bowlerCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        title: const Text('New Match Setup'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_page + 1) / 3,
            backgroundColor: AppColors.neoPressed,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTeamsAndOversPage(),
              _buildTossPage(),
              _buildOpeningPlayersPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neoBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.neoShadowDark.withValues(alpha: 0.4),
            offset: const Offset(0, -4),
            blurRadius: 14,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            children: [
              if (_page > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevPage,
                    child: const Text('Back'),
                  ),
                ),
              if (_page > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _page < 2 ? _nextPage : _startMatch,
                  child: Text(
                    _page < 2 ? 'Continue' : 'Start Match',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_page == 0) {
      _tossWinner ??= team1Name;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _page++);
  }

  void _prevPage() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _page--);
  }

  void _startMatch() {
    final sName = _strikerCtrl.text.trim().isEmpty ? 'Batter 1' : _strikerCtrl.text.trim();
    final nsName = _nonStrikerCtrl.text.trim().isEmpty ? 'Batter 2' : _nonStrikerCtrl.text.trim();
    final bName = _bowlerCtrl.text.trim().isEmpty ? 'Bowler 1' : _bowlerCtrl.text.trim();

    context.read<MatchProvider>().createNewMatch(
      team1Name: team1Name,
      team2Name: team2Name,
      format: _format,
      totalOvers: _overs,
      playersPerSide: _players,
      tossWinner: effectiveTossWinner,
      tossDecision: _tossDecision,
      strikerName: sName,
      nonStrikerName: nsName,
      openingBowlerName: bName,
    );

    Navigator.pushReplacementNamed(context, AppConstants.routeLiveScoring);
  }

  // ── Step 1: Teams & Match Format ──────────────────────────────────────────
  Widget _buildTeamsAndOversPage() {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        const _PageTitle(
          title: 'Teams & Overs',
          subtitle: 'Enter the two competing teams and match duration',
        ),
        AppSpacing.vGap(AppSpacing.xl),

        const SectionHeader(title: 'Team Names'),
        TextField(
          controller: _team1Ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Team 1 Name',
            hintText: 'e.g. Tigers CC',
            prefixIcon: Icon(Icons.shield_outlined),
          ),
        ),
        AppSpacing.vGap(AppSpacing.md),
        TextField(
          controller: _team2Ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Team 2 Name',
            hintText: 'e.g. Lions CC',
            prefixIcon: Icon(Icons.shield_outlined),
          ),
        ),

        AppSpacing.vGap(AppSpacing.xl),
        const SectionHeader(title: 'Match Format & Overs'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: ['T10', 'T20', 'ODI', 'CUSTOM'].map((f) {
            final sel = _format == f;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() {
                  _format = f;
                  _overs  = _formatOvers[f] ?? 20;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.neoBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.65),
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ]
                        : NeoCard.raisedShadows(blur: 8, offset: 3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (sel) const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      if (sel) const SizedBox(width: 6),
                      Text(
                        f == 'CUSTOM' ? 'Custom Overs' : '$f (${_formatOvers[f]} Ov)',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: sel ? Colors.white : AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (_format == 'CUSTOM') ...[
          AppSpacing.vGap(AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                Text('Total Overs: $_overs', style: AppTextStyles.bodyBold),
                const Spacer(),
                _StepperButton(
                  icon: Icons.remove,
                  onTap: () => setState(() => _overs = _overs > 1 ? _overs - 1 : 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_overs', style: AppTextStyles.headline2),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _overs = _overs < 100 ? _overs + 1 : 100),
                ),
              ],
            ),
          ),
        ],

        AppSpacing.vGap(AppSpacing.xl),
        const SectionHeader(title: 'Players Per Side'),
        AppCard(
          child: Row(
            children: [
              Text('$_players players per team', style: AppTextStyles.bodyBold),
              const Spacer(),
              _StepperButton(
                icon: Icons.remove,
                onTap: () => setState(() => _players = _players > 2 ? _players - 1 : 2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_players', style: AppTextStyles.headline2),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: () => setState(() => _players = _players < 25 ? _players + 1 : 25),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2: Toss ──────────────────────────────────────────────────────────
  Widget _buildTossPage() {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        const _PageTitle(
          title: 'Match Toss',
          subtitle: 'Select who won the toss and their elected decision',
        ),
        AppSpacing.vGap(AppSpacing.xl),

        const SectionHeader(title: 'Toss Winner'),
        Row(
          children: [team1Name, team2Name].map((name) {
            final sel = effectiveTossWinner == name;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _tossWinner = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.neoBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.65),
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.30),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ]
                            : NeoCard.raisedShadows(blur: 8, offset: 3),
                      ),
                      child: Center(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: sel ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        AppSpacing.vGap(AppSpacing.xl),
        const SectionHeader(title: 'Toss Decision'),
        Row(
          children: [
            for (final opt in const [
              (value: 'bat', label: '🏏  Elected to Bat'),
              (value: 'bowl', label: '🎳  Elected to Bowl'),
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: opt.value == 'bat' ? 10 : 0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _tossDecision = opt.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _tossDecision == opt.value ? AppColors.accent : AppColors.neoBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _tossDecision == opt.value
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.65),
                          ),
                          boxShadow: _tossDecision == opt.value
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.30),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ]
                              : NeoCard.raisedShadows(blur: 8, offset: 3),
                        ),
                        child: Center(
                          child: Text(
                            opt.label,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: _tossDecision == opt.value ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        AppSpacing.vGap(AppSpacing.xl),
        AppCard(
          backgroundColor: AppColors.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '1st Innings Setup',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                '• Batting First: $battingTeam\n• Bowling First: $bowlingTeam',
                style: AppTextStyles.body2.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Opening Batters & Opening Bowler ───────────────────────────────
  Widget _buildOpeningPlayersPage() {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        const _PageTitle(
          title: 'Opening Players',
          subtitle: 'Enter the opening batters and bowler to begin the match',
        ),
        AppSpacing.vGap(AppSpacing.xl),

        // Batting Team Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_cricket, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Batting: $battingTeam',
                      style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Swap Strike',
                    icon: const Icon(Icons.swap_vert, color: AppColors.accent),
                    onPressed: () {
                      final temp = _strikerCtrl.text;
                      _strikerCtrl.text = _nonStrikerCtrl.text;
                      _nonStrikerCtrl.text = temp;
                    },
                  ),
                ],
              ),
              const Divider(height: 20),

              // Striker
              TextField(
                controller: _strikerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Striker (Facing 1st Ball) *',
                  hintText: 'e.g. Batter 1',
                  prefixIcon: Icon(Icons.sports_cricket, color: AppColors.accent),
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),

              // Non-Striker
              TextField(
                controller: _nonStrikerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Non-Striker (Other End) *',
                  hintText: 'e.g. Batter 2',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        ),

        AppSpacing.vGap(AppSpacing.lg),

        // Bowling Team Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports, color: AppColors.warning, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Bowling: $bowlingTeam',
                    style: AppTextStyles.headline3.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Bowler
              TextField(
                controller: _bowlerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Opening Bowler Name *',
                  hintText: 'e.g. Bowler 1',
                  prefixIcon: Icon(Icons.sports, color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline2),
        AppSpacing.vGap(AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.body2),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeoIconButton(
      icon: icon,
      size: 38,
      iconColor: AppColors.primary,
      onTap: onTap,
    );
  }
}
