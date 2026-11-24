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
import '../../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), activeIcon: Icon(Icons.sports_cricket), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Players'),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, AppConstants.routeCreateMatch),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text('New Match', style: AppTextStyles.buttonSmall),
      elevation: 2,
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: AppSpacing.pagePadding,
          sliver: SliverList(delegate: SliverChildListDelegate([
            _LiveMatchSection(),
            AppSpacing.vGap(AppSpacing.xl),
            _RecentMatchesSection(),
            AppSpacing.vGap(100), // FAB clearance
          ])),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.rSM,
            ),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 18),
          ),
          AppSpacing.hGap(AppSpacing.sm),
          Text('Cricyy', style: AppTextStyles.headline3.copyWith(color: AppColors.primary)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          color: AppColors.textSecondary,
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _LiveMatchSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) return const _LoadingCard();
        final live = prov.liveMatches;
        if (live.isEmpty) return _EmptyLiveCard();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Live Now'),
            ...live.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
        ? (currentInn != null ? '${currentInn.scoreDisplay} (${currentInn.oversDisplay})' : 'Yet to bat')
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                          Text(team1Score, style: AppTextStyles.scoreMedium.copyWith(fontSize: 22)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('vs', style: AppTextStyles.body2),
                        AppSpacing.vGap(4),
                        Text('CRR: $crr', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                      ],
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
                          Text(team2Score, style: AppTextStyles.scoreMedium.copyWith(fontSize: 22)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (striker != null || bowler != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.rMD,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_cricket, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (striker != null) '${striker.playerName} ${striker.runs}*(${striker.balls})',
                              if (nonStriker != null) '${nonStriker.playerName} ${nonStriker.runs}*(${nonStriker.balls})',
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
      child: Column(
        children: [
          const Icon(Icons.sports_cricket, size: 48, color: AppColors.textHint),
          AppSpacing.vGap(AppSpacing.sm),
          Text('No live matches', style: AppTextStyles.bodyBold),
          AppSpacing.vGap(AppSpacing.xs),
          Text('Start a new match to begin scoring', style: AppTextStyles.body2),
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
              title: 'Recent Matches',
              action: 'See All',
              onAction: () => Navigator.pushNamed(context, AppConstants.routeMatchHistory),
            ),
            if (completed.isEmpty)
              Text('No completed matches yet.', style: AppTextStyles.body2)
            else
              ...completed.take(3).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.pushNamed(context, AppConstants.routeScorecard, arguments: match),
      child: Row(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
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
          const SizedBox(width: 12),
          if (result != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: AppRadius.rMD,
              ),
              child: Text(
                result.description ?? 'Result',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w600),
                maxLines: 2, textAlign: TextAlign.right,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
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
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const _HistoryTabView(),
      ),
    );
  }
}

class _HistoryTabView extends StatelessWidget {
  const _HistoryTabView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Match History')),
      body: Consumer<MatchProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          final matches = prov.matches;
          if (matches.isEmpty) return Center(child: Text('No matches yet', style: AppTextStyles.body2));
          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: matches.length,
            separatorBuilder: (_, _) => AppSpacing.vGap(AppSpacing.sm),
            itemBuilder: (_, i) => _CompactMatchCard(match: matches[i]),
          );
        },
      ),
    );
  }
}

// ── Players Tab ───────────────────────────────────────────────────────────────
class _PlayersTab extends StatelessWidget {
  const _PlayersTab();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const _PlayersTabView(),
      ),
    );
  }
}

class _PlayersTabView extends StatefulWidget {
  const _PlayersTabView();

  @override
  State<_PlayersTabView> createState() => _PlayersTabViewState();
}

class _PlayersTabViewState extends State<_PlayersTabView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Players & Statistics'),
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, prov, _) {
          final profiles = prov.profiles;
          final total = prov.totalPlayers;

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => prov.search(v),
                  decoration: InputDecoration(
                    hintText: 'Search player name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
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

              // Sorting Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _sortChip(prov, 'runs', '🏏 Most Runs'),
                    const SizedBox(width: 8),
                    _sortChip(prov, 'wickets', '🎯 Most Wickets'),
                    const SizedBox(width: 8),
                    _sortChip(prov, 'matches', '📅 Matches'),
                    const SizedBox(width: 8),
                    _sortChip(prov, 'name', '🔤 Name (A-Z)'),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Player List or Empty State
              Expanded(
                child: profiles.isEmpty
                    ? (total == 0
                        ? _buildEmptyNoPlayers(context)
                        : _buildEmptySearchResult(prov))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: profiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PlayerCard(profile: profiles[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sortChip(PlayerProvider prov, String sortKey, String label) {
    final selected = prov.sortBy == sortKey;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      onSelected: (_) => prov.setSortBy(sortKey),
    );
  }

  Widget _buildEmptyNoPlayers(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_cricket, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No Players Yet', style: AppTextStyles.headline2),
            const SizedBox(height: 8),
            Text(
              'Players are automatically registered with their career batting and bowling stats as soon as you create and score matches.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeCreateMatch),
              icon: const Icon(Icons.add),
              label: const Text('Create First Match'),
            ),
          ],
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
            const Icon(Icons.person_search, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No players found', style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text(
              'No player matched your search "${_searchCtrl.text}". Try another name.',
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

    // Determine role badge
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

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        context.read<PlayerProvider>().loadPlayerProfile(player.id);
        Navigator.pushNamed(
          context,
          AppConstants.routePlayerProfile,
          arguments: player.id,
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
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
              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),

          // Key Stats Row
          Row(
            children: [
              // Batting Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.rSM,
                  ),
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
              const SizedBox(width: 8),
              // Bowling Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.rSM,
                  ),
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
    return AppCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
