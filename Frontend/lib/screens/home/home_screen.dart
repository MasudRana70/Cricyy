// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../core/app_constants.dart';
import '../../providers/match_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/match_model.dart';
import '../../services/player_stats_aggregator.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sync_controls.dart';
import '../../widgets/player_quick_view_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _navIndex == 0 ? _buildFAB() : null,
    );
  }

  Widget _buildBody() {
    return switch (_navIndex) {
      0 => const _DashboardTab(),
      1 => const _HistoryTab(),
      2 => const _PlayersTab(),
      _ => const _DashboardTab(),
    };
  }

  Widget _buildBottomNav() {
    const items = [
      (icon: Icons.sports_cricket_outlined, active: Icons.sports_cricket_rounded, label: 'Dashboard'),
      (icon: Icons.history_outlined, active: Icons.history_rounded, label: 'History'),
      (icon: Icons.people_outline, active: Icons.people_rounded, label: 'Players'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.neoBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.neoShadowDark.withValues(alpha: 0.45),
            offset: const Offset(0, -4),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final selected = _navIndex == i;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _navIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.neoPressed : AppColors.neoBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                          boxShadow: selected
                              ? NeoCard.insetShadows(blur: 6, offset: 2)
                              : NeoCard.raisedShadows(blur: 8, offset: 3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.active : item.icon,
                              size: 20,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppConstants.routeCreateMatch),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Match', style: AppTextStyles.buttonSmall),
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.read<MatchProvider>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshMatches(silent: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SyncSummaryBanner(),
                      AppSpacing.vGap(AppSpacing.md),
                      _LiveMatchSection(),
                      AppSpacing.vGap(AppSpacing.xl),
                      _RecentMatchesSection(),
                      AppSpacing.vGap(100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.neoBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 19),
          ),
          AppSpacing.hGap(AppSpacing.sm),
          Text('Cricyy', style: AppTextStyles.headline3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: SyncActionControls(compact: true),
        ),
      ],
    );
  }
}

