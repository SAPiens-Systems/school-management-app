// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:provider/provider.dart';

// class BatchOperationsBar extends StatelessWidget {
//   const BatchOperationsBar({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AttendanceProvider>(context);

//     if (provider.attendanceRecords.isEmpty) {
//       return const SizedBox();
//     }

//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton.icon(
//             icon: const Icon(Icons.check_circle_outline),
//             label: Text('Mark All Present', style: GoogleFonts.lexend()),
//             onPressed: provider.markAllAsPresent,
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: OutlinedButton.icon(
//             icon: const Icon(Icons.clear),
//             label: Text('Clear All', style: GoogleFonts.lexend()),
//             onPressed: provider.clearAll,
//           ),
//         ),
//       ],
//     );
//   }
// }
