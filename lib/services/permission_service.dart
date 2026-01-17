import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class PermissionService {

  /// Check if all location permissions are granted
  Future<bool> hasLocationPermissions() async {
    final locationStatus = await Permission.location.status;
    final backgroundStatus = await Permission.locationAlways.status;

    return locationStatus.isGranted && backgroundStatus.isGranted;
  }

  /// Request all required location permissions with rationale dialogs
  /// Returns true if all permissions granted, false otherwise
  Future<bool> requestLocationPermissions(BuildContext context) async {
    // Step 1: Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      if (!context.mounted) return false;
      final shouldOpenSettings = await _showLocationServiceDialog(context);
      if (shouldOpenSettings) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    // Step 2: Request foreground location permission
    PermissionStatus locationStatus = await Permission.location.status;

    if (locationStatus.isDenied) {
      // Show rationale before requesting
      if (!context.mounted) return false;
      final shouldRequest = await _showForegroundRationaleDialog(context);
      if (!shouldRequest) return false;

      locationStatus = await Permission.location.request();
    }

    if (locationStatus.isPermanentlyDenied) {
      // User permanently denied - must go to settings
      if (!context.mounted) return false;
      await _showSettingsDialog(context, 'Location');
      return false;
    }

    if (!locationStatus.isGranted) {
      return false;
    }

    // Step 3: Request background location permission (Android 10+)
    PermissionStatus backgroundStatus = await Permission.locationAlways.status;

    if (backgroundStatus.isDenied) {
      // Show rationale for background location
      if (!context.mounted) return false;
      final shouldRequest = await _showBackgroundRationaleDialog(context);
      if (!shouldRequest) return false;

      backgroundStatus = await Permission.locationAlways.request();
    }

    if (backgroundStatus.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(context, 'Background Location');
      return false;
    }

    return backgroundStatus.isGranted;
  }

  Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are required for customers to find you. '
          'Please enable location services in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showForegroundRationaleDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs your location so customers can find your food stall. '
          'Your location is only shared when you set your status to "Open".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showBackgroundRationaleDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To keep showing your location to customers even when the app is '
          'minimized, please select "Allow all the time" on the next screen.\n\n'
          'This ensures customers can find you even if you\'re not looking at the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showSettingsDialog(BuildContext context, String permissionName) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'You have permanently denied $permissionName permission. '
          'Please enable it in app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
