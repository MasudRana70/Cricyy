// lib/widgets/player_performance_chart.dart

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/app_spacing.dart';
import '../services/player_stats_aggregator.dart';

enum ChartMode { batting, bowling }

class PlayerPerformanceChart extends StatefulWidget {
  final List<PlayerMatchPerformance> performances;

  const PlayerPerformanceChart({super.key, required this.performances});

  @override
  State<PlayerPerformanceChart> createState() => _PlayerPerformanceChartState();
}

class _PlayerPerformanceChartState extends State<PlayerPerformanceChart> {
  ChartMode _mode = ChartMode.batting;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final hasBattingData = widget.performances.any((p) => p.didBat);
    final hasBowlingData = widget.performances.any((p) => p.didBowl);

    if (!hasBattingData && !hasBowlingData) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rLG,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 36, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text('No match performance data to chart yet.', style: AppTextStyles.body2),
          ],
        ),
      );
    }

    final battingList = widget.performances.where((p) => p.didBat).toList();
    final bowlingList = widget.performances.where((p) => p.didBowl).toList();

    // Auto adjust mode if one is empty
    if (_mode == ChartMode.batting && battingList.isEmpty && bowlingList.isNotEmpty) {
      _mode = ChartMode.bowling;
    } else if (_mode == ChartMode.bowling && bowlingList.isEmpty && battingList.isNotEmpty) {
      _mode = ChartMode.batting;
    }

    final activeList = _mode == ChartMode.batting ? battingList : bowlingList;
    final selectedPerf = (_selectedIndex != null && _selectedIndex! < activeList.length)
        ? activeList[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector Bar
        Row(
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Performance Trends', style: AppTextStyles.headline3.copyWith(fontSize: 16)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.rFull,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _modeButton('Batting (Runs)', ChartMode.batting, _mode == ChartMode.batting),
                  _modeButton('Bowling (Wkts)', ChartMode.bowling, _mode == ChartMode.bowling),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vGap(AppSpacing.sm),

        // Visual Canvas Bar Chart
        Container(
          height: 190,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rLG,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _mode == ChartMode.batting
              ? _buildBattingChart(battingList)
              : _buildBowlingChart(bowlingList),
        ),

        // Selected Performance Inspection Card
        if (selectedPerf != null) ...[
          const SizedBox(height: 8),
          _buildSelectedInspectionCard(selectedPerf),
        ],
      ],
    );
  }

  Widget _modeButton(String label, ChartMode mode, bool selected) {
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _selectedIndex = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.rFull,
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildBattingChart(List<PlayerMatchPerformance> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No batting innings recorded yet in created matches.', style: AppTextStyles.body2),
      );
    }

    final maxRuns = list.map((p) => p.battingRuns).reduce((a, b) => a > b ? a : b);
    final chartCeiling = ((maxRuns < 25 ? 25 : maxRuns) * 1.25).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: list.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final isSelected = _selectedIndex == idx;
        final heightRatio = (p.battingRuns / chartCeiling).clamp(0.08, 1.0);

        final is50 = p.battingRuns >= 50 && p.battingRuns < 100;
        final is100 = p.battingRuns >= 100;

        final gradient = is100
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : (is50
                ? const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ));

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _selectedIndex = isSelected ? null : idx;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Run count label
                  Text(
                    '${p.battingRuns}${p.isNotOut ? "*" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accent : (is100 ? Colors.purple : (is50 ? Colors.amber.shade900 : AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // The Bar
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightRatio,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 32),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Opponent Team label
                  Text(
                    p.opponentTeam,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBowlingChart(List<PlayerMatchPerformance> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No bowling spells recorded yet in created matches.', style: AppTextStyles.body2),
      );
    }

    final maxWkts = list.map((p) => p.wicketsTaken).reduce((a, b) => a > b ? a : b);
    final chartCeiling = ((maxWkts < 3 ? 3 : maxWkts) * 1.3).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: list.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final isSelected = _selectedIndex == idx;
        final heightRatio = (p.wicketsTaken / chartCeiling).clamp(0.10, 1.0);

        final is3Wkts = p.wicketsTaken >= 3;

        final gradient = is3Wkts
            ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              );

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _selectedIndex = isSelected ? null : idx;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Wickets / runs
                  Text(
                    '${p.wicketsTaken}w/${p.runsConceded}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accent : (is3Wkts ? AppColors.error : AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // The Bar
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightRatio,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 32),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.error.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Opponent label
                  Text(
                    p.opponentTeam,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedInspectionCard(PlayerMatchPerformance p) {
    final dateStr = '${p.matchDate.day}/${p.matchDate.month}/${p.matchDate.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.rMD,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _mode == ChartMode.batting ? Icons.sports_cricket : Icons.sports,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${p.opponentTeam} • $dateStr (${p.format})',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                if (_mode == ChartMode.batting) ...[
                  Text(
                    '${p.battingRuns} Runs (${p.ballsFaced} balls)  ${p.fours}×4  ${p.sixes}×6  SR ${(p.ballsFaced > 0 ? (p.battingRuns / p.ballsFaced * 100) : 0).toStringAsFixed(1)}',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                  ),
                  Text(
                    p.isNotOut ? 'Not Out' : (p.dismissalType ?? 'Dismissed'),
                    style: AppTextStyles.caption.copyWith(
                      color: p.isNotOut ? AppColors.success : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${p.wicketsTaken} Wickets / ${p.runsConceded} Runs (${p.oversBowled} ov)  Eco ${p.economy.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                  ),
                  Text(
                    '${p.maidens} Maidens bowled',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _selectedIndex = null),
          ),
        ],
      ),
    );
  }
}
