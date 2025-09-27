import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/auth/views/admin_user_model.dart';
import 'package:projects/core/exceptions/auth_exceptions.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createPendingAdminUser(AdminUser user) async {
    try {
      //Stores userdata in school collection -> SchoolId
      await _firestore
          .collection('schools')
          .doc(user.schoolId)
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
      //Creates new Users collecion
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw AuthException(message: 'Failed to create user record');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserStatus(
    String uid,
  ) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw AuthException(message: 'Failed to fetch user status');
    }
  }

  Future<void> approveUser(String uid, String schoolId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('users')
          .doc(uid)
          .update({'status': 'approved'});
    } catch (e) {
      throw AuthException(message: 'Failed to approve user');
    }
  }
}
