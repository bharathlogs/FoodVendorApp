import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BatteryOptimizationHelper {
  /// Check and request battery optimization exemption
  /// This helps prevent Android from killing our service
  static Future<void> requestBatteryOptimizationExemption(
    BuildContext context,
  ) async {
    // Check if already exempted
    final isIgnoring =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    if (!isIgnoring) {
      // Show explanation first
      if (!context.mounted) return;

      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To ensure your location is shared reliably while the app is '
            'in the background, please disable battery optimization for this app.\n\n'
            'This helps customers find you even when you\'re serving other customers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disable Optimization'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  /// Check if battery optimization is already disabled
  static Future<bool> isBatteryOptimizationDisabled() async {
    return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  /// Open device battery settings (for troubleshooting)
  static Future<void> openBatterySettings() async {
    await FlutterForegroundTask.openSystemAlertWindowSettings();
  }
}
