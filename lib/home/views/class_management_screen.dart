import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/home/views/class_management_screen.dart' as repository;
import 'package:projects/models/class_model.dart';
import 'package:provider/provider.dart';

class ClassStudent {
  final String id;
  final String name;
  final String email;
  final String classId;
  final DateTime dateAdded;

  ClassStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.classId,
    required this.dateAdded,
  });

  factory ClassStudent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassStudent(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      classId: data['classId'] ?? '',
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'classId': classId,
      'dateAdded': dateAdded,
    };
  }
}

// ==================== REPOSITORY ====================
class ClassManagementRepository {
  final FirebaseFirestore firestore;
  final String schoolId;

  ClassManagementRepository({
    required this.schoolId,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  // Fetch all classes for the school
  Stream<List<SchoolClass>> fetchClasses({String? teacherId}) {
    print('DEBUG: Fetching classes for school: $schoolId');
    print('DEBUG: Teacher filter: $teacherId');
    Query query = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .orderBy('name');

    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
      print('DEBUG: Applying teacher filter: $teacherId');
    }

    return query.snapshots().map((snapshot) {
      print('DEBUG: Found ${snapshot.docs.length} classes');
      for (var doc in snapshot.docs) {
        print('DEBUG: Class: ${doc.id} - ${doc.data()}');
      }
      return snapshot.docs
          .map((doc) => SchoolClass.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    try {
      final teachersSnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .orderBy('name')
          .get();

      final teachers = teachersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Teacher',
          'email': data['email'] ?? '',
        };
      }).toList();

      print('DEBUG: Found ${teachers.length} teachers');
      return teachers;
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  // Create new class with proper ID format - FIXED
  Future<String> createClass(SchoolClass schoolClass) async {
    // Generate the proper class ID format: class_{number}_{section}
    final classNumber = schoolClass.name.replaceAll('Class ', '').split(' ')[0];
    final section = schoolClass.section.toLowerCase();
    final classId = 'class_${classNumber}_$section';

    final docRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId); // Use the formatted ID instead of random

    await docRef.set(schoolClass.toMap());
    return docRef.id;
  }

  // Fetch students for a specific class - FIXED to query main students collection
  Stream<List<ClassStudent>> fetchClassStudents(String classId) {
    print('DEBUG: Fetching students for class: $classId');
    print('DEBUG: Querying main students collection with classId: $classId');

    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('classId', isEqualTo: classId)
        .orderBy('name')
        .snapshots()
        .handleError((error) {
          print('DEBUG: Error fetching students: $error'); // Add error logging
        })
        .map((snapshot) {
          print(
            'DEBUG: Found ${snapshot.docs.length} students for class $classId',
          );

          for (var doc in snapshot.docs) {
            print('DEBUG: Student: ${doc.id} - ${doc.data()}');
          }

          return snapshot.docs
              .map((doc) => ClassStudent.fromFirestore(doc))
              .toList();
        });
  }

  // Search students for adding to class
  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    try {
      final studentsSnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(10)
          .get();

      return studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Student',
          'email': data['email'] ?? '',
          'classId': data['classId'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error searching students: $e');
      return [];
    }
  }

  // Update class - FIXED to handle ID changes if name/section changes
  Future<void> updateClass(SchoolClass schoolClass, String oldClassId) async {
    final classNumber = schoolClass.name.replaceAll('Class ', '').split(' ')[0];
    final section = schoolClass.section.toLowerCase();
    final newClassId = 'class_${classNumber}_$section';

    if (oldClassId != newClassId) {
      // If ID changed, we need to create new document and delete old one
      final batch = firestore.batch();

      // Create new document
      final newRef = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(newClassId);
      batch.set(newRef, schoolClass.toMap());

      // Delete old document
      final oldRef = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(oldClassId);
      batch.delete(oldRef);

      await batch.commit();
    } else {
      // Just update the existing document
      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(schoolClass.id)
          .update(schoolClass.toMap());
    }
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .delete();
  }

  // Add student to class - FIXED to only update main students collection
  Future<void> addStudentToClass(
    String classId,
    Map<String, dynamic> student,
  ) async {
    final batch = firestore.batch();

    // Update the student document in main collection
    final studentRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(student['id']);

    batch.update(studentRef, {
      'classId': classId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update student count in class document
    final classRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId);

    batch.update(classRef, {
      'studentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('DEBUG: Added student ${student['id']} to class $classId');
  }

  // Remove student from class - FIXED to only update main students collection
  Future<void> removeStudentFromClass(String classId, String studentId) async {
    final batch = firestore.batch();

    // Remove class reference from student document in main collection
    final studentRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId);

    batch.update(studentRef, {
      'classId': FieldValue.delete(), // Remove the classId field
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update student count in class document
    final classRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId);

    batch.update(classRef, {
      'studentCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('DEBUG: Removed student $studentId from class $classId');
  }

  // Sync student count with actual number of students
  Future<void> syncStudentCount(String schoolId, String classId) async {
    try {
      final students = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .where('classId', isEqualTo: classId)
          .get();

      final classRef = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId);

      await classRef.update({
        'studentCount': students.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
        'DEBUG: Synced student count to ${students.docs.length} for class $classId',
      );
    } catch (e) {
      print('Error syncing student count: $e');
    }
  }
}

// ==================== PROVIDER ====================
class ClassManagementProvider with ChangeNotifier {
  final ClassManagementRepository repository;
  final String userRole;
  final String userId;

  List<SchoolClass> _classes = [];
  List<ClassStudent> _classStudents = [];
  List<Map<String, dynamic>> _teachers = [];
  String _searchQuery = '';
  String _selectedClassId = '';
  bool _isLoading = false;
  bool _isManagingStudents = false;

  List<SchoolClass> get classes => _classes;
  List<ClassStudent> get classStudents => _classStudents;
  List<Map<String, dynamic>> get teachers => _teachers;
  String get searchQuery => _searchQuery;
  String get selectedClassId => _selectedClassId;
  bool get isLoading => _isLoading;
  bool get isManagingStudents => _isManagingStudents;
  StreamSubscription<List<SchoolClass>>? _classesStreamSubscription;
  StreamSubscription<List<ClassStudent>>? _classStudentsStreamSubscription;

  ClassManagementProvider({
    required this.repository,
    required this.userRole,
    required this.userId,
  });

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    print('DEBUG: Loading classes, userRole: $userRole, userId: $userId');
    try {
      final stream = repository.fetchClasses(
        teacherId: userRole == 'teacher' ? userId : null,
      );

      _classesStreamSubscription?.cancel();
      _classesStreamSubscription = stream.listen(
        (classes) {
          print('DEBUG: Received ${classes.length} classes from stream');
          _classes = classes;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('DEBUG: Error loading classes: $error');
          _isLoading = false;
          notifyListeners();
        },
        onDone: () {
          print('DEBUG: Classes stream completed');
        },
      );
    } catch (e) {
      print('DEBUG: Exception in loadClasses: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeachers() async {
    try {
      _teachers = await repository.fetchTeachers();
      notifyListeners();
    } catch (e) {
      print('Error loading teachers: $e');
    }
  }

  Future<void> loadClassStudents(String classId) async {
    _isManagingStudents = true;
    _selectedClassId = classId;
    notifyListeners();

    try {
      final stream = repository.fetchClassStudents(classId);
      _classStudentsStreamSubscription?.cancel();
      _classStudentsStreamSubscription = stream.listen(
        (students) {
          print('DEBUG: Loaded ${students.length} students for class $classId');
          _classStudents = students;
          _isManagingStudents = false;
          notifyListeners();
        },
        onError: (error) {
          print('DEBUG: Error loading students: $error');
          _isManagingStudents = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('DEBUG: Exception loading students: $e');
      _isManagingStudents = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> createClass(SchoolClass schoolClass) async {
    try {
      await repository.createClass(schoolClass);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClass(SchoolClass schoolClass, String oldClassId) async {
    try {
      await repository.updateClass(schoolClass, oldClassId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _classesStreamSubscription?.cancel();
    _classStudentsStreamSubscription?.cancel();
    super.dispose();
  }
}

Future<void> deleteClass(String classId) async {
  try {
    await repository.deleteClass(classId);
  } catch (e) {
    rethrow;
  }
}

Future<void> addStudentToClass(
  String classId,
  Map<String, dynamic> student,
) async {
  try {
    await repository.addStudentToClass(classId, student);
  } catch (e) {
    rethrow;
  }
}

Future<void> removeStudentFromClass(String classId, String studentId) async {
  try {
    await repository.removeStudentFromClass(classId, studentId);
  } catch (e) {
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> searchStudents(String query) async {
  try {
    return await repository.searchStudents(query);
  } catch (e) {
    print('Error searching students: $e');
    return [];
  }
}

// ==================== MAIN SCREENS ====================
class ClassListScreen extends StatefulWidget {
  final String schoolId;
  final String userRole;
  final String userId;

  const ClassListScreen({
    Key? key,
    required this.schoolId,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  _ClassListScreenState createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  late ClassManagementProvider _provider;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _provider = ClassManagementProvider(
      repository: ClassManagementRepository(schoolId: widget.schoolId),
      userRole: widget.userRole,
      userId: widget.userId,
    );
    _provider.loadClasses();
    if (widget.userRole == 'admin') {
      _provider.loadTeachers();
    }
    //_provider.repository.debugStudentLocations(widget.classItem.id);
    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        _provider.setSearchQuery(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Class Management', style: GoogleFonts.lexend()),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ClassSearchDelegate(_provider),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _provider.loadClasses(); // Add refresh button
              },
            ),
          ],
        ),
        body: Consumer<ClassManagementProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.classes.isEmpty) {
              return Center(child: CircularProgressIndicator());
            }

            if (provider.classes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_, size: 64, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      'No classes found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (widget.userRole == 'admin')
                      TextButton(
                        onPressed: _showCreateClassDialog,
                        child: Text('Create Your First Class'),
                      ),
                  ],
                ),
              );
            }

            final filteredClasses = provider.classes.where((classItem) {
              final query = provider.searchQuery.toLowerCase();
              return classItem.name.toLowerCase().contains(query) ||
                  classItem.section.toLowerCase().contains(query) ||
                  (classItem.subject?.toLowerCase() ?? '').contains(query) ||
                  (classItem.teacherName?.toLowerCase() ?? '').contains(query);
            }).toList();

            return ListView.builder(
              itemCount: filteredClasses.length,
              itemBuilder: (context, index) {
                final classItem = filteredClasses[index];
                return _ClassListItem(
                  classItem: classItem,
                  userRole: widget.userRole,
                  onTap: () => _viewClassDetails(classItem),
                );
              },
            );
          },
        ),
        floatingActionButton: widget.userRole == 'admin'
            ? FloatingActionButton(
                onPressed: _showCreateClassDialog,
                child: Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  void _showCreateClassDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateClassDialog(provider: _provider),
    );
  }

  void _viewClassDetails(SchoolClass classItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(
          classItem: classItem,
          userRole: widget.userRole,
          userId: widget.userId,
          schoolId: widget.schoolId,
        ),
      ),
    );
  }
}

class _ClassListItem extends StatelessWidget {
  final SchoolClass classItem;
  final String userRole;
  final VoidCallback onTap;

  const _ClassListItem({
    Key? key,
    required this.classItem,
    required this.userRole,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            classItem.name[0],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${classItem.name} - ${classItem.section}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (classItem.subject != null)
              Text('Subject: ${classItem.subject}'),
            Text('Teacher: ${classItem.teacherName}'),
            Text('Students: ${classItem.studentCount}'),
            if (classItem.schedule != null)
              Text('Schedule: ${classItem.schedule}'),
          ],
        ),
        trailing: userRole == 'admin' ? Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}

class ClassDetailScreen extends StatefulWidget {
  final SchoolClass classItem;
  final String userRole;
  final String userId;
  final String schoolId;

  const ClassDetailScreen({
    Key? key,
    required this.classItem,
    required this.userRole,
    required this.userId,
    required this.schoolId,
  }) : super(key: key);

  @override
  _ClassDetailScreenState createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late ClassManagementProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ClassManagementProvider(
      repository: ClassManagementRepository(schoolId: widget.schoolId),
      userRole: widget.userRole,
      userId: widget.userId,
    );
    _provider.loadClassStudents(widget.classItem.id);
    _provider.repository.syncStudentCount(widget.schoolId, widget.classItem.id);
    if (widget.userRole == 'admin') {
      _provider.loadTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.classItem.name} - ${widget.classItem.section}'),
          // Edit Class for Future
          // actions: [
          //   if (widget.userRole == 'admin')
          //     IconButton(
          //       icon: Icon(Icons.edit),
          //       onPressed: () => _showEditClassDialog(widget.classItem),
          //     ),
          // ],
        ),
        body: Consumer<ClassManagementProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClassInfoSection(classItem: widget.classItem),
                  SizedBox(height: 24),
                  _TeacherAssignmentSection(
                    classItem: widget.classItem,
                    userRole: widget.userRole,
                    teachers: provider.teachers,
                    onTeacherChanged: _updateClassTeacher,
                  ),
                  SizedBox(height: 24),
                  _StudentRosterSection(
                    classItem: widget.classItem,
                    userRole: widget.userRole,
                    students: provider.classStudents,
                    isLoading: provider.isManagingStudents,
                    onAddStudent: () =>
                        _showAddStudentDialog(widget.classItem.id),
                    onRemoveStudent: (studentId) =>
                        _removeStudent(widget.classItem.id, studentId),
                  ),
                  if (widget.userRole == 'admin') ...[
                    SizedBox(height: 32),
                    _DangerZoneSection(
                      classItem: widget.classItem,
                      onDelete: () => _deleteClass(widget.classItem.id),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditClassDialog(SchoolClass classItem) {
    showDialog(
      context: context,
      builder: (context) =>
          CreateClassDialog(provider: _provider, existingClass: classItem),
    );
  }

  void _updateClass(SchoolClass updatedClass, String oldClassId) async {
    try {
      await _provider.updateClass(updatedClass, oldClassId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Class updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update class: $e')));
    }
  }

  void _updateClassTeacher(String teacherId, String teacherName) async {
    try {
      final updatedClass = SchoolClass(
        id: widget.classItem.id,
        name: widget.classItem.name,
        section: widget.classItem.section,
        subject: widget.classItem.subject,
        schedule: widget.classItem.schedule,
        room: widget.classItem.room,
        teacherId: teacherId,
        teacherName: teacherName,
        studentCount: widget.classItem.studentCount,
        createdBy: widget.classItem.createdBy,
        createdAt: widget.classItem.createdAt,
        updatedAt: DateTime.now(),
      );

      await _provider.updateClass(updatedClass, widget.classItem.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Teacher assigned successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to assign teacher: $e')));
    }
  }

  void _showAddStudentDialog(String classId) {
    showDialog(
      context: context,
      builder: (context) =>
          AddStudentDialog(provider: _provider, classId: classId),
    );
  }

  void _removeStudent(String classId, String studentId) async {
    try {
      await _provider.repository.removeStudentFromClass(classId, studentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student removed from class'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Implement undo functionality if needed
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove student: $e')));
    }
  }

  void _deleteClass(String classId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete this class? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _provider.repository.deleteClass(classId);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Class deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete class: $e')));
      }
    }
  }
}

// ==================== UI COMPONENTS ====================
class _ClassInfoSection extends StatelessWidget {
  final SchoolClass classItem;

  const _ClassInfoSection({Key? key, required this.classItem})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _InfoRow(label: 'Class Name', value: classItem.name),
            _InfoRow(label: 'Section', value: classItem.section),
            if (classItem.subject != null)
              _InfoRow(label: 'Subject', value: classItem.subject!),
            if (classItem.schedule != null)
              _InfoRow(label: 'Schedule', value: classItem.schedule!),
            if (classItem.room != null)
              _InfoRow(label: 'Room', value: classItem.room!),
            _InfoRow(
              label: 'Total Students',
              value: classItem.studentCount.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TeacherAssignmentSection extends StatelessWidget {
  final SchoolClass classItem;
  final String userRole;
  final List<Map<String, dynamic>> teachers;
  final Function(String, String) onTeacherChanged;

  const _TeacherAssignmentSection({
    Key? key,
    required this.classItem,
    required this.userRole,
    required this.teachers,
    required this.onTeacherChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uniqueTeachers = _getUniqueTeachers(teachers);
    final currentTeacherId = classItem.teacherId;
    final bool teacherExists =
        currentTeacherId.isNotEmpty &&
        uniqueTeachers.any((teacher) => teacher['id'] == currentTeacherId);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher Assignment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (userRole == 'admin')
              DropdownButtonFormField<String>(
                value: teacherExists ? currentTeacherId : null,
                decoration: InputDecoration(
                  labelText: 'Assign Teacher',
                  border: OutlineInputBorder(),
                ),
                items: [
                  // Add "No Teacher" option first
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('No Teacher Assigned'),
                  ),
                  // Then add all unique teachers
                  ...uniqueTeachers.map<DropdownMenuItem<String>>((teacher) {
                    final teacherId = teacher['id'] as String? ?? '';
                    final teacherName = teacher['name'] as String? ?? 'Unknown';
                    final teacherEmail = teacher['email'] as String? ?? '';

                    return DropdownMenuItem<String>(
                      value: teacherId,
                      child: Text(teacherName),
                    );
                  }).toList(),
                ],
                onChanged: (String? teacherId) {
                  if (teacherId == null) {
                    onTeacherChanged('', '');
                  } else {
                    final teacher = uniqueTeachers.firstWhere(
                      (t) => t['id'] == teacherId,
                      orElse: () => {},
                    );
                    onTeacherChanged(teacherId, teacher['name'] as String);
                  }
                },
                validator: (value) {
                  // Validation is optional since we have a "No Teacher" option
                  return null;
                },
              )
            else if (classItem.teacherName.isNotEmpty)
              _InfoRow(label: 'Teacher', value: classItem.teacherName)
            else
              Text('No teacher assigned', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getUniqueTeachers(
    List<Map<String, dynamic>> teachers,
  ) {
    final uniqueTeachers = <String, Map<String, dynamic>>{};

    for (final teacher in teachers) {
      final teacherId = teacher['id'] as String?;
      if (teacherId != null && teacherId.isNotEmpty) {
        uniqueTeachers[teacherId] = teacher;
      }
    }

    return uniqueTeachers.values.toList();
  }
}

class _StudentRosterSection extends StatelessWidget {
  final SchoolClass classItem;
  final String userRole;
  final List<ClassStudent> students;
  final bool isLoading;
  final VoidCallback onAddStudent;
  final Function(String) onRemoveStudent;

  const _StudentRosterSection({
    Key? key,
    required this.classItem,
    required this.userRole,
    required this.students,
    required this.isLoading,
    required this.onAddStudent,
    required this.onRemoveStudent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Student Roster',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (userRole == 'admin' || userRole == 'teacher')
                  ElevatedButton.icon(
                    onPressed: onAddStudent,
                    icon: Icon(Icons.person_add),
                    label: Text('Add Student'),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (students.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.group, size: 48, color: Colors.grey[300]),
                    SizedBox(height: 8),
                    Text(
                      'No students enrolled',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(student.name[0])),
                    title: Text(student.name),
                    subtitle: Text(student.email),
                    trailing: (userRole == 'admin' || userRole == 'teacher')
                        ? IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => onRemoveStudent(student.id),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  final SchoolClass classItem;
  final VoidCallback onDelete;

  const _DangerZoneSection({
    Key? key,
    required this.classItem,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Once you delete a class, there is no going back. Please be certain.',
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete Class'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DIALOGS ====================
class CreateClassDialog extends StatefulWidget {
  final ClassManagementProvider provider;
  final SchoolClass? existingClass;

  const CreateClassDialog({
    Key? key,
    required this.provider,
    this.existingClass,
  }) : super(key: key);

  @override
  _CreateClassDialogState createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _roomController = TextEditingController();
  bool _isLoading = false;

  // Add class number and section options to match your student creation
  final List<String> _classNumbers = List.generate(
    12,
    (index) => '${index + 1}',
  );
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];
  String? _selectedClassNumber;
  String? _selectedSection;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _isLoadingTeachers = false;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();

    if (widget.existingClass != null) {
      final nameParts = widget.existingClass!.name.split(' ');
      if (nameParts.length >= 2) {
        _selectedClassNumber = nameParts[1];
      }
      _sectionController.text = widget.existingClass!.section;
      _subjectController.text = widget.existingClass!.subject ?? '';
      _scheduleController.text = widget.existingClass!.schedule ?? '';
      _roomController.text = widget.existingClass!.room ?? '';
    }
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      _teachers = await widget.provider.repository.fetchTeachers();
      _checkForDuplicateTeachers();
      // Auto-select first teacher if none selected
      if (_selectedTeacherId == null && _teachers.isNotEmpty) {
        _selectedTeacherId = _teachers.first['id'];
        _selectedTeacherName = _teachers.first['name'];
      }
    } catch (e) {
      print('Error loading teachers: $e');
    } finally {
      setState(() => _isLoadingTeachers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingClass != null ? 'Edit Class' : 'Create New Class',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClassNumber,
                decoration: InputDecoration(labelText: 'Class Number *'),
                items: List.generate(12, (index) => '${index + 1}').map((
                  number,
                ) {
                  return DropdownMenuItem(
                    value: number,
                    child: Text('Class $number'),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select class number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedClassNumber = value;
                  });
                },
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedSection,
                decoration: InputDecoration(labelText: 'Section *'),
                items: ['A', 'B', 'C', 'D', 'E'].map((section) {
                  return DropdownMenuItem(value: section, child: Text(section));
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select section';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value;
                  });
                },
              ),
              SizedBox(height: 16),
              _isLoadingTeachers
                  ? CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedTeacherId,
                      decoration: InputDecoration(labelText: 'Teacher *'),
                      items: [
                        // Add a default option first
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('Select a teacher'),
                          enabled: false,
                        ),
                        // Then add unique teachers
                        ..._getUniqueTeachers(
                          _teachers,
                        ).map<DropdownMenuItem<String>>((teacher) {
                          final teacherId = teacher['id'] as String? ?? '';
                          final teacherName =
                              teacher['name'] as String? ?? 'Unknown';

                          return DropdownMenuItem<String>(
                            value: teacherId,
                            child: Text(teacherName),
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a teacher';
                        }
                        return null;
                      },
                      onChanged: (String? value) {
                        setState(() {
                          _selectedTeacherId = value;
                          if (value != null) {
                            final teacher = _teachers.firstWhere(
                              (t) => t['id'] == value,
                              orElse: () => {},
                            );
                            _selectedTeacherName =
                                teacher['name'] as String? ?? 'Unknown';
                          }
                        });
                      },
                    ),
              SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject (Optional)'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: InputDecoration(labelText: 'Schedule (Optional)'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room Number (Optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? CircularProgressIndicator()
              : Text(widget.existingClass != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassNumber == null || _selectedSection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select both class number and section'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final schoolClass = SchoolClass(
          id: widget.existingClass?.id ?? '',
          name: 'Class $_selectedClassNumber',
          section: _selectedSection!,
          subject: _subjectController.text.isNotEmpty
              ? _subjectController.text
              : null,
          schedule: _scheduleController.text.isNotEmpty
              ? _scheduleController.text
              : null,
          room: _roomController.text.isNotEmpty ? _roomController.text : null,
          teacherId: _selectedTeacherId!,
          teacherName: _selectedTeacherName!,
          studentCount: widget.existingClass?.studentCount ?? 0,
          createdBy:
              widget.existingClass?.createdBy ??
              FirebaseAuth.instance.currentUser!.uid,
          createdAt: widget.existingClass?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.existingClass != null) {
          final provider = widget.provider;
          await provider.updateClass(schoolClass, widget.existingClass!.id);
        } else {
          await widget.provider.createClass(schoolClass);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingClass != null
                  ? 'Class updated successfully'
                  : 'Class created successfully',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save class: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getUniqueTeachers(
    List<Map<String, dynamic>> teachers,
  ) {
    final uniqueTeachers = <String, Map<String, dynamic>>{};

    for (final teacher in teachers) {
      final teacherId = teacher['id'] as String?;
      if (teacherId != null && teacherId.isNotEmpty) {
        uniqueTeachers[teacherId] = teacher;
      }
    }

    return uniqueTeachers.values.toList();
  }

  void _checkForDuplicateTeachers() {
    final teacherIds = <String>{};
    final duplicates = <String>[];

    for (final teacher in _teachers) {
      final teacherId = teacher['id'] as String?;
      if (teacherId != null) {
        if (teacherIds.contains(teacherId)) {
          duplicates.add(teacherId);
        } else {
          teacherIds.add(teacherId);
        }
      }
    }

    if (duplicates.isNotEmpty) {
      print('DEBUG: Found duplicate teacher IDs: $duplicates');
    } else {
      print('DEBUG: No duplicate teacher IDs found');
    }
  }
}

class AddStudentDialog extends StatefulWidget {
  final ClassManagementProvider provider;
  final String classId;

  const AddStudentDialog({
    Key? key,
    required this.provider,
    required this.classId,
  }) : super(key: key);

  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
      _searchDebounce = Timer(
        const Duration(milliseconds: 500),
        _performSearch,
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await widget.provider.repository.searchStudents(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching students: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Student to Class',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Students',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_isSearching)
                Center(child: CircularProgressIndicator())
              else if (_searchResults.isEmpty &&
                  _searchController.text.isNotEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No students found'),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(student['name'] ?? 'Unknown'),
                          subtitle: Text(student['email'] ?? ''),
                          onTap: () => _addStudent(student),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addStudent(Map<String, dynamic> student) async {
    try {
      await widget.provider.repository.addStudentToClass(
        widget.classId,
        student,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Student added to class')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add student: $e')));
    }
  }
}

class ClassSearchDelegate extends SearchDelegate {
  final ClassManagementProvider provider;

  ClassSearchDelegate(this.provider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = provider.classes.where((classItem) {
      return classItem.name.toLowerCase().contains(query.toLowerCase()) ||
          classItem.section.toLowerCase().contains(query.toLowerCase()) ||
          (classItem.subject?.toLowerCase() ?? '').contains(
            query.toLowerCase(),
          ) ||
          (classItem.teacherName.toLowerCase()).contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final classItem = results[index];
        return ListTile(
          title: Text('${classItem.name} - ${classItem.section}'),
          subtitle: Text(
            '${classItem.teacherName ?? "No Teacher"} - ${classItem.studentCount} students',
          ),
          onTap: () {
            close(context, classItem);
          },
        );
      },
    );
  }
}
