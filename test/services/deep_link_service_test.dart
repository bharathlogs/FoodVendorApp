import 'package:flutter_test/flutter_test.dart';
import 'package:food_vendor_app/services/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    group('constants', () {
      test('webBaseUrl is correct', () {
        expect(DeepLinkService.webBaseUrl, 'https://foodfinder.app');
      });

      test('customScheme is correct', () {
        expect(DeepLinkService.customScheme, 'foodfinder');
      });
    });

    group('generateVendorLink', () {
      test('generates correct web URL for vendor', () {
        final link = DeepLinkService.generateVendorLink('vendor123');
        expect(link, 'https://foodfinder.app/vendor/vendor123');
      });

      test('generates link with complex vendor ID', () {
        final link = DeepLinkService.generateVendorLink('abc-123-xyz');
        expect(link, 'https://foodfinder.app/vendor/abc-123-xyz');
      });

      test('generates link with UUID vendor ID', () {
        final link = DeepLinkService.generateVendorLink(
            '550e8400-e29b-41d4-a716-446655440000');
        expect(link,
            'https://foodfinder.app/vendor/550e8400-e29b-41d4-a716-446655440000');
      });

      test('handles empty vendor ID', () {
        final link = DeepLinkService.generateVendorLink('');
        expect(link, 'https://foodfinder.app/vendor/');
      });
    });

    group('generateVendorAppLink', () {
      test('generates correct custom scheme URL for vendor', () {
        final link = DeepLinkService.generateVendorAppLink('vendor456');
        expect(link, 'foodfinder://vendor/vendor456');
      });

      test('generates app link with complex vendor ID', () {
        final link = DeepLinkService.generateVendorAppLink('test-vendor-789');
        expect(link, 'foodfinder://vendor/test-vendor-789');
      });
    });
  });

  group('DeepLinkType', () {
    test('contains vendor type', () {
      expect(DeepLinkType.values, contains(DeepLinkType.vendor));
    });

    test('has correct number of types', () {
      // Currently only vendor is implemented
      expect(DeepLinkType.values.length, 1);
    });
  });

  group('DeepLinkData', () {
    test('creates DeepLinkData with required fields', () {
      final uri = Uri.parse('foodfinder://vendor/vendor123');
      final data = DeepLinkData(
        type: DeepLinkType.vendor,
        id: 'vendor123',
        rawUri: uri,
      );

      expect(data.type, DeepLinkType.vendor);
      expect(data.id, 'vendor123');
      expect(data.rawUri, uri);
    });

    test('toString returns readable format', () {
      final uri = Uri.parse('https://foodfinder.app/vendor/abc');
      final data = DeepLinkData(
        type: DeepLinkType.vendor,
        id: 'abc',
        rawUri: uri,
      );

      expect(data.toString(), 'DeepLinkData(type: DeepLinkType.vendor, id: abc)');
    });

    test('stores raw URI for debugging', () {
      final uri = Uri.parse('foodfinder://vendor/test?param=value');
      final data = DeepLinkData(
        type: DeepLinkType.vendor,
        id: 'test',
        rawUri: uri,
      );

      expect(data.rawUri.queryParameters['param'], 'value');
    });
  });

  group('URI parsing logic', () {
    // Test the parsing logic used by the service

    DeepLinkData? parseUri(Uri uri) {
      final pathSegments = uri.pathSegments;

      // Handle custom scheme URLs where type is in the host
      // e.g., foodfinder://vendor/vendor456 has host='vendor', path=[vendor456]
      if (uri.scheme == 'foodfinder' && uri.host == 'vendor') {
        if (pathSegments.isNotEmpty) {
          return DeepLinkData(
            type: DeepLinkType.vendor,
            id: pathSegments.first,
            rawUri: uri,
          );
        }
        return null;
      }

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
      }

      return null;
    }

    test('parses HTTPS vendor URL correctly', () {
      final uri = Uri.parse('https://foodfinder.app/vendor/vendor123');
      final data = parseUri(uri);

      expect(data, isNotNull);
      expect(data!.type, DeepLinkType.vendor);
      expect(data.id, 'vendor123');
    });

    test('parses custom scheme vendor URL correctly', () {
      final uri = Uri.parse('foodfinder://vendor/vendor456');
      final data = parseUri(uri);

      expect(data, isNotNull);
      expect(data!.type, DeepLinkType.vendor);
      expect(data.id, 'vendor456');
    });

    test('returns null for empty path', () {
      final uri = Uri.parse('https://foodfinder.app/');
      final data = parseUri(uri);

      expect(data, isNull);
    });

    test('returns null for vendor path without ID', () {
      final uri = Uri.parse('https://foodfinder.app/vendor');
      final data = parseUri(uri);

      expect(data, isNull);
    });

    test('returns null for unknown path type', () {
      final uri = Uri.parse('https://foodfinder.app/unknown/123');
      final data = parseUri(uri);

      expect(data, isNull);
    });

    test('handles vendor URL with additional path segments', () {
      final uri = Uri.parse('https://foodfinder.app/vendor/abc/extra/path');
      final data = parseUri(uri);

      expect(data, isNotNull);
      expect(data!.id, 'abc');
    });

    test('handles vendor URL with query parameters', () {
      final uri = Uri.parse('https://foodfinder.app/vendor/test?source=share');
      final data = parseUri(uri);

      expect(data, isNotNull);
      expect(data!.id, 'test');
      expect(data.rawUri.queryParameters['source'], 'share');
    });
  });

  group('share text generation', () {
    // Test the share text formatting logic

    String generateShareText({
      required String vendorName,
      required String link,
      String? description,
      double? distanceKm,
    }) {
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

      return shareText;
    }

    test('generates basic share text', () {
      final text = generateShareText(
        vendorName: 'Taco Truck',
        link: 'https://foodfinder.app/vendor/123',
      );

      expect(text, contains('Check out Taco Truck on Food Finder!'));
      expect(text, contains('https://foodfinder.app/vendor/123'));
    });

    test('includes description when provided', () {
      final text = generateShareText(
        vendorName: 'Pizza Place',
        link: 'https://foodfinder.app/vendor/456',
        description: 'Best pizza in town!',
      );

      expect(text, contains('Best pizza in town!'));
    });

    test('does not include description when empty', () {
      final text = generateShareText(
        vendorName: 'Burger Joint',
        link: 'https://foodfinder.app/vendor/789',
        description: '',
      );

      expect(text.split('\n\n').length, 2); // Only header and link
    });

    test('formats distance in meters when less than 1km', () {
      final text = generateShareText(
        vendorName: 'Coffee Shop',
        link: 'https://foodfinder.app/vendor/abc',
        distanceKm: 0.5,
      );

      expect(text, contains('500m'));
      expect(text, contains('away'));
    });

    test('formats distance in km when 1km or more', () {
      final text = generateShareText(
        vendorName: 'Food Stall',
        link: 'https://foodfinder.app/vendor/def',
        distanceKm: 2.5,
      );

      expect(text, contains('2.5km'));
      expect(text, contains('away'));
    });

    test('includes both distance and description', () {
      final text = generateShareText(
        vendorName: 'Noodle House',
        link: 'https://foodfinder.app/vendor/ghi',
        description: 'Amazing ramen!',
        distanceKm: 1.2,
      );

      expect(text, contains('1.2km'));
      expect(text, contains('Amazing ramen!'));
    });
  });
}
