// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// @immutable
// class Student {
//   final String id;
//   final String schoolId;
//   final String name;
//   final int age;
//   final String parentEmail;
//   final String parentMobile;
//   final String studentClass;
//   final String section;
//   final DateTime dateOfBirth;
//   final String address;
//   final String status;
//   final DateTime createdAt;
//   final String createdBy;
//   final String studentId; // 10-digit unique ID

//   const Student({
//     required this.id,
//     required this.schoolId,
//     required this.name,
//     required this.age,
//     required this.parentEmail,
//     required this.parentMobile,
//     required this.studentClass,
//     required this.section,
//     required this.dateOfBirth,
//     required this.address,
//     required this.status,
//     required this.createdAt,
//     required this.createdBy,
//     required this.studentId,
//   });

//   factory Student.fromMap(Map<String, dynamic> map) {
//     return Student(
//       id: map['id'] as String,
//       schoolId: map['schoolId'] as String,
//       name: map['name'] as String,
//       age: map['age'] as int,
//       parentEmail: map['parentEmail'] as String,
//       parentMobile: map['parentMobile'] as String,
//       studentClass: map['class'] as String,
//       section: map['section'] as String,
//       dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
//       address: map['address'] as String,
//       status: map['status'] as String,
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//       createdBy: map['createdBy'] as String,
//       studentId: map['studentId'] as String,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'schoolId': schoolId,
//       'name': name,
//       'age': age,
//       'parentEmail': parentEmail,
//       'parentMobile': parentMobile,
//       'class': studentClass,
//       'section': section,
//       'dateOfBirth': Timestamp.fromDate(dateOfBirth),
//       'address': address,
//       'status': status,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'createdBy': createdBy,
//       'studentId': studentId,
//     };
//   }

//   Student copyWith({
//     String? name,
//     int? age,
//     String? parentEmail,
//     String? parentMobile,
//     String? studentClass,
//     String? section,
//     DateTime? dateOfBirth,
//     String? address,
//     String? status,
//   }) {
//     return Student(
//       id: id,
//       schoolId: schoolId,
//       name: name ?? this.name,
//       age: age ?? this.age,
//       parentEmail: parentEmail ?? this.parentEmail,
//       parentMobile: parentMobile ?? this.parentMobile,
//       studentClass: studentClass ?? this.studentClass,
//       section: section ?? this.section,
//       dateOfBirth: dateOfBirth ?? this.dateOfBirth,
//       address: address ?? this.address,
//       status: status ?? this.status,
//       createdAt: createdAt,
//       createdBy: createdBy,
//       studentId: studentId,
//     );
//   }

//   @override
//   String toString() {
//     return 'Student($name, $studentClass-$section, ID: $studentId)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is Student && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
