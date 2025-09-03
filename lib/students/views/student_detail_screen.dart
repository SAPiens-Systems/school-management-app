// import 'package:flutter/material.dart';
// import 'package:projects/core/constants/app_colors.dart';
// import 'package:projects/core/constants/app_styles.dart';
// import 'package:projects/students/models/student_model.dart';

// class StudentDetailScreen extends StatelessWidget {
//   final Student student;

//   const StudentDetailScreen({Key? key, required this.student})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(student.name),
//         backgroundColor: AppColors.primary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildProfileHeader(),
//             const SizedBox(height: 32),

//             _buildSectionHeader('Personal Information'),
//             _buildInfoRow('Student ID', student.studentId),
//             _buildInfoRow('Name', student.name),
//             _buildInfoRow('Age', '${student.age} years'),
//             _buildInfoRow('Date of Birth', _formatDate(student.dateOfBirth)),
//             _buildInfoRow(
//               'Class',
//               '${student.studentClass} - ${student.section}',
//             ),

//             const SizedBox(height: 24),

//             _buildSectionHeader('Contact Information'),
//             _buildInfoRow('Parent Email', student.parentEmail),
//             _buildInfoRow('Parent Mobile', student.parentMobile),
//             _buildInfoRow('Address', student.address),

//             const SizedBox(height: 24),

//             _buildSectionHeader('System Information'),
//             _buildInfoRow('School ID', student.schoolId),
//             _buildInfoRow('Status', student.status),
//             _buildInfoRow('Created', _formatDateTime(student.createdAt)),
//             _buildInfoRow('Created By', student.createdBy),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     return Center(
//       child: Column(
//         children: [
//           Container(
//             width: 100,
//             height: 100,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               shape: BoxShape.circle,
//               border: Border.all(color: AppColors.primary, width: 2),
//             ),
//             child: Icon(Icons.person, size: 50, color: AppColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             student.name,
//             style: AppStyles.headline1.copyWith(fontSize: 24),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Class ${student.studentClass} - ${student.section}',
//             style: AppStyles.bodyText1.copyWith(
//               color: AppColors.textSecondary,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: student.status == 'Active'
//                   ? AppColors.success.withOpacity(0.1)
//                   : AppColors.error.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Text(
//               student.status,
//               style: TextStyle(
//                 color: student.status == 'Active'
//                     ? AppColors.success
//                     : AppColors.error,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: AppStyles.headline1.copyWith(
//         fontSize: 18,
//         color: AppColors.primary,
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: AppStyles.bodyText1.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//           Expanded(child: Text(value, style: AppStyles.bodyText1)),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   String _formatDateTime(DateTime date) {
//     return '${_formatDate(date)} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }
