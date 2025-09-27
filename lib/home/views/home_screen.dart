import 'package:flutter/material.dart';
import 'package:projects/home/views/assigment_screen.dart';
import 'package:projects/home/views/attendance_screen.dart';
import 'package:projects/auth/views/admin_approval_screen.dart';
import 'package:projects/auth/views/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/home/views/announcement_creation_screen.dart';
import 'package:projects/home/views/bulk_upload_screen.dart';
import 'package:projects/home/views/class_management_screen.dart';
import 'package:projects/home/views/my_details_screen.dart';
import 'package:projects/home/views/students_directory_screen.dart';
import 'package:projects/students/controllers/student_creation_controller.dart';

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
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadUserData(user);
  }

  Future<void> _loadUserData(User? user) async {
    try {
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _userData = userDoc.exists ? userDoc.data() : null;
          _isLoading = false;
        });
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
      body: _buildDashboard(userRole, schoolId, userName),
    );
  }

  Widget _buildDashboard(String role, String schoolId, String userName) {
    switch (role) {
      case 'admin':
        return _buildAdminDashboard(schoolId, role, user, userName);
      case 'teacher':
        return _buildTeacherDashboard(schoolId, role, user, userName);
      case 'student':
        return _buildParentDashboard(schoolId, role, user);
      default:
        return _buildDummyDashboard();
    }
  }

  Widget _buildAdminDashboard(
    String schoolId,
    String role,
    User? user,
    String userName,
  ) {
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
                DashboardCard(
                  icon: Icons.people,
                  title: 'User Approvals',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminApprovalScreen(),
                    ),
                  ),
                ),

                DashboardCard(
                  icon: Icons.person_add,
                  title: 'Create Student',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentCreationScreen(schoolId: schoolId),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.announcement,
                  title: 'Create Announcement',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementsScreen(schoolId: schoolId),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.person,
                  title: 'Students',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDirectoryScreen(
                        schoolId: schoolId,
                        userRole: role,
                      ),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.class_,
                  title: 'Class Management',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassListScreen(
                        schoolId: schoolId,
                        userRole: role,
                        userId: user!.uid,
                      ),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.upload_file,
                  title: 'Upload Students',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BulkUploadScreen(schoolId: schoolId),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.announcement,
                  title: 'Assignments',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentListScreen(
                        schoolId: schoolId,
                        userRole: role,
                        userId: user!.uid,
                        userEmail: user.email!,
                        userName: userName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDashboard(
    String schoolId,
    String role,
    User? user,
    String userName,
  ) {
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
                //Announcements Screen
                DashboardCard(
                  icon: Icons.announcement,
                  title: 'Announcements',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementsScreen(schoolId: schoolId),
                    ),
                  ),
                ),
                //Students Screen
                DashboardCard(
                  icon: Icons.person,
                  title: 'Students',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDirectoryScreen(
                        schoolId: schoolId,
                        userRole: role,
                      ),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.person,
                  title: 'Class Management',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassListScreen(
                        schoolId: schoolId,
                        userRole: role,
                        userId: user!.uid,
                      ),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.check_outlined,
                  title: 'Mark Attendance',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaffAttendanceScreen(),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.check_outlined,
                  title: 'My Details',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyDetailsScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.announcement,
                  title: 'Create Assignments',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentListScreen(
                        schoolId: schoolId,
                        userRole: role,
                        userId: user!.uid,
                        userEmail: user.email!,
                        userName: userName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyDashboard() {
    return Padding(padding: const EdgeInsets.all(16.0));
  }

  Widget _buildParentDashboard(String schoolId, String role, User? user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent Dashboard - $schoolId',
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
                //Announcements Screen
                DashboardCard(
                  icon: Icons.announcement,
                  title: 'My Details',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementsScreen(schoolId: schoolId),
                    ),
                  ),
                ),
                //Students Screen
                DashboardCard(
                  icon: Icons.person,
                  title: 'Announcements',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDirectoryScreen(
                        schoolId: schoolId,
                        userRole: role,
                      ),
                    ),
                  ),
                ),
                DashboardCard(
                  icon: Icons.person,
                  title: 'Class Management',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassListScreen(
                        schoolId: schoolId,
                        userRole: role,
                        userId: user!.uid,
                      ),
                    ),
                  ),
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

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color; // Optional custom color

  const DashboardCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color cardColor =
        color ??
        theme.colorScheme.primary; // Use primary color if none provided
    final Color iconColor = theme.colorScheme.onPrimary;

    return Semantics(
      button: true,
      label: 'Button to $title',
      child: Card(
        elevation: 4,
        // Using a custom shape for rounded corners
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12), // Match the card's shape
          onTap: onTap,
          // Added a slight scale animation on tap
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with a background for better hierarchy
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
