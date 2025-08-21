import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/auth/repositories/auth_repository.dart';
import 'package:provider/provider.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _currentAdminSchoolId;

  @override
  void initState() {
    super.initState();
    _loadAdminSchoolId();
  }

  Future<void> _loadAdminSchoolId() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get the admin's school ID from their user document
        final userDoc = await _firestore
            .collectionGroup('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          setState(() {
            _currentAdminSchoolId = userData['schoolId'];
          });
        }
      }
    } catch (e) {
      print('Error loading admin school: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String userId, String schoolId) async {
    setState(() => _isLoading = true);
    try {
      // 1. Update user status to approved
      await _firestore
          .collection('school_admins')
          .doc('${schoolId}_admins')
          .collection('users')
          .doc(userId)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': _auth.currentUser!.uid,
          });

      // 2. Enable user account in Auth
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      await authRepo.enableUser(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approval failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectUser(String userId, String schoolId) async {
    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('school_admins')
          .doc('${schoolId}_admins')
          .collection('users')
          .doc(userId)
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': _auth.currentUser!.uid,
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User rejected')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rejection failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentAdminSchoolId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentAdminSchoolId == null) {
      return const Scaffold(
        body: Center(child: Text('Unable to load school information')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Approvals - ${_currentAdminSchoolId!}'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('school_admins')
            .doc('${_currentAdminSchoolId!}_admins') // ONLY current school
            .collection('users')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No pending approvals for your school'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final user = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(user['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? 'No Email'),
                      Text('Role: ${user['role']}'),
                      Text('Applied on: ${_formatDate(user['createdAt'])}'),
                    ],
                  ),
                  trailing: _isLoading
                      ? const CircularProgressIndicator()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _approveUser(doc.id, _currentAdminSchoolId!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _rejectUser(doc.id, _currentAdminSchoolId!),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'Invalid date';
  }
}
