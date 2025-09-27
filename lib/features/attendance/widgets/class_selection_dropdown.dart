// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:projects/attendance/repositories/attendance_repository.dart';
// import 'package:projects/features/attendance/data/datasources/attendance_remote_data_source.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ClassSelectionDropdown extends StatelessWidget {
//   const ClassSelectionDropdown({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AttendanceProvider>(context);

//     return StreamBuilder<QuerySnapshot>(
//       stream: AttendanceRepository(
//         AttendanceRemoteDataSource(),
//       ).getClassesStream(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: DropdownButton(
//               isExpanded: true,
//               items: [],
//               onChanged: null,
//               hint: Text('Loading classes...'),
//             ),
//           );
//         }

//         final classes = snapshot.data!.docs;

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: DropdownButton<String>(
//             isExpanded: true,
//             value: provider.selectedClassId,
//             items: classes.map((classDoc) {
//               return DropdownMenuItem<String>(
//                 value: classDoc.id,
//                 child: Text(classDoc.data()['name'] ?? 'Unknown Class'),
//               );
//             }).toList(),
//             onChanged: (classId) {
//               if (classId != null) {
//                 final classDoc = classes.firstWhere((doc) => doc.id == classId);
//                 provider.setClass(classId, classDoc.data()['name'] ?? '');
//               }
//             },
//             hint: Text('Select Class', style: GoogleFonts.lexend()),
//           ),
//         );
//       },
//     );
//   }
// }
