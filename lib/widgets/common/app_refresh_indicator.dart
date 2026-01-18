import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A themed RefreshIndicator that matches the app's design system
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double strokeWidth;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 60.0,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? Colors.white,
      displacement: displacement,
      strokeWidth: strokeWidth,
      child: child,
    );
  }
}
