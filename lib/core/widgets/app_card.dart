import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final bool hasBorder;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.elevation,
    this.onTap,
    this.hasBorder = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: color ?? AppColors.surface,
        elevation: elevation ?? 1,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
              border: hasBorder
                  ? border ?? Border.all(color: AppColors.surfaceVariant, width: 1)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
