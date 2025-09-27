import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClass {
  final String id;
  final String name;
  final String section;
  final String? subject;
  final String? schedule;
  final String? room;
  final String teacherId;
  final String teacherName;
  final int studentCount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolClass({
    required this.id,
    required this.name,
    required this.section,
    this.subject,
    this.schedule,
    this.room,
    required this.teacherId,
    required this.teacherName,
    this.studentCount = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    Timestamp? updatedAtTimestamp = data['updatedAt'] as Timestamp?;

    DateTime createdAt = createdAtTimestamp?.toDate() ?? DateTime.now();
    DateTime updatedAt = updatedAtTimestamp?.toDate() ?? DateTime.now();
    return SchoolClass(
      id: doc.id,
      name: data['name'] ?? '',
      section: data['section'] ?? '',
      subject: data['subject'] as String?,
      schedule: data['schedule'] as String?,
      room: data['room'] as String?,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? 'Unassigned',
      studentCount: (data['studentCount'] as int?) ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'section': section,
      'subject': subject,
      'schedule': schedule,
      'room': room,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentCount': studentCount,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
