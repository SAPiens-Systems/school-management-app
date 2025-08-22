import 'package:flutter/material.dart';
import 'package:projects/auth/repositories/auth_repository.dart';
import 'package:projects/auth/repositories/user_repository.dart';
import 'package:projects/auth/views/admin_user_model.dart';
import 'package:projects/core/exceptions/auth_exceptions.dart';

class AuthController with ChangeNotifier {
  AuthRepository _authRepo;
  UserRepository _userRepo;

  void initialize({
    required AuthRepository authRepo,
    required UserRepository userRepo,
  }) {
    _authRepo = authRepo;
    _userRepo = userRepo;
  }

  AuthController({
    required AuthRepository authRepo,
    required UserRepository userRepo,
  }) : _authRepo = authRepo,
       _userRepo = userRepo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> registerWithApproval({
    required String email,
    required String password,
    required String name,
    required String schoolId,
    required String role,
  }) async {
    try {
      _isLoading = true;
      safeNotifyListeners();

      // Create user in Firebase Auth
      final userCredential = await _authRepo.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Store user in Firestore with pending status
      await _userRepo.createPendingAdminUser(
        AdminUser(
          uid: uid,
          name: name,
          email: email,
          schoolId: schoolId,
          role: role,
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      );

      // Disable the user until approved
      await _authRepo.disableUser(uid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      if (mounted) safeNotifyListeners(); // Check mounted before notifying

      final userCredential = await _authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userData = await _userRepo.getUserStatus(uid);

      if (userData == null) {
        await _authRepo.signOut();
        throw AuthException(message: 'User account not found in database');
      }

      if (userData['status'] != 'approved') {
        await _authRepo.signOut();
        throw AuthException(message: 'Account pending admin approval');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      if (mounted) safeNotifyListeners(); // Check mounted before notifying
    }
  }

  bool _mounted = true;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }
}
