import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/services/firestore_service.dart';

// Pure unit tests for the error mapper — no Firebase initialization,
// emulator, or network access required (FirebaseException is a plain
// Dart class that can be constructed directly).
void main() {
  FirebaseException firestoreError(String code) => FirebaseException(
        plugin: 'cloud_firestore',
        code: code,
      );

  group('FirestoreService.describeError', () {
    test('permission-denied explains sign-in / rules requirement', () {
      final message = FirestoreService.describeError(
        firestoreError('permission-denied'),
      );

      expect(message, contains('permission'));
      expect(message, contains('signed in'));
    });

    test('unauthenticated asks the user to log in again', () {
      final message = FirestoreService.describeError(
        firestoreError('unauthenticated'),
      );

      expect(message.toLowerCase(), contains('log in'));
    });

    test('unavailable points to the internet connection', () {
      final message = FirestoreService.describeError(
        firestoreError('unavailable'),
      );

      expect(message.toLowerCase(), contains('internet'));
    });

    test('network-request-failed points to the internet connection', () {
      final message = FirestoreService.describeError(
        firestoreError('network-request-failed'),
      );

      expect(message.toLowerCase(), contains('internet'));
    });

    test('deadline-exceeded reports a timeout', () {
      final message = FirestoreService.describeError(
        firestoreError('deadline-exceeded'),
      );

      expect(message.toLowerCase(), contains('timed out'));
    });

    test('unknown codes still produce a friendly message with the code',
        () {
      final message = FirestoreService.describeError(
        firestoreError('some-new-code'),
      );

      expect(message, contains('some-new-code'));
      expect(message, isNot(contains('Exception')));
    });

    test('non-Firebase errors fall back to a generic friendly message', () {
      final message =
          FirestoreService.describeError(StateError('boom'));

      expect(message.toLowerCase(), contains('unexpected'));
    });
  });
}