class _SyncSummaryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        final connected = prov.isCloudConnected;
        final autoOn = prov.autoRefreshEnabled;
        final label = connected
            ? (autoOn
                ? 'Live Multi-User Sync active • Updates every 5s'
                : 'Connected to shared server • Manual refresh mode')
            : 'Offline / Local cache mode • Tap to configure cloud sync';

        return GestureDetector(
          onTap: () => showSyncSettingsDialog(context),
          child: NeoCard(
            style: NeoStyle.inset,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  connected ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                  size: 16,
                  color: connected ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Settings',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveMatchSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && prov.matches.isEmpty) return const _LoadingCard();
        final live = prov.liveMatches;
        if (live.isEmpty) return _EmptyLiveCard();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Live Matches (${live.length})'),
            ...live.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _LiveMatchCard(match: m),
            )),
          ],
        );
      },
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final MatchModel match;
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final inn1 = match.innings1;
    final inn2 = match.innings2;
    final currentInn = inn2 ?? inn1;

    final isTeam1Batting = currentInn != null &&
        ((currentInn.battingTeamName == match.team1Name) || (currentInn.battingTeamId == match.team1Id));

    final team1Score = isTeam1Batting
        ? '${currentInn.scoreDisplay} (${currentInn.oversDisplay})'
        : (inn1 != null ? '${inn1.scoreDisplay} (${inn1.oversDisplay})' : 'Yet to bat');

    final team2Score = !isTeam1Batting
        ? (currentInn != null ? '${currentInn.scoreDisplay} (${currentInn.oversDisplay})' : 'Yet to bat')
        : (inn2 != null ? '${inn2.scoreDisplay} (${inn2.oversDisplay})' : 'Yet to bat');

    final crr = currentInn != null ? currentInn.currentRunRate.toStringAsFixed(2) : '-';
    final striker = currentInn?.striker;
    final nonStriker = currentInn?.nonStriker;
    final bowler = currentInn?.currentBowler;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.read<MatchProvider>().selectMatch(match);
        Navigator.pushNamed(context, AppConstants.routeLiveScoring, arguments: match);
      },
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('LIVE', style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('${match.format} • ${match.totalOvers} Overs',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    context.read<MatchProvider>().selectMatch(match);
                    Navigator.pushNamed(context, AppConstants.routeScorecard, arguments: match);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Scorecard',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Score
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(match.team1Name,
                                    style: AppTextStyles.bodyBold,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isTeam1Batting) const SizedBox(width: 4),
                              if (isTeam1Batting)
                                const Icon(Icons.sports_cricket, size: 14, color: AppColors.primary),
                            ],
                          ),
                          AppSpacing.vGap(4),
                          Text(team1Score, style: AppTextStyles.scoreMedium.copyWith(fontSize: 21)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text('vs', style: AppTextStyles.body2),
                          AppSpacing.vGap(4),
                          NeoCard(
                            style: NeoStyle.inset,
                            borderRadius: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text('CRR $crr', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isTeam1Batting)
                                const Icon(Icons.sports_cricket, size: 14, color: AppColors.primary),
                              if (!isTeam1Batting) const SizedBox(width: 4),
                              Flexible(
                                child: Text(match.team2Name,
                                    style: AppTextStyles.bodyBold,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          AppSpacing.vGap(4),
                          Text(team2Score, style: AppTextStyles.scoreMedium.copyWith(fontSize: 21)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (striker != null || bowler != null) ...[
                  const SizedBox(height: 12),
                  NeoCard(
                    style: NeoStyle.inset,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_cricket, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (striker != null) '${striker.playerName} ${striker.runs}*(${striker.balls})',
                              if (nonStriker != null) '${nonStriker.playerName} ${nonStriker.runs}(${nonStriker.balls})',
                            ].join(' • '),
                            style: AppTextStyles.body2.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bowler != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${bowler.playerName} ${bowler.oversDisplay}-${bowler.maidens}-${bowler.runs}-${bowler.wickets}',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          NeoCard(
            style: NeoStyle.inset,
            borderRadius: 100,
            padding: const EdgeInsets.all(16),
            child: const Icon(Icons.sports_cricket_rounded, size: 36, color: AppColors.primary),
          ),
          AppSpacing.vGap(AppSpacing.md),
          Text('No Live Matches Right Now', style: AppTextStyles.bodyBold),
          AppSpacing.vGap(AppSpacing.xs),
          Text(
            'Tap "New Match" to start scoring, or pull down to sync matches created by others.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentMatchesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        final completed = prov.completedMatches;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recent Completed Matches',
              action: 'See All',
              onAction: () => Navigator.pushNamed(context, AppConstants.routeMatchHistory),
            ),
            if (completed.isEmpty)
              NeoCard(
                style: NeoStyle.inset,
                child: Center(
                  child: Text('No completed matches yet.', style: AppTextStyles.body2),
                ),
              )
            else
              ...completed.take(5).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompactMatchCard(match: m),
              )),
          ],
        );
      },
    );
  }
}

