import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/core/exceptions/auth_exceptions.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<void> updateUserDisabledStatus(String uid, bool disabled) async {
    try {
      await _firestore.collection('user_status').doc(uid).set({
        'disabled': disabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException(message: 'Failed to update user status');
    }
  }

  Future<bool> isUserDisabled(String uid) async {
    try {
      final doc = await _firestore.collection('user_status').doc(uid).get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final disabled = data['disabled'];
      return disabled is bool ? disabled : false;
    } catch (e) {
      throw AuthException(message: 'Failed to check user status');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      //await _firebaseAuth.setPersistence(Persistence.LOCAL);
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<void> enableUser(String uid) async {
    try {
      await _firestore.collection('user_status').doc(uid).set({
        'disabled': false,
        'enabledAt': FieldValue.serverTimestamp(),
        'status': 'approved',
      });
    } catch (e) {
      throw AuthException(message: 'Failed to enable user');
    }
  }

  Future<void> disableUser(String uid) async {
    try {
      await _firestore.collection('user_status').doc(uid).set({
        'disabled': true,
        'disabledAt': FieldValue.serverTimestamp(),
        'status': 'approved',
      });
    } catch (e) {
      throw AuthException(message: 'Failed to disable user');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
