// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:projects/core/constants/attendance_constants.dart';
// import 'package:provider/provider.dart';

// class AttendanceStudentList extends StatelessWidget {
//   const AttendanceStudentList({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AttendanceProvider>(context);

//     if (provider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (provider.attendanceRecords.isEmpty) {
//       return Center(
//         child: Text(
//           'No students found. Select a class to continue.',
//           style: GoogleFonts.lexend(),
//           textAlign: TextAlign.center,
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: provider.attendanceRecords.length,
//       itemBuilder: (context, index) {
//         final record = provider.attendanceRecords[index];
//         return _StudentAttendanceItem(record: record);
//       },
//     );
//   }
// }

// class _StudentAttendanceItem extends StatelessWidget {
//   final AttendanceRecord record;

//   const _StudentAttendanceItem({Key? key, required this.record})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AttendanceProvider>(context);

//     Color getBackgroundColor() {
//       switch (record.status) {
//         case 'present':
//           return AttendanceConstants.statusColors['present']!.withOpacity(0.1);
//         case 'absent':
//           return AttendanceConstants.statusColors['absent']!.withOpacity(0.1);
//         case 'late':
//           return AttendanceConstants.statusColors['late']!.withOpacity(0.1);
//         case 'halfDay':
//           return AttendanceConstants.statusColors['halfDay']!.withOpacity(0.1);
//         default:
//           return Colors.transparent;
//       }
//     }

//     return Card(
//       color: getBackgroundColor(),
//       child: ListTile(
//         title: Text(record.studentName, style: GoogleFonts.lexend()),
//         subtitle: record.rollNumber != null
//             ? Text('Roll No: ${record.rollNumber}', style: GoogleFonts.lexend())
//             : null,
//         trailing: SizedBox(
//           width: 160,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: AttendanceConstants.statusOptions.map((status) {
//               return IconButton(
//                 icon: Text(
//                   AttendanceConstants.statusEmojis[status]!,
//                   style: const TextStyle(fontSize: 18),
//                 ),
//                 onPressed: () {
//                   provider.updateStudentStatus(record.studentId, status);
//                 },
//                 style: IconButton.styleFrom(
//                   backgroundColor: record.status == status
//                       ? AttendanceConstants.statusColors[status]!.withOpacity(
//                           0.2,
//                         )
//                       : null,
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         onTap: () {
//           // Cycle through statuses on tap
//           final currentIndex = AttendanceConstants.statusOptions.indexOf(
//             record.status,
//           );
//           final nextIndex =
//               (currentIndex + 1) % AttendanceConstants.statusOptions.length;
//           provider.updateStudentStatus(
//             record.studentId,
//             AttendanceConstants.statusOptions[nextIndex],
//           );
//         },
//       ),
//     );
//   }
// }
