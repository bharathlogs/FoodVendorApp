import 'package:flutter/material.dart';

/// Defines transition types available throughout the app
enum AppTransitionType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  scale,
  fadeScale,
}

/// Provides consistent transition builders for page navigation
class AppTransitions {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOutCubic;

  /// Fade transition - good for auth flows and subtle transitions
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: defaultCurve,
      ),
      child: child,
    );
  }

  /// Slide from right - standard forward navigation
  static Widget slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Slide from left - reverse navigation feel
  static Widget slideLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Slide up - for modal-like screens
  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Slide down - for dismissing modals
  static Widget slideDownTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Scale transition - for emphasis
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: child,
    );
  }

  /// Fade + Scale - branded transition for home screens
  static Widget fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    final scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: defaultCurve,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  /// Get transition builder by type
  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) getTransitionBuilder(AppTransitionType type) {
    switch (type) {
      case AppTransitionType.fade:
        return fadeTransition;
      case AppTransitionType.slideRight:
        return slideRightTransition;
      case AppTransitionType.slideLeft:
        return slideLeftTransition;
      case AppTransitionType.slideUp:
        return slideUpTransition;
      case AppTransitionType.slideDown:
        return slideDownTransition;
      case AppTransitionType.scale:
        return scaleTransition;
      case AppTransitionType.fadeScale:
        return fadeScaleTransition;
    }
  }
}
