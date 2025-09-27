// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:provider/provider.dart';

// class SubmissionButton extends StatelessWidget {
//   const SubmissionButton({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AttendanceProvider>(context);

//     if (provider.attendanceRecords.isEmpty) {
//       return const SizedBox();
//     }

//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: provider.isLoading
//             ? null
//             : () async {
//                 final success = await provider.submitAttendance();

//                 if (success) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         'Attendance submitted successfully!',
//                         style: GoogleFonts.lexend(),
//                       ),
//                       action: SnackBarAction(
//                         label: 'Undo',
//                         onPressed: () {
//                           // Implement undo functionality if needed
//                         },
//                       ),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         'Failed to submit attendance.',
//                         style: GoogleFonts.lexend(),
//                       ),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//         child: provider.isLoading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : Text('Submit Attendance', style: GoogleFonts.lexend()),
//       ),
//     );
//   }
// }
