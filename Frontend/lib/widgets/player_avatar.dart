// lib/widgets/player_avatar.dart

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import 'neo_card.dart';

class PlayerAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final Color? bgColor;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.imageUrl,
    this.bgColor,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _color => bgColor ?? AppColors.primaryDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neoBackground,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
        boxShadow: NeoCard.raisedShadows(blur: 7, offset: 3),
      ),
      child: Center(
        child: Container(
          width: size - 6,
          height: size - 6,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials,
              style: AppTextStyles.label.copyWith(
                color: _color,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BallByBallRow extends StatelessWidget {
  final List<String> balls;

  const BallByBallRow({super.key, required this.balls});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: balls.map((b) {
        final color = switch (b) {
          'W'  => AppColors.error,
          '4'  => AppColors.primary,
          '6'  => AppColors.six,
          'wd' => AppColors.warning,
          'nb' => AppColors.warning,
          '0'  => AppColors.textHint,
          _    => AppColors.success,
        };
        final bg = switch (b) {
          'W'  => AppColors.errorLight,
          '4'  => AppColors.primaryLight,
          '6'  => const Color(0xFFF3E8FF),
          'wd' => AppColors.warningLight,
          'nb' => AppColors.warningLight,
          _    => AppColors.neoPressed,
        };
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: Text(
              b,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
