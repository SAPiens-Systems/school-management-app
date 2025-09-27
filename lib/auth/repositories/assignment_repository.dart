// repositories/assignment_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:projects/models/assigment_model.dart';

class AssignmentRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String schoolId;

  AssignmentRepository({
    required this.schoolId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance;

  // Get assignments for teacher (their own assignments)
  Stream<List<Assignment>> getTeacherAssignments(String teacherId) {
    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Assignment.fromFirestore(doc))
              .toList(),
        );
  }

  // Get all assignments for admin
  Stream<List<Assignment>> getAllAssignments() {
    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Assignment.fromFirestore(doc))
              .toList(),
        );
  }

  // Get assignments for a specific class
  Stream<List<Assignment>> getClassAssignments(String classId) {
    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'published')
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Assignment.fromFirestore(doc))
              .toList(),
        );
  }

  // Create new assignment
  Future<String> createAssignment(Assignment assignment) async {
    final docRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc();

    await docRef.set(assignment.toMap()..['id'] = docRef.id);
    return docRef.id;
  }

  // Update assignment
  Future<void> updateAssignment(Assignment assignment) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc(assignment.id)
        .update(assignment.toMap());
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc(assignmentId)
        .delete();
  }

  // Upload attachment
  Future<String> uploadAttachment(String assignmentId, File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = storage.ref(
      'schools/$schoolId/assignments/$assignmentId/attachments/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // Get students for a class (for notifications)
  Future<List<Map<String, dynamic>>> getClassStudents(String classId) async {
    final snapshot = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }
}
