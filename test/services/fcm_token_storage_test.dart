import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FCM Token Storage', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('storeFcmToken', () {
      test('stores FCM token as subcollection document', () async {
        const userId = 'user_123';
        const token = 'fcm_token_abc123';
        const platform = 'android';

        // Store token
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'platform': platform,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Verify
        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .get();

        expect(tokenDoc.exists, true);
        expect(tokenDoc['token'], token);
        expect(tokenDoc['platform'], platform);
      });

      test('stores multiple tokens for same user (multi-device)', () async {
        const userId = 'user_123';
        const token1 = 'fcm_token_device1';
        const token2 = 'fcm_token_device2';

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token1)
            .set({'token': token1, 'platform': 'android'});

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token2)
            .set({'token': token2, 'platform': 'ios'});

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();

        expect(snapshot.docs.length, 2);
      });

      test('updates existing token with merge', () async {
        const userId = 'user_123';
        const token = 'fcm_token_abc123';

        // Store initial
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'platform': 'android',
          'deviceModel': 'Pixel 5',
        });

        // Update with merge
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .get();

        // Original fields preserved
        expect(tokenDoc['token'], token);
        expect(tokenDoc['platform'], 'android');
        expect(tokenDoc['deviceModel'], 'Pixel 5');
        // New field added
        expect(tokenDoc['lastUpdatedAt'], isNotNull);
      });
    });

    group('removeFcmToken', () {
      test('removes single token on logout', () async {
        const userId = 'user_123';
        const token = 'fcm_token_abc123';

        // Store token
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({'token': token, 'platform': 'android'});

        // Remove token
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .delete();

        // Verify deleted
        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .get();

        expect(tokenDoc.exists, false);
      });

      test('removes only specified token, keeps others', () async {
        const userId = 'user_123';
        const token1 = 'fcm_token_device1';
        const token2 = 'fcm_token_device2';

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token1)
            .set({'token': token1, 'platform': 'android'});

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token2)
            .set({'token': token2, 'platform': 'ios'});

        // Remove only token1
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token1)
            .delete();

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();

        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first['token'], token2);
      });
    });

    group('removeAllFcmTokens', () {
      test('removes all tokens for user using batch', () async {
        const userId = 'user_123';

        // Store multiple tokens
        for (var i = 0; i < 5; i++) {
          await fakeFirestore
              .collection('users')
              .doc(userId)
              .collection('fcm_tokens')
              .doc('token_$i')
              .set({'token': 'token_$i', 'platform': 'android'});
        }

        // Verify tokens exist
        var snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();
        expect(snapshot.docs.length, 5);

        // Remove all using batch
        final batch = fakeFirestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Verify all deleted
        snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();
        expect(snapshot.docs.length, 0);
      });
    });

    group('getUserFcmTokens', () {
      test('retrieves all tokens for a user', () async {
        const userId = 'user_123';
        final expectedTokens = ['token_1', 'token_2', 'token_3'];

        for (final token in expectedTokens) {
          await fakeFirestore
              .collection('users')
              .doc(userId)
              .collection('fcm_tokens')
              .doc(token)
              .set({'token': token, 'platform': 'android'});
        }

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();

        final tokens =
            snapshot.docs.map((doc) => doc['token'] as String).toList();

        expect(tokens, containsAll(expectedTokens));
      });

      test('returns empty list for user with no tokens', () async {
        const userId = 'user_with_no_tokens';

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();

        expect(snapshot.docs.length, 0);
      });
    });

    group('Token data structure', () {
      test('stores required fields: token and platform', () async {
        const userId = 'user_123';
        const token = 'fcm_token_abc';

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'platform': 'ios',
        });

        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .get();

        expect(tokenDoc.data()!.containsKey('token'), true);
        expect(tokenDoc.data()!.containsKey('platform'), true);
      });

      test('stores optional fields: deviceModel, timestamps', () async {
        const userId = 'user_123';
        const token = 'fcm_token_abc';
        final now = DateTime.now();

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'platform': 'android',
          'deviceModel': 'Samsung Galaxy S21',
          'createdAt': now.toIso8601String(),
          'lastUpdatedAt': now.toIso8601String(),
        });

        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .get();

        expect(tokenDoc['deviceModel'], 'Samsung Galaxy S21');
        expect(tokenDoc['createdAt'], isNotNull);
        expect(tokenDoc['lastUpdatedAt'], isNotNull);
      });
    });

    group('Token refresh handling', () {
      test('old token removed when new token stored', () async {
        const userId = 'user_123';
        const oldToken = 'old_fcm_token';
        const newToken = 'new_fcm_token';

        // Store old token
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(oldToken)
            .set({'token': oldToken, 'platform': 'android'});

        // Simulate token refresh: remove old, add new
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(oldToken)
            .delete();

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(newToken)
            .set({'token': newToken, 'platform': 'android'});

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .get();

        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first['token'], newToken);
      });
    });
  });
}
