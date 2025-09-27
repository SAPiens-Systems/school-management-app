// student_directory_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/home/views/student_detail_screen.dart';
import 'package:provider/provider.dart';

// ==================== MODELS ====================
class Student {
  final String id;
  final String name;
  final String email;
  final String? studentId;
  final String classId;
  final String? className;
  final String? gender;
  final String? phone;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final String schoolId;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    required this.classId,
    this.className,
    this.gender,
    this.phone,
    this.dateOfBirth,
    required this.createdAt,
    required this.schoolId,
  });

  factory Student.fromFirestore(DocumentSnapshot doc, [String? className]) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ Handle both Timestamp and String dateOfBirth
    DateTime? dob;
    final rawDob = data['dateOfBirth'];
    if (rawDob != null) {
      if (rawDob is Timestamp) {
        dob = rawDob.toDate();
      } else if (rawDob is String) {
        try {
          dob = DateTime.parse(rawDob);
        } catch (_) {
          dob = null;
        }
      }
    }

    return Student(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      studentId: data['studentId'] as String?,
      classId: data['classId'] ?? '',
      className: className,
      gender: data['gender'] as String?,
      phone: data['phone'] as String?,
      dateOfBirth: dob,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      schoolId: data['schoolId'] ?? '',
    );
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}

// ==================== REPOSITORY ====================
class StudentDirectoryRepository {
  final FirebaseFirestore firestore;
  final String schoolId;

  StudentDirectoryRepository({
    required this.schoolId,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, String>> fetchClasses() async {
    try {
      final classesSnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .get();

      final classesMap = <String, String>{};
      for (final doc in classesSnapshot.docs) {
        final data = doc.data();
        classesMap[doc.id] = data['name'] as String? ?? doc.id;
      }
      return classesMap;
    } catch (e) {
      print('Error fetching classes: $e');
      return {};
    }
  }

  Stream<List<Student>> fetchStudents({
    String? classId,
    String? searchQuery,
    required Map<String, String> classesMap,
  }) {
    Query query = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students');

    // Apply class filter
    if (classId != null && classId != 'all') {
      query = query.where('classId', isEqualTo: classId);
    }

    // Apply search filter (only one orderBy)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.orderBy('name').startAt([searchQuery]).endAt([
        '$searchQuery\uf8ff',
      ]);
    } else {
      query = query.orderBy('name');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final student = Student.fromFirestore(doc);
        return Student(
          id: student.id,
          name: student.name,
          email: student.email,
          studentId: student.studentId,
          classId: student.classId,
          className: classesMap[student.classId] ?? student.classId,
          gender: student.gender,
          phone: student.phone,
          dateOfBirth: student.dateOfBirth,
          createdAt: student.createdAt,
          schoolId: schoolId,
        );
      }).toList();
    });
  }

  Future<String> exportStudentsToCsv(List<Student> students) async {
    final sb = StringBuffer();
    sb.writeln('Name,Email,Student ID,Class,Gender,Phone,Age');

    for (final student in students) {
      sb.writeln(
        [
          '"${student.name.replaceAll('"', '""')}"',
          '"${student.email.replaceAll('"', '""')}"',
          '"${student.studentId?.replaceAll('"', '""') ?? ""}"',
          '"${student.className?.replaceAll('"', '""') ?? student.classId}"',
          '"${student.gender ?? ""}"',
          '"${student.phone ?? ""}"',
          student.age.toString(),
        ].join(','),
      );
    }

    return sb.toString();
  }
}

// ==================== PROVIDER ====================
class StudentDirectoryProvider with ChangeNotifier {
  final StudentDirectoryRepository repository;
  final String userRole;

  List<Student> _students = [];
  Map<String, String> _classes = {};
  String _selectedClassId = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isExporting = false;
  final List<String> _selectedStudentIds = [];

  List<Student> get students => _students;
  Map<String, String> get classes => _classes;
  String get selectedClassId => _selectedClassId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  List<String> get selectedStudentIds => _selectedStudentIds;
  int get selectedCount => _selectedStudentIds.length;

