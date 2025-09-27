// models/assignment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { draft, published, closed }

class Assignment {
  final String id;
  final String schoolId;
  final String title;
  final String instructions; // JSON string for Quill content
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final DateTime dueDate;
  final int pointsPossible;
  final AssignmentStatus status;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.instructions,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.dueDate,
    required this.pointsPossible,
    required this.status,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      title: data['title'] ?? '',
      instructions: data['instructions'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      pointsPossible: data['pointsPossible'] ?? 0,
      status: _parseStatus(data['status']),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static AssignmentStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'published':
          return AssignmentStatus.published;
        case 'closed':
          return AssignmentStatus.closed;
        default:
          return AssignmentStatus.draft;
      }
    }
    return AssignmentStatus.draft;
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'title': title,
      'instructions': instructions,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dueDate': Timestamp.fromDate(dueDate),
      'pointsPossible': pointsPossible,
      'status': status.toString().split('.').last,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now());
  bool get canEdit => status == AssignmentStatus.draft && !isOverdue;
}
