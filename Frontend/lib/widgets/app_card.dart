// lib/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = AppRadius.lg,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(color: AppColors.border, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
