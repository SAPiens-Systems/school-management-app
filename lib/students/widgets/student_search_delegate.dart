// import 'package:flutter/material.dart';
// import 'package:projects/core/constants/app_colors.dart';
// import 'package:projects/students/controllers/student_controller.dart';
// import 'package:projects/students/models/student_model.dart';

// class StudentSearchDelegate extends SearchDelegate {
//   final StudentController studentController;

//   StudentSearchDelegate({required this.studentController});

//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       IconButton(
//         icon: const Icon(Icons.clear),
//         onPressed: () {
//           if (query.isEmpty) {
//             close(context, null);
//           } else {
//             query = '';
//           }
//         },
//       ),
//     ];
//   }

//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, null),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     return _buildSearchResults();
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return _buildSearchResults();
//   }

//   Widget _buildSearchResults() {
//     if (query.length < 2) {
//       return const Center(child: Text('Enter at least 2 characters to search'));
//     }

//     return FutureBuilder<List<Student>>(
//       future: studentController.searchStudents(query),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final results = snapshot.data ?? [];

//         if (results.isEmpty) {
//           return const Center(child: Text('No students found'));
//         }

//         return ListView.builder(
//           itemCount: results.length,
//           itemBuilder: (context, index) {
//             final student = results[index];
//             return ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: AppColors.primary.withOpacity(0.1),
//                 child: Icon(Icons.person, color: AppColors.primary),
//               ),
//               title: Text(student.name),
//               subtitle: Text('Grade ${student.grade} • ${student.section}'),
//               onTap: () {
//                 close(context, student);
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   ThemeData appBarTheme(BuildContext context) {
//     final theme = Theme.of(context);
//     return theme.copyWith(
//       inputDecorationTheme: InputDecorationTheme(
//         hintStyle: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
//         border: InputBorder.none,
//       ),
//     );
//   }
// }
