import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Reusable high-performance glassmorphic card.
///
/// Wraps content in ClipRRect -> BackdropFilter with strict blur limits (sigma: 16)
/// to prevent GPU throttling, accented by a subtle directional gradient border.
class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? customFill;
  final Color? customBorder;
  final VoidCallback? onTap;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusLg,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.customFill,
    this.customBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = customFill ??
        (isDark ? AppColors.darkSurfaceGlass : AppColors.lightSurfaceGlass);
    final border = customBorder ??
        (isDark ? AppColors.darkBorderGlass : AppColors.lightBorderGlass);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSpacing.glassBlurSigma,
          sigmaY: AppSpacing.glassBlurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: border,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
