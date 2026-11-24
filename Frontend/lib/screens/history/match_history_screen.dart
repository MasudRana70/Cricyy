// lib/screens/history/match_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../core/app_constants.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sync_controls.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  String _status    = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().refreshMatches(silent: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: NeoCard(
        style: NeoStyle.inset,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: const InputDecoration(
            hintText: 'Search by team name...',
            filled: false,
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['all', 'in_progress', 'completed'];
    final labels  = {'all': 'All', 'in_progress': 'Live', 'completed': 'Completed'};
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: FormatChip(
            label: labels[f]!,
            selected: _status == f,
            onTap: () => setState(() => _status = f),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<MatchProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && prov.matches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        var matches = prov.matches;
        if (_status != 'all') matches = matches.where((m) => m.status == _status).toList();
        if (_query.isNotEmpty) {
          matches = matches.where((m) =>
            m.team1Name.toLowerCase().contains(_query) ||
            m.team2Name.toLowerCase().contains(_query)).toList();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => prov.refreshMatches(silent: false),
          child: matches.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded, size: 56, color: AppColors.textHint),
                          AppSpacing.vGap(AppSpacing.base),
                          Text('No matches found', style: AppTextStyles.bodyBold),
                          AppSpacing.vGap(AppSpacing.xs),
                          Text('Try a different search or pull down to refresh', style: AppTextStyles.body2),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.pagePadding.copyWith(top: 12),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => AppSpacing.vGap(AppSpacing.md),
                  itemBuilder: (_, i) => _MatchHistoryCard(match: matches[i]),
                ),
        );
      },
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  final MatchModel match;
  const _MatchHistoryCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.read<MatchProvider>().selectMatch(match);
        Navigator.pushNamed(context,
            match.isLive ? AppConstants.routeLiveScoring : AppConstants.routeScorecard,
            arguments: match);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: match.isLive
                  ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                  : null,
              color: match.isLive ? null : AppColors.neoPressed,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (match.isLive)
                  Row(children: [
                    Container(width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('LIVE', style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                  ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: match.isLive ? Colors.white.withValues(alpha: 0.2) : AppColors.primaryLight,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Text(match.format,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: match.isLive ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(_formatDate(match.matchDate),
                    style: AppTextStyles.caption.copyWith(
                        color: match.isLive ? Colors.white70 : AppColors.textHint)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(match.team1Name,
                          style: AppTextStyles.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text('vs', style: AppTextStyles.body2),
                    Expanded(
                      child: Text(match.team2Name,
                          style: AppTextStyles.bodyBold, textAlign: TextAlign.end,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (match.isCompleted && match.result != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppRadius.rMD,
                    ),
                    child: Text(
                      match.result!.description ?? '',
                      style: AppTextStyles.body2.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (match.innings1 != null || match.innings2 != null) ...[
                  const SizedBox(height: 8),
                  NeoCard(
                    style: NeoStyle.inset,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (match.innings1 != null)
                          Text(
                            '${match.innings1!.battingTeamName}: ${match.innings1!.scoreDisplay} (${match.innings1!.oversDisplay})',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        if (match.innings2 != null)
                          Text(
                            '${match.innings2!.battingTeamName}: ${match.innings2!.scoreDisplay} (${match.innings2!.oversDisplay})',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
                if (match.isLive) ...[
                  Builder(builder: (context) {
                    final inn = match.innings2 ?? match.innings1;
                    if (inn == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Text('${inn.battingTeamName}: ${inn.scoreDisplay} (${inn.oversDisplay})', style: AppTextStyles.scoreSmall),
                          const Spacer(),
                          Text('CRR: ${inn.currentRunRate.toStringAsFixed(2)}', style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
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
