import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/auth/views/admin_user_model.dart';
import 'package:projects/core/exceptions/auth_exceptions.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createPendingAdminUser(AdminUser user) async {
    try {
      await _firestore
          .collection('school_admins')
          .doc('${user.schoolId}_admins')
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw AuthException(message: 'Failed to create user record');
    }
  }

  Future<Map<String, dynamic>?> getUserStatus(String uid) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
    } catch (e) {
      throw AuthException(message: 'Failed to fetch user status');
    }
  }

  Future<void> approveUser(String uid, String schoolId) async {
    try {
      await _firestore
          .collection('school_admins')
          .doc('${schoolId}_admins')
          .collection('users')
          .doc(uid)
          .update({'status': 'approved'});
    } catch (e) {
      throw AuthException(message: 'Failed to approve user');
    }
  }
}
