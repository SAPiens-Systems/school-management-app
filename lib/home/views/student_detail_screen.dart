// screens/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/student_model.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;
  final String schoolId;

  const StudentDetailsScreen({
    Key? key,
    required this.studentId,
    required this.schoolId,
  }) : super(key: key);

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailsScreen> {
  late Future<Student> _studentFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _studentFuture = _fetchStudent();
  }

  Future<Student> _fetchStudent() async {
    try {
      final doc = await _firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (doc.exists) {
        return Student.fromFirestore(doc);
      } else {
        throw Exception('Student not found');
      }
    } catch (e) {
      throw Exception('Failed to load student: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _studentFuture = _fetchStudent();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Student>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _studentFuture = _fetchStudent();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No student data found'));
          }

          final student = snapshot.data!;
          return _buildStudentDetails(student);
        },
      ),
    );
  }

  Widget _buildStudentDetails(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(student),
          const SizedBox(height: 24),

          // Personal Information
          _buildInfoSection(
            title: 'Personal Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('Full Name', student.name),
              _buildInfoRow('Email', student.email),
              _buildInfoRow('Gender', student.gender),
              // _buildInfoRow(
              //   'Date of Birth',
              //   DateFormat('yyyy-MM-dd').format(student.dateOfBirth),
              // ),
              // _buildInfoRow('Age', '${student.age} years'),
              if (student.bloodGroup != null)
                _buildInfoRow('Blood Group', student.bloodGroup!),
            ],
          ),
          const SizedBox(height: 24),

          // Academic Information
          _buildInfoSection(
            title: 'Academic Information',
            icon: Icons.school,
            children: [
              // _buildInfoRow('Class', student.className),
              // _buildInfoRow('Section', student.section),
              // _buildInfoRow('Class ID', student.classId),
              _buildInfoRow('Student ID', student.id),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Information
          _buildInfoSection(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildInfoRow('Phone', student.phone),
              _buildInfoRow('Address', student.address),
              if (student.emergencyContact != null)
                _buildInfoRow('Emergency Contact', student.emergencyContact!),
            ],
          ),
          const SizedBox(height: 24),

          // Parent/Guardian Information
          if (student.parentName != null ||
              student.parentEmail != null ||
              student.parentPhone != null)
            Column(
              children: [
                _buildInfoSection(
                  title: 'Parent/Guardian Information',
                  icon: Icons.family_restroom,
                  children: [
                    if (student.parentName != null)
                      _buildInfoRow('Parent Name', student.parentName!),
                    if (student.parentEmail != null)
                      _buildInfoRow('Parent Email', student.parentEmail!),
                    if (student.parentPhone != null)
                      _buildInfoRow('Parent Phone', student.parentPhone!),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Medical Information
          if (student.medicalConditions != null || student.allergies != null)
            Column(
              children: [
                _buildInfoSection(
                  title: 'Medical Information',
                  icon: Icons.medical_services,
                  children: [
                    if (student.medicalConditions != null)
                      _buildInfoRow(
                        'Medical Conditions',
                        student.medicalConditions!,
                      ),
                    if (student.allergies != null)
                      _buildInfoRow('Allergies', student.allergies!),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),

          // System Information
          _buildInfoSection(
            title: 'System Information',
            icon: Icons.info,
            children: [
              _buildInfoRow('School ID', student.schoolId),
              _buildInfoRow(
                'Created',
                DateFormat('yyyy-MM-dd – HH:mm').format(student.createdAt),
              ),
              _buildInfoRow(
                'Last Updated',
                DateFormat('yyyy-MM-dd – HH:mm').format(student.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Student student) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                student.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'Class'} ${student.classId.length != 10 ? student.classId[6] : student.classId[6] + student.classId[7]} - ${student.classId[student.classId.length - 1].toUpperCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
