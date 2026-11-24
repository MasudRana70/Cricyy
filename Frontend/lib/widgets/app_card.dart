// lib/widgets/app_card.dart
//
// Neomorphic card — raised soft-shadow style on AppColors.neoBackground.

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import 'neo_card.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;

  // Kept for caller compatibility; neomorphism relies on soft dual shadows.
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 20,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.neoBackground;
    final radius = BorderRadius.circular(borderRadius);

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.58),
          width: 1,
        ),
        boxShadow: NeoCard.raisedShadows(blur: 14, offset: 5),
      ),
      child: child,
    );

    if (onTap == null) return container;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: container,
      ),
    );
  }
}
