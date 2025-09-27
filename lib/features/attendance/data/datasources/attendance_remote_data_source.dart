// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:projects/core/services/firestore_paths.dart';

// class AttendanceRemoteDataSource {
//   final FirebaseFirestore _firestore;
//   final User? _user;

//   AttendanceRemoteDataSource({FirebaseFirestore? firestore})
//     : _firestore = firestore ?? FirebaseFirestore.instance,
//       _user = FirebaseAuth.instance.currentUser;

//   Future<String> getSchoolId() async {
//     final token = await _user!.getIdTokenResult(true);
//     return token.claims?['schoolId'] as String? ?? '';
//   }

//   // Get classes for the staff's school
//   Stream<QuerySnapshot> getClassesStream() {
//     return getSchoolId()
//         .asStream()
//         .asyncMap((schoolId) {
//           return _firestore
//               .collection(FirestorePaths.classes(schoolId))
//               .orderBy('name')
//               .snapshots();
//         })
//         .fold<QuerySnapshot>((prev, element) => element);
//   }

//   // Get students for a specific class
//   Stream<QuerySnapshot> getStudentsStream(String classId) {
//     return getSchoolId()
//         .asStream()
//         .asyncMap((schoolId) {
//           return _firestore
//               .collection(FirestorePaths.students(schoolId, classId))
//               .orderBy('name')
//               .snapshots();
//         })
//         .fold<QuerySnapshot>((prev, element) => element);
//   }

//   // Get existing attendance for a specific date and class
//   Future<Map<String, String>> getExistingAttendance(
//     String date,
//     String classId,
//   ) async {
//     final schoolId = await getSchoolId();
//     final snapshot = await _firestore
//         .collection(FirestorePaths.attendanceRecords(schoolId, date))
//         .where('classId', isEqualTo: classId)
//         .get();

//     final attendanceMap = <String, String>{};
//     for (final doc in snapshot.docs) {
//       attendanceMap[doc.data()['studentId'] as String] =
//           doc.data()['status'] as String;
//     }

//     return attendanceMap;
//   }

//   // Submit attendance in batch
//   Future<void> submitAttendance({
//     required String date,
//     required String classId,
//     required Map<String, String> attendanceRecords,
//   }) async {
//     final schoolId = await getSchoolId();
//     final batch = _firestore.batch();

//     final attendanceRef = _firestore.collection(
//       FirestorePaths.attendanceRecords(schoolId, date),
//     );

//     attendanceRecords.forEach((studentId, status) {
//       final docRef = attendanceRef.doc(studentId);
//       batch.set(docRef, {
//         'studentId': studentId,
//         'status': status,
//         'markedBy': _user!.uid,
//         'markedAt': FieldValue.serverTimestamp(),
//         'classId': classId,
//         'schoolId': schoolId,
//       });
//     });

//     await batch.commit();
//   }
// }
