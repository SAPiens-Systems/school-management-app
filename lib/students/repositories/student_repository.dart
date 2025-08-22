import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/core/exceptions/database_exceptions.dart';
import 'package:projects/students/models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore;
  final String _schoolId;

  StudentRepository({
    required FirebaseFirestore firestore,
    required String schoolId,
  }) : _firestore = firestore,
       _schoolId = schoolId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('schools').doc(_schoolId).collection('students');

  // Generate unique 10-digit student ID
  Future<String> _generateStudentId() async {
    const chars = '0123456789';
    final random = Random();

    String generateId() {
      return List.generate(
        10,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
    }

    // Check uniqueness with retry logic
    for (int i = 0; i < 5; i++) {
      final candidateId = generateId();
      final exists = await _collection
          .where('studentId', isEqualTo: candidateId)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);
      if (!exists) return candidateId;
    }

    throw DatabaseException('Failed to generate unique student ID');
  }

  Future<Student> createStudent(Student student) async {
    try {
      final studentId = await _generateStudentId();
      final studentWithId = Student(
        id: student.id,
        schoolId: student.schoolId,
        name: student.name,
        age: student.age,
        parentEmail: student.parentEmail,
        parentMobile: student.parentMobile,
        studentClass: student.studentClass,
        section: student.section,
        dateOfBirth: student.dateOfBirth,
        address: student.address,
        status: student.status,
        createdAt: student.createdAt,
        createdBy: student.createdBy,
        studentId: studentId,
      );

      await _collection.doc(student.id).set(studentWithId.toMap());
      return studentWithId;
    } on FirebaseException catch (e) {
      throw DatabaseException('Failed to create student: ${e.message}');
    }
  }

  Future<List<Student>> getStudents({
    String? classFilter,
    String? sectionFilter,
    int limit = 50,
  }) async {
    try {
      Query query = _collection.orderBy('name');

      if (classFilter != null) {
        query = query.where('class', isEqualTo: classFilter);
        if (sectionFilter != null) {
          query = query.where('section', isEqualTo: sectionFilter);
        }
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw DatabaseException('Failed to fetch students: ${e.message}');
    }
  }

  Future<List<Student>> searchStudents(String query) async {
    try {
      if (query.length < 2) return [];

      final lowercaseQuery = query.toLowerCase();

      final snapshot = await _collection
          .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('name', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data()))
          .where(
            (student) => student.name.toLowerCase().contains(lowercaseQuery),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException('Search failed: ${e.message}');
    }
  }

  Stream<List<Student>> watchStudents({
    String? classFilter,
    String? sectionFilter,
  }) {
    Query query = _collection.orderBy('name');

    if (classFilter != null) {
      query = query.where('class', isEqualTo: classFilter);
      if (sectionFilter != null) {
        query = query.where('section', isEqualTo: sectionFilter);
      }
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList(),
    );
  }

  Future<List<String>> getAvailableClasses() async {
    try {
      final snapshot = await _collection.orderBy('class').get();

      final classes = snapshot.docs
          .map((doc) => doc.data()['class'] as String?)
          .where((className) => className != null)
          .toSet()
          .toList();

      return classes..sort();
    } on FirebaseException catch (e) {
      throw DatabaseException('Failed to fetch classes: ${e.message}');
    }
  }

  Future<List<String>> getAvailableSections(String studentClass) async {
    try {
      final snapshot = await _collection
          .where('class', isEqualTo: studentClass)
          .get();

      final sections = snapshot.docs
          .map((doc) => doc.data()['section'] as String?)
          .where((section) => section != null)
          .toSet()
          .toList();

      return sections..sort();
    } on FirebaseException catch (e) {
      throw DatabaseException('Failed to fetch sections: ${e.message}');
    }
  }
}
