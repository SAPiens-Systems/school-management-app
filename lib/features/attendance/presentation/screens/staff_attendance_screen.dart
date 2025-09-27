// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:projects/core/utils/validators.dart';
// import 'package:projects/features/attendance/data/datasources/attendance_remote_data_source.dart';
// import 'package:projects/features/attendance/widgets/attendance_student_list.dart';
// import 'package:projects/features/attendance/widgets/batch_operations_bar.dart';
// import 'package:projects/features/attendance/widgets/class_selection_dropdown.dart';
// import 'package:projects/features/attendance/widgets/submission_button.dart';
// import 'package:provider/provider.dart';

// class StaffAttendanceScreen extends StatefulWidget {
//   const StaffAttendanceScreen({Key? key}) : super(key: key);

//   @override
//   State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
// }

// class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
//   bool _isAuthorized = false;
//   bool _checkingAuthorization = true;

//   @override
//   void initState() {
//     super.initState();
//     _checkAuthorization();
//   }

//   Future<void> _checkAuthorization() async {
//     final isStaff = await Validators.isStaff();
//     setState(() {
//       _isAuthorized = isStaff;
//       _checkingAuthorization = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_checkingAuthorization) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (!_isAuthorized) {
//       return const Scaffold(
//         body: Center(child: Text('Access denied. Staff role required.')),
//       );
//     }

//     return ChangeNotifierProvider(
//       create: (context) => AttendanceProvider(
//         AttendanceRepository(AttendanceRemoteDataSource()),
//       ),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             'Mark Attendance',
//             style: GoogleFonts.lexend(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         body: const _AttendanceContent(),
//       ),
//     );
//   }
// }

// class _AttendanceContent extends StatelessWidget {
//   const _AttendanceContent({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Date and Class Selection
//           Row(
//             children: const [
//               Expanded(child: DateSelectionField()),
//               SizedBox(width: 16),
//               Expanded(child: ClassSelectionDropdown()),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // Batch operations
//           const BatchOperationsBar(),

//           const SizedBox(height: 16),

//           // Last marked info
//           Consumer<AttendanceProvider>(
//             builder: (context, provider, child) {
//               if (provider.lastMarkedInfo == null) {
//                 return const SizedBox();
//               }

//               return Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.info_outline, color: Colors.blue),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         provider.lastMarkedInfo!,
//                         style: GoogleFonts.lexend(color: Colors.blue[700]),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),

//           const SizedBox(height: 16),

//           // Student list
//           const Expanded(child: AttendanceStudentList()),

//           const SizedBox(height: 16),

//           // Submit button
//           const SubmissionButton(),
//         ],
//       ),
//     );
//   }
// }

// class DateSelectionField {
//   const DateSelectionField();
// }
