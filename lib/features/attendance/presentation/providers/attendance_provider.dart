// import 'package:flutter/foundation.dart';
// import 'package:projects/attendance/provider/attendance_provider.dart';
// import 'package:projects/attendance/repositories/attendance_repository.dart';

// class AttendanceProvider with ChangeNotifier {
//   final AttendanceRepository _repository;

//   AttendanceProvider(this._repository);

//   DateTime _selectedDate = DateTime.now();
//   String? _selectedClassId;
//   String? _selectedClassName;
//   List<AttendanceRecord> _attendanceRecords = [];
//   bool _isLoading = false;
//   String? _lastMarkedInfo;
//   Map<String, String> _existingAttendance = {};

//   DateTime get selectedDate => _selectedDate;
//   String? get selectedClassId => _selectedClassId;
//   String? get selectedClassName => _selectedClassName;
//   List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
//   bool get isLoading => _isLoading;
//   String? get lastMarkedInfo => _lastMarkedInfo;

//   void setDate(DateTime date) {
//     _selectedDate = date;
//     _loadExistingAttendance();
//     notifyListeners();
//   }

//   void setClass(String classId, String className) {
//     _selectedClassId = classId;
//     _selectedClassName = className;
//     _loadStudents();
//     notifyListeners();
//   }

//   Future<void> _loadStudents() async {
//     if (_selectedClassId == null) return;

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final studentsSnapshot = await _repository
//           .getStudentsStream(_selectedClassId!)
//           .first;
//       _attendanceRecords = studentsSnapshot.docs.map((doc) {
//         return AttendanceRecord(
//           studentId: doc.id,
//           studentName: doc.data()['name'] ?? 'Unknown',
//           rollNumber: doc.data()['rollNumber'],
//         );
//       }).toList();

//       await _loadExistingAttendance();
//     } catch (e) {
//       print('Error loading students: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _loadExistingAttendance() async {
//     if (_selectedClassId == null || _attendanceRecords.isEmpty) return;

//     try {
//       final dateStr = _formatDate(_selectedDate);
//       _existingAttendance = await _repository.getExistingAttendance(
//         dateStr,
//         _selectedClassId!,
//       );

//       for (final record in _attendanceRecords) {
//         if (_existingAttendance.containsKey(record.studentId)) {
//           record.status = _existingAttendance[record.studentId]!;
//         }
//       }

//       // Set last marked info if attendance exists
//       if (_existingAttendance.isNotEmpty) {
//         _lastMarkedInfo = "Attendance already marked for this date";
//       } else {
//         _lastMarkedInfo = null;
//       }

//       notifyListeners();
//     } catch (e) {
//       print('Error loading existing attendance: $e');
//     }
//   }

//   void updateStudentStatus(String studentId, String status) {
//     final record = _attendanceRecords.firstWhere(
//       (r) => r.studentId == studentId,
//     );
//     record.status = status;
//     notifyListeners();
//   }

//   void markAllAsPresent() {
//     for (final record in _attendanceRecords) {
//       record.status = 'present';
//     }
//     notifyListeners();
//   }

//   void clearAll() {
//     for (final record in _attendanceRecords) {
//       record.status = 'absent';
//     }
//     notifyListeners();
//   }

//   Future<bool> submitAttendance() async {
//     if (_selectedClassId == null) return false;

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final dateStr = _formatDate(_selectedDate);
//       final attendanceMap = <String, String>{};

//       for (final record in _attendanceRecords) {
//         attendanceMap[record.studentId] = record.status;
//       }

//       await _repository.submitAttendance(
//         date: dateStr,
//         classId: _selectedClassId!,
//         attendanceRecords: attendanceMap,
//       );

//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       print('Error submitting attendance: $e');
//       return false;
//     }
//   }

//   String _formatDate(DateTime date) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }
// }
