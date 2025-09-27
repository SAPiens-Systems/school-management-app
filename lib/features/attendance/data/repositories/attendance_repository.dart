// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:projects/features/attendance/data/datasources/attendance_remote_data_source.dart';

// class AttendanceRepository {
//   final AttendanceRemoteDataSource _remoteDataSource;

//   AttendanceRepository(this._remoteDataSource);

//   Stream<QuerySnapshot> getClassesStream() =>
//       _remoteDataSource.getClassesStream();

//   Stream<QuerySnapshot> getStudentsStream(String classId) =>
//       _remoteDataSource.getStudentsStream(classId);

//   Future<Map<String, String>> getExistingAttendance(
//     String date,
//     String classId,
//   ) => _remoteDataSource.getExistingAttendance(date, classId);

//   Future<void> submitAttendance({
//     required String date,
//     required String classId,
//     required Map<String, String> attendanceRecords,
//   }) => _remoteDataSource.submitAttendance(
//     date: date,
//     classId: classId,
//     attendanceRecords: attendanceRecords,
//   );
// }
