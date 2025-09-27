// models/student_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final String classId;
  final String className;
  final String section;
  final String gender;
  // final DateTime dateOfBirth;
  // final int age;
  final String address;
  final String phone;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentName;
  final String? parentEmail;
  final String? parentPhone;
  final String? emergencyContact;
  final String? bloodGroup;
  final String? medicalConditions;
  final String? allergies;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.classId,
    required this.className,
    required this.section,
    required this.gender,
    // required this.dateOfBirth,
    // required this.age,
    required this.address,
    required this.phone,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.parentName,
    this.parentEmail,
    this.parentPhone,
    this.emergencyContact,
    this.bloodGroup,
    this.medicalConditions,
    this.allergies,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // final dob = (data['dateOfBirth'] as Timestamp?)?? DateTime.now();
    // final age = _calculateAge(dob);

    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? data['class'] ?? '',
      section: data['section'] ?? '',
      gender: data['gender'] ?? 'Other',
      // dateOfBirth: dob,
      // age: data['age'] ?? age,
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      schoolId: data['schoolId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentName: data['parentName'],
      parentEmail: data['parentEmail'],
      parentPhone: data['parentPhone'],
      emergencyContact: data['emergencyContact'],
      bloodGroup: data['bloodGroup'],
      medicalConditions: data['medicalConditions'],
      allergies: data['allergies'],
    );
  }

  static int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'classId': classId,
      'className': className,
      'section': section,
      'gender': gender,
      // 'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      // 'age': age,
      'address': address,
      'phone': phone,
      'schoolId': schoolId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'parentName': parentName,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'emergencyContact': emergencyContact,
      'bloodGroup': bloodGroup,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
    };
  }
}
