import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  /// Show user-friendly error message
  static void showError(BuildContext context, dynamic error) {
    String message = _getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error.code);
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  static String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to do this.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Requested data not found.';
      default:
        return 'Database error. Please try again.';
    }
  }
}
