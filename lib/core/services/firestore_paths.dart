class FirestorePaths {
  static String user(String userId) => 'users/$userId';

  static String school(String schoolId) => 'schools/$schoolId';

  static String classes(String schoolId) => 'schools/$schoolId/classes';

  static String classDoc(String schoolId, String classId) =>
      'schools/$schoolId/classes/$classId';

  static String students(String schoolId, String classId) =>
      'schools/$schoolId/classes/$classId/students';

  static String studentDoc(String schoolId, String classId, String studentId) =>
      'schools/$schoolId/classes/$classId/students/$studentId';

  static String attendance(String schoolId, String date) =>
      'schools/$schoolId/attendance/$date';

  static String attendanceRecords(String schoolId, String date) =>
      'schools/$schoolId/attendance/$date/records';

  static String attendanceRecord(
    String schoolId,
    String date,
    String studentId,
  ) => 'schools/$schoolId/attendance/$date/records/$studentId';
}
