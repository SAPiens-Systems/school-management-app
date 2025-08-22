// import 'package:flutter/material.dart';
// import 'package:projects/core/constants/app_colors.dart';
// import 'package:projects/core/constants/app_styles.dart';
// import 'package:projects/students/controllers/student_controller.dart';
// import 'package:projects/students/models/student_model.dart';
// import 'package:projects/students/views/student_detail_screen.dart';
// import 'package:projects/students/views/student_form_screen.dart';
// import 'package:projects/students/widgets/student_card.dart';
// import 'package:projects/students/widgets/student_search_delegate.dart';
// import 'package:provider/provider.dart';

// class StudentListScreen extends StatefulWidget {
//   const StudentListScreen({Key? key}) : super(key: key);

//   @override
//   State<StudentListScreen> createState() => _StudentListScreenState();
// }

// class _StudentListScreenState extends State<StudentListScreen>
//     with WidgetsBindingObserver {
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoadingMore = false;
//   bool _initialDataLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _setupScrollListener();
//     Future.microtask(() => _initializeData());
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_initialDataLoaded) {
//       _initializeData();
//     }
//   }

//   Future<void> _initializeData() async {
//     if (!mounted) return;

//     final controller = context.read<StudentController>();
//     if (controller.students.isEmpty && !controller.isLoading) {
//       await controller.loadStudents(refresh: true);
//     }
//   }

//   void _setupScrollListener() {
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels ==
//           _scrollController.position.maxScrollExtent) {
//         _loadMoreStudents();
//       }
//     });
//   }

//   Future<void> _loadMoreStudents() async {
//     if (_isLoadingMore) return;

//     final controller = context.read<StudentController>();
//     if (!controller.hasMore || controller.isLoading) return;

//     setState(() => _isLoadingMore = true);
//     await controller.loadStudents();
//     if (mounted) {
//       setState(() => _isLoadingMore = false);
//     }
//   }

//   Future<void> _refreshStudents() async {
//     final controller = context.read<StudentController>();
//     await controller.loadStudents(refresh: true);
//   }

//   void _navigateToAddStudent() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentFormScreen(),
//         fullscreenDialog: true,
//       ),
//     );
//   }

//   void _showSearch() {
//     showSearch(
//       context: context,
//       delegate: StudentSearchDelegate(
//         studentController: context.read<StudentController>(),
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Students'),
//         backgroundColor: AppColors.primary,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: _showSearch,
//             tooltip: 'Search students',
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _refreshStudents,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Consumer<StudentController>(
//         builder: (context, controller, child) {
//           if (controller.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Error loading students', style: AppStyles.bodyText1),
//                   const SizedBox(height: 8),
//                   Text(
//                     controller.error!,
//                     textAlign: TextAlign.center,
//                     style: AppStyles.bodyText1.copyWith(color: AppColors.error),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _refreshStudents,
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           if (controller.isLoading && controller.students.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (controller.students.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.people_outline,
//                     size: 64,
//                     color: Colors.grey,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No students found',
//                     style: AppStyles.headline1.copyWith(fontSize: 20),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Add your first student to get started',
//                     style: AppStyles.bodyText1.copyWith(
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: _refreshStudents,
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: controller.students.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == controller.students.length) {
//                   return _buildLoadingFooter(controller);
//                 }

//                 final student = controller.students[index];
//                 return StudentCard(
//                   student: student,
//                   onTap: () => _navigateToStudentDetail(student),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _navigateToAddStudent,
//         backgroundColor: AppColors.primary,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildLoadingFooter(StudentController controller) {
//     if (!controller.hasMore) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 16),
//         child: Text(
//           'No more students',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return _isLoadingMore
//         ? const Padding(
//             padding: EdgeInsets.symmetric(vertical: 16),
//             child: Center(child: CircularProgressIndicator()),
//           )
//         : Container();
//   }

//   void _navigateToStudentDetail(Student student) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)),
//     );
//   }
// }
