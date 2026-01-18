import 'package:flutter/material.dart';
import 'app_page_route.dart';
import 'app_transitions.dart';

/// Extension methods for easier navigation with transitions
extension NavigationExtensions on BuildContext {
  /// Push a page with custom transition
  Future<T?> pushWithTransition<T>(
    Widget page, {
    AppTransitionType transition = AppTransitionType.slideRight,
    Duration? duration,
  }) {
    return Navigator.of(this).push<T>(
      AppPageRoute(
        page: page,
        transitionType: transition,
        customDuration: duration,
      ),
    );
  }

  /// Push replacement with custom transition
  Future<T?> pushReplacementWithTransition<T, TO>(
    Widget page, {
    AppTransitionType transition = AppTransitionType.fadeScale,
    Duration? duration,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      AppPageRoute(
        page: page,
        transitionType: transition,
        customDuration: duration,
      ),
      result: result,
    );
  }

  /// Push and remove all previous routes with transition
  Future<T?> pushAndRemoveAllWithTransition<T>(
    Widget page, {
    AppTransitionType transition = AppTransitionType.fadeScale,
    Duration? duration,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      AppPageRoute(
        page: page,
        transitionType: transition,
        customDuration: duration,
      ),
      (route) => false,
    );
  }

  /// Pop the current route
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Pop until a specific route
  void popUntil(bool Function(Route<dynamic>) predicate) {
    Navigator.of(this).popUntil(predicate);
  }

  /// Check if can pop
  bool canPop() {
    return Navigator.of(this).canPop();
  }
}