  StudentDirectoryProvider({required this.repository, required this.userRole});

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _classes = await repository.fetchClasses();
    } catch (e) {
      print('Error loading classes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadStudents() {
    _isLoading = true;
    notifyListeners();

    repository
        .fetchStudents(
          classId: _selectedClassId,
          searchQuery: _searchQuery,
          classesMap: _classes,
        )
        .listen(
          (students) {
            _students = students;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void setClassFilter(String classId) {
    _selectedClassId = classId;
    _selectedStudentIds.clear();
    loadStudents();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _selectedStudentIds.clear();
    loadStudents();
  }

  void toggleStudentSelection(String studentId) {
    if (_selectedStudentIds.contains(studentId)) {
      _selectedStudentIds.remove(studentId);
    } else {
      _selectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  void selectAllStudents() {
    _selectedStudentIds.clear();
    _selectedStudentIds.addAll(_students.map((s) => s.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedStudentIds.clear();
    notifyListeners();
  }

  Future<void> exportToCsv() async {
    _isExporting = true;
    notifyListeners();

    try {
      final csvData = await repository.exportStudentsToCsv(_students);
      // Share or download the CSV file
      // This would typically use the share_plus package
      print('CSV Data:\n$csvData');

      // For web/download implementation, you'd use:
      // final blob = html.Blob([csvData], 'text/csv');
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // html.AnchorElement(href: url)
      //   ..setAttribute('download', 'students.csv')
      //   ..click();
    } catch (e) {
      print('Error exporting CSV: $e');
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}

// ==================== MAIN SCREEN ====================
class StudentDirectoryScreen extends StatefulWidget {
  final String schoolId;
  final String userRole;

  const StudentDirectoryScreen({
    Key? key,
    required this.schoolId,
    required this.userRole,
  }) : super(key: key);

  @override
  _StudentDirectoryScreenState createState() =>
      _StudentDirectoryScreenState(schoolId);
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  late StudentDirectoryProvider _provider;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  _StudentDirectoryScreenState(String schoolId);

  @override
  void initState() {
    super.initState();
    _provider = StudentDirectoryProvider(
      repository: StudentDirectoryRepository(schoolId: widget.schoolId),
      userRole: widget.userRole,
    );
    _provider.loadClasses();
    _provider.loadStudents();

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
          title: Text('Student Directory', style: GoogleFonts.lexend()),
          actions: [
            if (_provider.selectedCount > 0) ...[
              IconButton(
                icon: Icon(Icons.email),
                onPressed: () => _handleBulkEmail(),
                tooltip: 'Email Selected Students',
              ),
              IconButton(
                icon: Icon(Icons.group),
                onPressed: () => _handleBulkClassAssignment(),
                tooltip: 'Assign to Class',
              ),
            ],
            if (widget.userRole == 'admin') ...[
              IconButton(
                icon: Icon(Icons.download),
                onPressed: _provider.exportToCsv,
                tooltip: 'Export to CSV',
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
            _buildActiveFiltersIndicator(),
            Expanded(child: _buildStudentList()),
          ],
        ),
        floatingActionButton: _provider.selectedCount > 0
            ? FloatingActionButton(
                onPressed: _provider.clearSelection,
                child: Icon(Icons.clear),
                tooltip: 'Clear Selection',
              )
            : null,
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<StudentDirectoryProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Class Filter Dropdown
              DropdownButtonFormField<String>(
                value: provider.selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Filter by Class',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Classes')),
                  ...provider.classes.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }),
                ],
                onChanged: (value) {
                  provider.setClassFilter(value ?? 'all');
                },
              ),
              SizedBox(height: 16),
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Students',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFiltersIndicator() {
    return Consumer<StudentDirectoryProvider>(
      builder: (context, provider, child) {
        final filters = <String>[];

        if (provider.selectedClassId != 'all') {
          final className =
              provider.classes[provider.selectedClassId] ??
              provider.selectedClassId;
          filters.add('Class: $className');
        }

        if (provider.searchQuery.isNotEmpty) {
          filters.add('Search: "${provider.searchQuery}"');
        }

        if (filters.isEmpty) return SizedBox();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.filter_alt, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                filters.join(' | '),
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  provider.setClassFilter('all');
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
                child: Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentList() {
    return Consumer<StudentDirectoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.students.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  provider.searchQuery.isNotEmpty
                      ? 'No students found for "${provider.searchQuery}"'
                      : 'No students found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: provider.students.length,
          separatorBuilder: (context, index) => Divider(height: 1),
          itemBuilder: (context, index) {
            final student = provider.students[index];
            final isSelected = provider.selectedStudentIds.contains(student.id);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                child: Text(
                  student.initials,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                student.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student.studentId != null)
                    Text('ID: ${student.studentId}'),
                  Text('Class: ${student.className ?? student.classId}'),
                  if (student.email.isNotEmpty) Text('Email: ${student.email}'),
                ],
              ),
              trailing: widget.userRole == 'admin'
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        provider.toggleStudentSelection(student.id);
                      },
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(
                      studentId: student.id,
                      schoolId: student.schoolId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // void _viewStudentProfile(Student student) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Center(
  //               child: CircleAvatar(
  //                 radius: 40,
  //                 backgroundColor: Colors.blue,
  //                 child: Text(
  //                   student.initials,
  //                   style: TextStyle(fontSize: 24, color: Colors.white),
  //                 ),
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //             Text(
  //               student.name,
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //             if (student.studentId != null)
  //               Text('Student ID: ${student.studentId}'),
  //             Text('Class: ${student.className ?? student.classId}'),
  //             Text('Email: ${student.email}'),
  //             if (student.phone != null) Text('Phone: ${student.phone}'),
  //             if (student.gender != null) Text('Gender: ${student.gender}'),
  //             if (student.dateOfBirth != null)
  //               Text(
  //                 'Age: ${student.age} years (${DateFormat('yyyy-MM-dd').format(student.dateOfBirth!)})',
  //               ),
  //             SizedBox(height: 16),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 ElevatedButton.icon(
  //                   onPressed: () => _sendEmail(student.email),
  //                   icon: Icon(Icons.email),
  //                   label: Text('Email'),
  //                 ),
  //                 ElevatedButton.icon(
  //                   onPressed: () => _viewAttendance(student),
  //                   icon: Icon(Icons.assignment),
  //                   label: Text('Attendance'),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  void _sendEmail(String email) {
    // Implement email functionality
    print('Sending email to: $email');
  }

  void _viewAttendance(Student student) {
    // Implement attendance view
    print('Viewing attendance for: ${student.name}');
  }

  void _handleBulkEmail() {
    final selectedEmails = _provider.students
        .where((s) => _provider.selectedStudentIds.contains(s.id))
        .map((s) => s.email)
        .where((email) => email.isNotEmpty)
        .join(',');

    _sendEmail(selectedEmails);
  }

  void _handleBulkClassAssignment() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign ${_provider.selectedCount} Students to Class'),
          content: DropdownButtonFormField<String>(
            items: _provider.classes.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (classId) {
              // Implement bulk class assignment
              print('Assigning students to class: $classId');
              Navigator.pop(context);
            },
            decoration: InputDecoration(labelText: 'Select Class'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement assignment logic
                Navigator.pop(context);
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}
