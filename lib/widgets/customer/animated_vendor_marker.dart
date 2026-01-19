import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';

/// Tracks animated positions for vendors on the map
/// Uses interpolation to smoothly animate between position updates
class VendorPositionTracker extends ChangeNotifier {
  final Map<String, VendorAnimationData> _vendorData = {};
  final Duration animationDuration;

  VendorPositionTracker({
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  /// Update vendor position - call this when new position data arrives
  void updatePosition(String vendorId, LatLng newPosition) {
    if (_vendorData.containsKey(vendorId)) {
      final data = _vendorData[vendorId]!;
      // Only animate if position actually changed
      if (data.targetPosition != newPosition) {
        data.previousPosition = data.currentPosition;
        data.targetPosition = newPosition;
        data.animationStart = DateTime.now();
        data.isAnimating = true;
      }
    } else {
      _vendorData[vendorId] = VendorAnimationData(
        previousPosition: newPosition,
        targetPosition: newPosition,
        currentPosition: newPosition,
        animationStart: DateTime.now(),
        isAnimating: false,
      );
    }
    notifyListeners();
  }

  /// Get current interpolated position for a vendor
  LatLng getPosition(String vendorId) {
    final data = _vendorData[vendorId];
    if (data == null) {
      return const LatLng(0, 0);
    }

    if (!data.isAnimating) {
      return data.targetPosition;
    }

    // Calculate animation progress
    final elapsed = DateTime.now().difference(data.animationStart);
    final progress = (elapsed.inMilliseconds / animationDuration.inMilliseconds)
        .clamp(0.0, 1.0);

    // Apply easing curve
    final easedProgress = Curves.easeInOutCubic.transform(progress);

    // Interpolate position
    final lat = data.previousPosition.latitude +
        (data.targetPosition.latitude - data.previousPosition.latitude) *
            easedProgress;
    final lng = data.previousPosition.longitude +
        (data.targetPosition.longitude - data.previousPosition.longitude) *
            easedProgress;

    final interpolated = LatLng(lat, lng);
    data.currentPosition = interpolated;

    // Mark animation as complete
    if (progress >= 1.0) {
      data.isAnimating = false;
      data.currentPosition = data.targetPosition;
    }

    return interpolated;
  }

  /// Check if any vendor is currently animating
  bool get hasActiveAnimations =>
      _vendorData.values.any((data) => data.isAnimating);

  /// Remove vendor from tracking
  void removeVendor(String vendorId) {
    _vendorData.remove(vendorId);
    notifyListeners();
  }

  /// Clear all tracked vendors
  void clear() {
    _vendorData.clear();
    notifyListeners();
  }

  /// Get all tracked vendor IDs
  Set<String> get trackedVendorIds => _vendorData.keys.toSet();
}

/// Data class to hold vendor animation state
class VendorAnimationData {
  LatLng previousPosition;
  LatLng targetPosition;
  LatLng currentPosition;
  DateTime animationStart;
  bool isAnimating;

  VendorAnimationData({
    required this.previousPosition,
    required this.targetPosition,
    required this.currentPosition,
    required this.animationStart,
    required this.isAnimating,
  });
}

/// Widget that rebuilds periodically during animations
class AnimatedMarkerLayer extends StatefulWidget {
  final VendorPositionTracker positionTracker;
  final Widget Function(Map<String, LatLng> positions) builder;
  final Duration refreshRate;

  const AnimatedMarkerLayer({
    super.key,
    required this.positionTracker,
    required this.builder,
    this.refreshRate = const Duration(milliseconds: 16), // ~60fps
  });

  @override
  State<AnimatedMarkerLayer> createState() => _AnimatedMarkerLayerState();
}

class _AnimatedMarkerLayerState extends State<AnimatedMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Map<String, LatLng> _currentPositions = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.positionTracker.addListener(_onPositionUpdate);
    _updatePositions();
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.positionTracker.removeListener(_onPositionUpdate);
    super.dispose();
  }

  void _onPositionUpdate() {
    _updatePositions();
    // Start ticker if animations are active
    if (widget.positionTracker.hasActiveAnimations && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _updatePositions();
    // Stop ticker if no active animations
    if (!widget.positionTracker.hasActiveAnimations) {
      _ticker.stop();
    }
  }

  void _updatePositions() {
    final newPositions = <String, LatLng>{};
    for (final vendorId in widget.positionTracker.trackedVendorIds) {
      newPositions[vendorId] = widget.positionTracker.getPosition(vendorId);
    }

    if (mounted) {
      setState(() {
        _currentPositions = newPositions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_currentPositions);
  }
}
