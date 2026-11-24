// lib/widgets/score_badge.dart — colored neomorphic badge for scoring events

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

enum ScoreType { dot, one, two, three, four, six, wide, noBall, bye, legBye, wicket }

class ScoreBadge extends StatelessWidget {
  final String text;
  final ScoreType type;
  final double size;

  const ScoreBadge({
    super.key,
    required this.text,
    required this.type,
    this.size = 32,
  });

  factory ScoreBadge.forValue(String val, {double size = 32}) {
    final ScoreType type;
    if (val.startsWith('wd')) {
      type = ScoreType.wide;
    } else if (val.startsWith('nb')) {
      type = ScoreType.noBall;
    } else if (val.startsWith('lb')) {
      type = ScoreType.legBye;
    } else if (val.startsWith('b')) {
      type = ScoreType.bye;
    } else if (val.contains('W')) {
      type = ScoreType.wicket;
    } else {
      type = switch (val) {
        '0' => ScoreType.dot,
        '1' => ScoreType.one,
        '2' => ScoreType.two,
        '3' => ScoreType.three,
        '4' => ScoreType.four,
        '6' => ScoreType.six,
        _   => ScoreType.dot,
      };
    }
    return ScoreBadge(text: val, type: type, size: size);
  }

  Color get _bg => switch (type) {
    ScoreType.dot    => AppColors.neoPressed,
    ScoreType.one    => AppColors.successLight,
    ScoreType.two    => AppColors.successLight,
    ScoreType.three  => AppColors.successLight,
    ScoreType.four   => AppColors.primaryLight,
    ScoreType.six    => const Color(0xFFF3E8FF),
    ScoreType.wicket => AppColors.errorLight,
    ScoreType.wide   => AppColors.warningLight,
    ScoreType.noBall => AppColors.warningLight,
    ScoreType.bye    => AppColors.neoPressed,
    ScoreType.legBye => AppColors.neoPressed,
  };

  Color get _fg => switch (type) {
    ScoreType.dot    => AppColors.textSecondary,
    ScoreType.one    => AppColors.success,
    ScoreType.two    => AppColors.success,
    ScoreType.three  => AppColors.success,
    ScoreType.four   => AppColors.primary,
    ScoreType.six    => AppColors.six,
    ScoreType.wicket => AppColors.error,
    ScoreType.wide   => AppColors.warning,
    ScoreType.noBall => AppColors.warning,
    ScoreType.bye    => AppColors.textSecondary,
    ScoreType.legBye => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final isLong = text.length > 2;
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: EdgeInsets.symmetric(horizontal: isLong ? 7 : 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: _fg.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.neoShadowDark.withValues(alpha: 0.45),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: AppColors.neoShadowLight.withValues(alpha: 0.9),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: _fg,
            fontWeight: FontWeight.w700,
            fontSize: isLong ? (size * 0.32) : (size * 0.38),
          ),
        ),
      ),
    );
  }
}
