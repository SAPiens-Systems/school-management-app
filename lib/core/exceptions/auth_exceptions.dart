import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String message;

  const AuthException({this.message = 'An authentication error occurred'});

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(message: 'No account found for this email');
      case 'wrong-password':
        return const AuthException(message: 'Incorrect password');
      case 'email-already-in-use':
        return const AuthException(message: 'Email already in use');
      case 'invalid-email':
        return const AuthException(message: 'Invalid email address');
      case 'operation-not-allowed':
        return const AuthException(message: 'Operation not allowed');
      case 'weak-password':
        return const AuthException(message: 'Password is too weak');
      case 'user-disabled':
        return const AuthException(message: 'This account has been disabled');
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many requests. Please try again later',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Please check your connection',
        );
      default:
        return const AuthException();
    }
  }

  @override
  String toString() => message;
}
