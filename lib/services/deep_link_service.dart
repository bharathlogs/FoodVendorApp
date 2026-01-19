import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';

/// Service for handling deep links and sharing functionality
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  /// Base URL for web links
  static const String webBaseUrl = 'https://foodfinder.app';

  /// Custom scheme for app links
  static const String customScheme = 'foodfinder';

  /// Stream controller for incoming deep links
  final _linkController = StreamController<DeepLinkData>.broadcast();

  /// Stream of incoming deep links
  Stream<DeepLinkData> get linkStream => _linkController.stream;

  /// Initialize deep link handling
  Future<DeepLinkData?> initialize() async {
    // Handle initial link (app launched from link)
    final initialUri = await _appLinks.getInitialLink();
    final initialData = initialUri != null ? _parseUri(initialUri) : null;

    // Listen for subsequent links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      final data = _parseUri(uri);
      if (data != null) {
        _linkController.add(data);
      }
    });

    return initialData;
  }

  /// Parse URI into structured deep link data
  DeepLinkData? _parseUri(Uri uri) {
    // Handle both custom scheme and https URLs
    // foodfinder://vendor/{vendorId}
    // https://foodfinder.app/vendor/{vendorId}

    final pathSegments = uri.pathSegments;

    if (pathSegments.isEmpty) return null;

    final type = pathSegments.first;

    switch (type) {
      case 'vendor':
        if (pathSegments.length >= 2) {
          return DeepLinkData(
            type: DeepLinkType.vendor,
            id: pathSegments[1],
            rawUri: uri,
          );
        }
        break;
      // Add more link types here as needed
      // case 'menu':
      // case 'order':
    }

    return null;
  }

  /// Generate a shareable link for a vendor
  static String generateVendorLink(String vendorId) {
    return '$webBaseUrl/vendor/$vendorId';
  }

  /// Generate a custom scheme link for a vendor
  static String generateVendorAppLink(String vendorId) {
    return '$customScheme://vendor/$vendorId';
  }

  /// Share a vendor with others
  static Future<void> shareVendor({
    required String vendorId,
    required String vendorName,
    String? description,
  }) async {
    final link = generateVendorLink(vendorId);

    String shareText = 'Check out $vendorName on Food Finder!';
    if (description != null && description.isNotEmpty) {
      shareText += '\n\n$description';
    }
    shareText += '\n\n$link';

    await Share.share(
      shareText,
      subject: vendorName,
    );
  }

  /// Share vendor with location context
  static Future<void> shareVendorWithLocation({
    required String vendorId,
    required String vendorName,
    String? description,
    double? distanceKm,
  }) async {
    final link = generateVendorLink(vendorId);

    String shareText = 'Check out $vendorName on Food Finder!';

    if (distanceKm != null) {
      final distanceStr = distanceKm < 1
          ? '${(distanceKm * 1000).round()}m'
          : '${distanceKm.toStringAsFixed(1)}km';
      shareText += ' They\'re $distanceStr away from me.';
    }

    if (description != null && description.isNotEmpty) {
      shareText += '\n\n$description';
    }

    shareText += '\n\n$link';

    await Share.share(
      shareText,
      subject: vendorName,
    );
  }

  /// Dispose resources
  void dispose() {
    _linkController.close();
  }
}

/// Types of deep links supported
enum DeepLinkType {
  vendor,
  // menu,
  // order,
}

/// Structured data from a parsed deep link
class DeepLinkData {
  final DeepLinkType type;
  final String id;
  final Uri rawUri;

  DeepLinkData({
    required this.type,
    required this.id,
    required this.rawUri,
  });

  @override
  String toString() => 'DeepLinkData(type: $type, id: $id)';
}
