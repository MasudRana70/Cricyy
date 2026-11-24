// lib/widgets/neo_card.dart
//
// Neomorphic design system primitives — soft, minimalist, tactile surfaces.

import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum NeoStyle {
  raised, // Soft extruded card / button
  inset,  // Pressed-in / active / input well
  flat,   // Flat surface on neoBackground
}

class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final NeoStyle style;
  final Color? color;
  final double? width;
  final double? height;

  const NeoCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
    this.style = NeoStyle.raised,
    this.color,
    this.width,
    this.height,
  });

  static List<BoxShadow> raisedShadows({double blur = 14, double offset = 5}) => [
        BoxShadow(
          color: AppColors.neoShadowDark.withValues(alpha: 0.78),
          offset: Offset(offset, offset),
          blurRadius: blur,
        ),
        BoxShadow(
          color: AppColors.neoShadowLight.withValues(alpha: 0.95),
          offset: Offset(-offset, -offset),
          blurRadius: blur,
        ),
      ];

  static List<BoxShadow> insetShadows({double blur = 8, double offset = 3}) => [
        BoxShadow(
          color: AppColors.neoShadowDark.withValues(alpha: 0.52),
          offset: Offset(offset, offset),
          blurRadius: blur,
        ),
        BoxShadow(
          color: AppColors.neoShadowLight.withValues(alpha: 0.85),
          offset: Offset(-offset, -offset),
          blurRadius: blur,
        ),
      ];

  List<BoxShadow> get _shadows {
    switch (style) {
      case NeoStyle.raised:
        return raisedShadows();
      case NeoStyle.inset:
        return insetShadows();
      case NeoStyle.flat:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (style == NeoStyle.inset ? AppColors.neoPressed : AppColors.neoBackground);
    final radius = BorderRadius.circular(borderRadius);

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: style == NeoStyle.raised
            ? Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1)
            : (style == NeoStyle.inset
                ? Border.all(color: AppColors.neoShadowDark.withValues(alpha: 0.25), width: 1)
                : null),
        boxShadow: _shadows,
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

/// Circular neomorphic icon button
class NeoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? tooltip;
  final bool isActive;

  const NeoIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconColor,
    this.backgroundColor,
    this.tooltip,
    this.isActive = false,
  });

  @override
  State<NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<NeoIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDown = _pressed || widget.isActive;
    final bg = widget.backgroundColor ?? (isDown ? AppColors.neoPressed : AppColors.neoBackground);

    final w = MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDown
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.65),
              width: 1,
            ),
            boxShadow: isDown
                ? NeoCard.insetShadows(blur: 5, offset: 2)
                : NeoCard.raisedShadows(blur: 9, offset: 4),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.45,
            color: widget.iconColor ?? (widget.isActive ? AppColors.primary : AppColors.textSecondary),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: w);
    }
    return w;
  }
}

/// Neomorphic pill button / selectable filter toggle
class NeoPillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  const NeoPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor : AppColors.neoBackground,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.65),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.30),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ]
                : NeoCard.raisedShadows(blur: 8, offset: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
