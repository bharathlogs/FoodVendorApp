import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_vendor_app/services/location_queue_service.dart';

void main() {
  group('LocationQueueService', () {
    late LocationQueueService queueService;

    setUp(() async {
      // Set up mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      queueService = LocationQueueService();
      await queueService.init();
    });

    test('should start with empty queue', () async {
      expect(queueService.queueLength, 0);
      expect(queueService.isEmpty, true);
    });

    test('should enqueue location updates', () async {
      await queueService.enqueue(12.9716, 77.5946, DateTime.now());
      expect(queueService.queueLength, 1);
      expect(queueService.isEmpty, false);

      await queueService.enqueue(12.9720, 77.5950, DateTime.now());
      expect(queueService.queueLength, 2);
    });

    test('should return all queued items', () async {
      final timestamp1 = DateTime(2024, 1, 1, 12, 0);
      final timestamp2 = DateTime(2024, 1, 1, 12, 5);

      await queueService.enqueue(12.9716, 77.5946, timestamp1);
      await queueService.enqueue(12.9720, 77.5950, timestamp2);

      final all = await queueService.getAll();
      expect(all.length, 2);
      expect(all[0]['latitude'], 12.9716);
      expect(all[0]['longitude'], 77.5946);
      expect(all[1]['latitude'], 12.9720);
      expect(all[1]['longitude'], 77.5950);
    });

    test('should return most recent update', () async {
      await queueService.enqueue(12.9716, 77.5946, DateTime.now());
      await queueService.enqueue(12.9720, 77.5950, DateTime.now());

      final mostRecent = queueService.mostRecent;
      expect(mostRecent, isNotNull);
      expect(mostRecent!['latitude'], 12.9720);
      expect(mostRecent['longitude'], 77.5950);
    });

    test('should return null for mostRecent when queue is empty', () {
      expect(queueService.mostRecent, isNull);
    });

    test('should clear all queued updates', () async {
      await queueService.enqueue(12.9716, 77.5946, DateTime.now());
      await queueService.enqueue(12.9720, 77.5950, DateTime.now());
      expect(queueService.queueLength, 2);

      await queueService.clear();
      expect(queueService.queueLength, 0);
      expect(queueService.isEmpty, true);
    });

    test('should limit queue size to 100 entries', () async {
      // Add 105 entries
      for (int i = 0; i < 105; i++) {
        await queueService.enqueue(12.0 + i * 0.001, 77.0 + i * 0.001, DateTime.now());
      }

      // Should be capped at 100
      expect(queueService.queueLength, 100);

      // Should keep most recent (last 100)
      final all = await queueService.getAll();
      // First item should be the 6th enqueued (index 5), not the 1st
      expect(all[0]['latitude'], closeTo(12.005, 0.0001));
    });

    test('should persist queue across reinitializations', () async {
      await queueService.enqueue(12.9716, 77.5946, DateTime.now());
      await queueService.enqueue(12.9720, 77.5950, DateTime.now());

      // Create new instance and reinitialize
      final newQueueService = LocationQueueService();
      await newQueueService.init();

      expect(newQueueService.queueLength, 2);
      final all = await newQueueService.getAll();
      expect(all[0]['latitude'], 12.9716);
    });

    test('should store timestamp in ISO8601 format', () async {
      final timestamp = DateTime(2024, 6, 15, 10, 30, 45);
      await queueService.enqueue(12.9716, 77.5946, timestamp);

      final all = await queueService.getAll();
      expect(all[0]['timestamp'], timestamp.toIso8601String());
    });
  });
}
