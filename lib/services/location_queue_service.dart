import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for queuing location updates when offline
/// Uses SharedPreferences for persistence across app restarts
class LocationQueueService {
  static const String _queueKey = 'location_queue';
  static const int _maxQueueSize = 100; // Prevent unbounded growth

  SharedPreferences? _prefs;
  List<Map<String, dynamic>> _queue = [];

  /// Initialize the queue service and load any persisted data
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueue();
  }

  /// Load queue from SharedPreferences
  Future<void> _loadQueue() async {
    final String? queueJson = _prefs?.getString(_queueKey);
    if (queueJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _queue = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        // If decode fails, start with empty queue
        _queue = [];
      }
    }
  }

  /// Save queue to SharedPreferences
  Future<void> _saveQueue() async {
    final String queueJson = jsonEncode(_queue);
    await _prefs?.setString(_queueKey, queueJson);
  }

  /// Add a location update to the queue
  Future<void> enqueue(double latitude, double longitude, DateTime timestamp) async {
    _queue.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    });

    // Trim if too large (keep most recent)
    if (_queue.length > _maxQueueSize) {
      _queue.removeRange(0, _queue.length - _maxQueueSize);
    }

    await _saveQueue();
  }

  /// Get all queued updates
  Future<List<Map<String, dynamic>>> getAll() async {
    return List.from(_queue);
  }

  /// Get the number of queued updates
  int get queueLength => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Clear all queued updates
  Future<void> clear() async {
    _queue.clear();
    await _prefs?.remove(_queueKey);
  }

  /// Get the most recent queued update (if any)
  Map<String, dynamic>? get mostRecent {
    if (_queue.isEmpty) return null;
    return _queue.last;
  }
}
