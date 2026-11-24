// lib/widgets/stat_tile.dart — single stat cell for scorecards

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/app_spacing.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color? valueColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.scoreMedium.copyWith(
            fontSize: 22,
            color: valueColor ?? (isHighlighted ? AppColors.primary : AppColors.textPrimary),
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vGap(2),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

// Row of stat tiles with dividers
class StatRow extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const StatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final i    = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: stat['label'] as String,
                  value: stat['value'] as String,
                  isHighlighted: stat['highlight'] == true,
                  valueColor: stat['color'] as Color?,
                ),
              ),
              if (i < stats.length - 1)
                Container(
                  width: 1, height: 36,
                  color: AppColors.borderLight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