class _CompactMatchCard extends StatelessWidget {
  final MatchModel match;
  const _CompactMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final result = match.result;
    final inn1 = match.innings1;
    final inn2 = match.innings2;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () {
        context.read<MatchProvider>().selectMatch(match);
        Navigator.pushNamed(
          context,
          match.isLive ? AppConstants.routeLiveScoring : AppConstants.routeScorecard,
          arguments: match,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${match.team1Name} vs ${match.team2Name}',
                        style: AppTextStyles.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    AppSpacing.vGap(AppSpacing.xs),
                    Row(
                      children: [
                        if (match.isLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.live,
                              borderRadius: AppRadius.rFull,
                            ),
                            child: Text('LIVE',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.65),
                            borderRadius: AppRadius.rFull,
                          ),
                          child: Text(match.format,
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDate(match.matchDate), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (result != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppRadius.rMD,
                    ),
                    child: Text(
                      result.description ?? 'Result',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
            ],
          ),
          if (inn1 != null || inn2 != null) ...[
            const SizedBox(height: 10),
            NeoCard(
              style: NeoStyle.inset,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (inn1 != null)
                    Flexible(
                      child: Text(
                        '${inn1.battingTeamName}: ${inn1.scoreDisplay} (${inn1.oversDisplay})',
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (inn2 != null)
                    Flexible(
                      child: Text(
                        '${inn2.battingTeamName}: ${inn2.scoreDisplay} (${inn2.oversDisplay})',
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        title: const Text('Match History'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncActionControls(compact: true),
          ),
        ],
      ),
      body: Consumer<MatchProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = prov.matches;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => prov.refreshMatches(silent: false),
            child: matches.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AppCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_rounded, size: 44, color: AppColors.textHint),
                                const SizedBox(height: 10),
                                Text('No matches yet', style: AppTextStyles.bodyBold),
                                const SizedBox(height: 4),
                                Text('Pull down to refresh or create a match from Dashboard.',
                                    style: AppTextStyles.body2, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AppSpacing.pagePadding,
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => AppSpacing.vGap(AppSpacing.md),
                        itemBuilder: (_, i) => _CompactMatchCard(match: matches[i]),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// ── Players Tab ───────────────────────────────────────────────────────────────
class _PlayersTab extends StatefulWidget {
  const _PlayersTab();

  @override
  State<_PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<_PlayersTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchProv = context.read<MatchProvider>();
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        title: const Text('Players & Statistics'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncActionControls(compact: true),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, prov, _) {
          final profiles = prov.profiles;
          final total = prov.totalPlayers;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  // Search field (neomorphic inset)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: NeoCard(
                      style: NeoStyle.inset,
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => prov.search(v),
                        decoration: InputDecoration(
                          hintText: 'Search player name...',
                          filled: false,
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    prov.search('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Sorting Filter Chips (neomorphic pills)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _sortChip(prov, 'runs', '🏏 Most Runs'),
                        const SizedBox(width: 10),
                        _sortChip(prov, 'wickets', '🎯 Most Wickets'),
                        const SizedBox(width: 10),
                        _sortChip(prov, 'matches', '📅 Matches'),
                        const SizedBox(width: 10),
                        _sortChip(prov, 'name', '🔤 Name (A-Z)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Player List with Pull-to-Refresh
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => matchProv.refreshMatches(silent: false),
                      child: profiles.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 60),
                                total == 0
                                    ? _buildEmptyNoPlayers(context)
                                    : _buildEmptySearchResult(prov),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: profiles.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 14),
                              itemBuilder: (_, i) => _PlayerCard(profile: profiles[i]),
                            ),
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

  Widget _sortChip(PlayerProvider prov, String sortKey, String label) {
    return NeoPillButton(
      label: label,
      selected: prov.sortBy == sortKey,
      onTap: () => prov.setSortBy(sortKey),
    );
  }

  Widget _buildEmptyNoPlayers(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeoCard(
                style: NeoStyle.inset,
                borderRadius: 100,
                padding: const EdgeInsets.all(18),
                child: const Icon(Icons.sports_cricket_rounded, size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text('No Players Yet', style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text(
                'Players are automatically aggregated with career batting/bowling stats and performance graphs from matches created by you or others.',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppConstants.routeCreateMatch),
                icon: const Icon(Icons.add),
                label: const Text('Create First Match'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchResult(PlayerProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No players found', style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text(
              'No player matched "${_searchCtrl.text}". Try another name.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PlayerAggregatedProfile profile;
  const _PlayerCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final player = profile.player;
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

    final initial = player.name.trim().isNotEmpty ? player.name.trim()[0].toUpperCase() : 'P';

    void openProfile() {
      context.read<PlayerProvider>().loadPlayerProfile(player.id);
      Navigator.pushNamed(
        context,
        AppConstants.routePlayerProfile,
        arguments: player.id,
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => showPlayerQuickView(context, player.name),
      child: Column(
        children: [
          Row(
            children: [
              // Clickable Player Avatar + Name opens Performance Graph Sheet directly
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: NeoCard.raisedShadows(blur: 8, offset: 3),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: AppTextStyles.bodyBold.copyWith(
                              fontSize: 16,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: AppRadius.rFull,
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bat.totalMatches} ${bat.totalMatches == 1 ? "match" : "matches"}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Graph Quick-View pill button + Full Profile chevron
              GestureDetector(
                onTap: () => showPlayerQuickView(context, player.name),
                child: NeoCard(
                  style: NeoStyle.inset,
                  borderRadius: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Graph',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NeoIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                size: 34,
                tooltip: 'Open full career profile',
                onTap: openProfile,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Key Stats Row (Neomorphic inset wells)
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  style: NeoStyle.inset,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Text('🏏', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bat.totalRuns} Runs',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                            ),
                            Text(
                              'Avg ${bat.battingAverage?.toStringAsFixed(1) ?? "-"} • SR ${bat.strikeRate.toStringAsFixed(0)}',
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeoCard(
                  style: NeoStyle.inset,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bowl.totalWickets} Wkts',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                            ),
                            Text(
                              '${bowl.overs} ov • Eco ${bowl.economyRate.toStringAsFixed(1)}',
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
