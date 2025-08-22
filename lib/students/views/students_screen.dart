import 'package:flutter/material.dart';
import 'package:projects/auth/controllers/auth_controller.dart';
import 'package:projects/core/constants/app_colors.dart';
import 'package:projects/core/constants/app_styles.dart';
import 'package:projects/students/controllers/student_controller.dart';
import 'package:projects/students/models/student_model.dart';
import 'package:projects/students/views/student_detail_screen.dart';
import 'package:projects/students/views/student_form_screen.dart';
import 'package:projects/students/widgets/student_card.dart';
import 'package:provider/provider.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _initializeData() {
    final controller = context.read<StudentController>();
    controller.loadStudents();
    controller.loadAvailableClasses();
  }

  void _navigateToAddStudent() {
    final authController = context.read<AuthController>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(
          schoolId: authController.currentUser?.schoolId ?? '',
          adminId: authController.currentUser?.uid ?? '',
        ),
      ),
    ).then((_) => context.read<StudentController>().loadStudents());
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final isAdmin = authController.currentUser?.role == 'admin';

    return Scaffold(
      appBar: SearchAppBar(
        title: 'Students',
        onSearch: (query) async {
          final results = await context
              .read<StudentController>()
              .searchStudents(query);
          // Implement search results display
        },
      ),
      body: Column(
        children: [
          const FilterChipRow(),
          Expanded(
            child: Consumer<StudentController>(
              builder: (context, controller, child) {
                if (controller.error != null) {
                  return _buildErrorState(controller);
                }

                if (controller.isLoading && controller.students.isEmpty) {
                  return _buildLoadingState();
                }

                if (controller.students.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildStudentList(controller);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToAddStudent,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildErrorState(StudentController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load students',
            style: AppStyles.headline1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error!,
            textAlign: TextAlign.center,
            style: AppStyles.bodyText1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.loadStudents,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text('Try Again', style: AppStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading students...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: AppStyles.headline1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first student to get started',
            style: AppStyles.bodyText1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(StudentController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadStudents(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: controller.students.length,
        itemBuilder: (context, index) {
          final student = controller.students[index];
          return StudentCard(
            student: student,
            onTap: () => _navigateToStudentDetail(student),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
