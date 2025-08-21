import 'package:flutter/material.dart';
import 'package:projects/auth/views/admin_approval_screen.dart';
import 'package:projects/auth/views/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collectionGroup('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          setState(() {
            _userData = userDoc.docs.first.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userRole = _userData?['role'] ?? 'teacher';
    final userName = _userData?['name'] ?? 'User';
    final schoolId = _userData?['schoolId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildDashboard(userRole, schoolId),
    );
  }

  Widget _buildDashboard(String role, String schoolId) {
    switch (role) {
      case 'admin':
        return _buildAdminDashboard(schoolId);
      case 'teacher':
        return _buildTeacherDashboard(schoolId);
      default:
        return _buildTeacherDashboard(schoolId);
    }
  }

  Widget _buildAdminDashboard(String schoolId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard - $schoolId',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              children: [
                _DashboardCard(
                  icon: Icons.people,
                  title: 'User Approvals',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminApprovalScreen(),
                    ),
                  ),
                ),
                _DashboardCard(
                  icon: Icons.school,
                  title: 'Manage Students',
                  onTap: () => _showComingSoon('Student Management'),
                ),
                _DashboardCard(
                  icon: Icons.assignment,
                  title: 'Reports',
                  onTap: () => _showComingSoon('Reports'),
                ),
                _DashboardCard(
                  icon: Icons.settings,
                  title: 'School Settings',
                  onTap: () => _showComingSoon('School Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDashboard(String schoolId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Dashboard - $schoolId',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              children: [
                _DashboardCard(
                  icon: Icons.people,
                  title: 'My Students',
                  onTap: () => _showComingSoon('My Students'),
                ),
                _DashboardCard(
                  icon: Icons.assignment,
                  title: 'Attendance',
                  onTap: () => _showComingSoon('Attendance'),
                ),
                _DashboardCard(
                  icon: Icons.grade,
                  title: 'Grades',
                  onTap: () => _showComingSoon('Grades'),
                ),
                _DashboardCard(
                  icon: Icons.calendar_today,
                  title: 'Schedule',
                  onTap: () => _showComingSoon('Schedule'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature - Coming Soon!')));
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
