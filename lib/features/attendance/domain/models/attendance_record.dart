class AttendanceRecord {
  final String studentId;
  final String studentName;
  String status;
  final String? rollNumber;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    this.status = 'present',
    this.rollNumber,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'status': status,
      if (rollNumber != null) 'rollNumber': rollNumber,
    };
  }

  // Create from Firestore document
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      status: map['status'] ?? 'present',
      rollNumber: map['rollNumber'],
    );
  }
}
