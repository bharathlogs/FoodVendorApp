import 'package:flutter/material.dart';
import 'app_transitions.dart';

/// Custom PageRoute that applies consistent transitions across the app
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AppTransitionType transitionType;
  final Duration? customDuration;

  AppPageRoute({
    required this.page,
    this.transitionType = AppTransitionType.slideRight,
    this.customDuration,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration:
              customDuration ?? AppTransitions.defaultDuration,
          reverseTransitionDuration:
              customDuration ?? AppTransitions.defaultDuration,
          transitionsBuilder:
              AppTransitions.getTransitionBuilder(transitionType),
        );
}

/// PageRoute with no transition (instant)
class NoTransitionRoute<T> extends PageRouteBuilder<T> {
  NoTransitionRoute({
    required Widget page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
        );
}
