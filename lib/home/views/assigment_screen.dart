// assignment_management_module.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ==================== MODELS ====================
enum AssignmentStatus { draft, published, closed }

class Assignment {
  final String id;
  final String schoolId;
  final String title;
  final String instructions;
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
  String get statusLabel {
    switch (status) {
      case AssignmentStatus.published:
        return isOverdue ? 'Overdue' : 'Published';
      case AssignmentStatus.closed:
        return 'Closed';
      case AssignmentStatus.draft:
        return 'Draft';
    }
  }

  Color get statusColor {
    switch (status) {
      case AssignmentStatus.published:
        return isOverdue ? Colors.red : Colors.green;
      case AssignmentStatus.closed:
        return Colors.grey;
      case AssignmentStatus.draft:
        return Colors.blue;
    }
  }
}

// ==================== REPOSITORY ====================
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

  Future<List<Map<String, dynamic>>> getTeacherClasses(String teacherId) async {
    final snapshot = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'section': data['section'] ?? '',
      };
    }).toList();
  }

  Future<String> createAssignment(Assignment assignment) async {
    final docRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc();

    await docRef.set(assignment.toMap()..['id'] = docRef.id);
    return docRef.id;
  }

  Future<void> updateAssignment(Assignment assignment) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc(assignment.id)
        .update(assignment.toMap());
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .doc(assignmentId)
        .delete();
  }

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

// ==================== PROVIDER ====================
class AssignmentProvider with ChangeNotifier {
  final AssignmentRepository repository;
  final String userRole;
  final String userId;
  final String userEmail;
  final String userName;

  List<Assignment> _assignments = [];
  List<Assignment> _filteredAssignments = [];
  List<Map<String, dynamic>> _teacherClasses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _classFilter = 'all';

  List<Assignment> get assignments => _filteredAssignments;
  List<Map<String, dynamic>> get teacherClasses => _teacherClasses;
  bool get isLoading => _isLoading;

  AssignmentProvider({
    required this.repository,
    required this.userRole,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  Future<void> loadAssignments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = userRole == 'admin'
          ? repository.getAllAssignments()
          : repository.getTeacherAssignments(userId);

      stream.listen((assignments) {
        _assignments = assignments;
        _applyFilters();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadTeacherClasses() async {
    if (userRole == 'teacher') {
      _teacherClasses = await repository.getTeacherClasses(userId);
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setClassFilter(String classId) {
    _classFilter = classId;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredAssignments = _assignments.where((assignment) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          assignment.title.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == 'all' ||
          assignment.status.toString().split('.').last == _statusFilter;

      final matchesClass =
          _classFilter == 'all' || assignment.classId == _classFilter;

      return matchesSearch && matchesStatus && matchesClass;
    }).toList();

    notifyListeners();
  }

  Future<String> createAssignment(Assignment assignment) async {
    return await repository.createAssignment(assignment);
  }

  Future<void> updateAssignment(Assignment assignment) async {
    await repository.updateAssignment(assignment);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await repository.deleteAssignment(assignmentId);
  }

  Future<String> uploadAttachment(String assignmentId, File file) async {
    return await repository.uploadAttachment(assignmentId, file);
  }

  Future<void> sendAssignmentNotifications(
    String assignmentId,
    String classId,
    String assignmentTitle,
  ) async {
    final students = await repository.getClassStudents(classId);

    // In a real implementation, this would call a Cloud Function or email service
    for (final student in students) {
      print(
        'Sending notification to ${student['email']} about assignment: $assignmentTitle',
      );
      // Implement actual email sending logic here
    }
  }
}

// ==================== UI SCREENS ====================
class AssignmentListScreen extends StatefulWidget {
  final String schoolId;
  final String userRole;
  final String userId;
  final String userEmail;
  final String userName;

  const AssignmentListScreen({
    Key? key,
    required this.schoolId,
    required this.userRole,
    required this.userId,
    required this.userEmail,
    required this.userName,
  }) : super(key: key);

  @override
  _AssignmentListScreenState createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  late AssignmentProvider _provider;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = AssignmentProvider(
      repository: AssignmentRepository(schoolId: widget.schoolId),
      userRole: widget.userRole,
      userId: widget.userId,
      userEmail: widget.userEmail,
      userName: widget.userName,
    );

    _provider.loadAssignments();
    if (widget.userRole == 'teacher') {
      _provider.loadTeacherClasses();
    }

    _searchController.addListener(() {
      _provider.setSearchQuery(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Consumer<AssignmentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.assignments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      provider._searchQuery.isNotEmpty
                          ? 'No assignments found for "${provider._searchQuery}"'
                          : 'No assignments found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (widget.userRole == 'teacher')
                      TextButton(
                        onPressed: _createNewAssignment,
                        child: const Text('Create Your Assignment'),
                      ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: provider.assignments.length,
              itemBuilder: (context, index) {
                final assignment = provider.assignments[index];
                return _AssignmentListItem(
                  assignment: assignment,
                  userRole: widget.userRole,
                  onTap: () => _viewAssignmentDetails(assignment),
                );
              },
            );
          },
        ),
        floatingActionButton: widget.userRole == 'teacher'
            ? FloatingActionButton(
                onPressed: _createNewAssignment,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  void _createNewAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentEditorScreen(
          schoolId: widget.schoolId,
          userId: widget.userId,
          userEmail: widget.userEmail,
          userName: widget.userName,
        ),
      ),
    );
  }

  void _viewAssignmentDetails(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class: ${assignment.className}'),
              Text('Due: ${_formatDate(assignment.dueDate)}'),
              Text('Status: ${assignment.statusLabel}'),
              const SizedBox(height: 16),
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(assignment.instructions),
              if (assignment.attachmentUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Attachments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...assignment.attachmentUrls
                    .map((url) => Text('- ${url.split('/').last}'))
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Assignments'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search by title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _provider.setSearchQuery(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Assignments'),
        content: Consumer<AssignmentProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                DropdownButtonFormField<String>(
                  value: provider._statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'published',
                      child: Text('Published'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    provider.setStatusFilter(value!);
                  },
                ),
                const SizedBox(height: 16),
                // Class filter (for teachers)
                if (widget.userRole == 'teacher' &&
                    provider.teacherClasses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: provider._classFilter,
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Classes'),
                      ),
                      ...provider.teacherClasses.map(
                        (classInfo) => DropdownMenuItem(
                          value: classInfo['id'],
                          child: Text(
                            '${classInfo['name']} ${classInfo['section']}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      provider.setClassFilter(value!);
                    },
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }
}

class _AssignmentListItem extends StatelessWidget {
  final Assignment assignment;
  final String userRole;
  final VoidCallback onTap;

  const _AssignmentListItem({
    Key? key,
    required this.assignment,
    required this.userRole,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment.statusColor,
          child: Icon(
            _getStatusIcon(assignment.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class: ${assignment.className}'),
            Text('Due: ${_formatDate(assignment.dueDate)}'),
            if (assignment.isOverdue)
              const Text('Overdue', style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: userRole == 'admin' ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.published:
        return Icons.public;
      case AssignmentStatus.closed:
        return Icons.lock;
      case AssignmentStatus.draft:
        return Icons.edit;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class AssignmentEditorScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String userEmail;
  final String userName;
  final Assignment? existingAssignment;

  const AssignmentEditorScreen({
    Key? key,
    required this.schoolId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.existingAssignment,
  }) : super(key: key);

  @override
  _AssignmentEditorScreenState createState() => _AssignmentEditorScreenState();
}

class _AssignmentEditorScreenState extends State<AssignmentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pointsController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedClassId;
  List<String> _attachmentUrls = [];
  bool _isLoading = false;

  late AssignmentProvider _provider;
  List<Map<String, dynamic>> _teacherClasses = [];

  @override
  void initState() {
    super.initState();
    _provider = AssignmentProvider(
      repository: AssignmentRepository(schoolId: widget.schoolId),
      userRole: 'teacher',
      userId: widget.userId,
      userEmail: widget.userEmail,
      userName: widget.userName,
    );

    _loadTeacherClasses();

    if (widget.existingAssignment != null) {
      _titleController.text = widget.existingAssignment!.title;
      _instructionsController.text = widget.existingAssignment!.instructions;
      _pointsController.text = widget.existingAssignment!.pointsPossible
          .toString();
      _dueDate = widget.existingAssignment!.dueDate;
      _selectedClassId = widget.existingAssignment!.classId;
      _attachmentUrls = widget.existingAssignment!.attachmentUrls;
    }
  }

  Future<void> _loadTeacherClasses() async {
    _teacherClasses = await _provider.repository.getTeacherClasses(
      widget.userId,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingAssignment != null
              ? 'Edit Assignment'
              : 'Create Assignment',
        ),
        actions: [
          if (widget.existingAssignment != null &&
              widget.existingAssignment!.canEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAssignment,
            ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAsDraft),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class selector
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(labelText: 'Class *'),
                      items: _teacherClasses.map((classInfo) {
                        return DropdownMenuItem<String>(
                          value: classInfo['id'],
                          child: Text(
                            '${classInfo['name']} ${classInfo['section']}',
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a class';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Instructions field
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions *',
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter instructions';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due date
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Due Date *',
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: _dueDate != null
                                  ? DateFormat(
                                      'MMM dd, yyyy - HH:mm',
                                    ).format(_dueDate!)
                                  : '',
                            ),
                            validator: (value) {
                              if (_dueDate == null) {
                                return 'Please select a due date';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDueDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Points possible
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points Possible',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final points = int.tryParse(value);
                          if (points == null || points < 0) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Attachments
                    const Text(
                      'Attachments',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._attachmentUrls.map(
                          (url) => Chip(
                            label: Text(url.split('/').last),
                            onDeleted: () => _removeAttachment(url),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _addAttachment,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveAsDraft,
                            child: const Text('Save as Draft'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _publishAssignment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Publish'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addAttachment() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isLoading = true);

      try {
        final downloadUrl = await _provider.uploadAttachment(
          widget.existingAssignment?.id ?? 'temp',
          File(file.path),
        );

        setState(() {
          _attachmentUrls.add(downloadUrl);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload attachment: $e')),
        );
      }
    }
  }

  void _removeAttachment(String url) {
    setState(() {
      _attachmentUrls.remove(url);
    });
  }

  Future<void> _saveAsDraft() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final classInfo = _teacherClasses.firstWhere(
        (c) => c['id'] == _selectedClassId,
      );

      final assignment = Assignment(
        id: widget.existingAssignment?.id ?? '',
        schoolId: widget.schoolId,
        title: _titleController.text,
        instructions: _instructionsController.text,
        classId: _selectedClassId!,
        className: '${classInfo['name']} ${classInfo['section']}',
        teacherId: widget.userId,
        teacherName: widget.userName,
        dueDate: _dueDate!,
        pointsPossible: int.tryParse(_pointsController.text) ?? 0,
        status: AssignmentStatus.draft,
        attachmentUrls: _attachmentUrls,
        createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingAssignment != null) {
        await _provider.updateAssignment(assignment);
      } else {
        await _provider.createAssignment(assignment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment saved as draft')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save assignment: $e')));
    }
  }

  Future<void> _publishAssignment() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final classInfo = _teacherClasses.firstWhere(
        (c) => c['id'] == _selectedClassId,
      );

      final assignment = Assignment(
        id: widget.existingAssignment?.id ?? '',
        schoolId: widget.schoolId,
        title: _titleController.text,
        instructions: _instructionsController.text,
        classId: _selectedClassId!,
        className: '${classInfo['name']} ${classInfo['section']}',
        teacherId: widget.userId,
        teacherName: widget.userName,
        dueDate: _dueDate!,
        pointsPossible: int.tryParse(_pointsController.text) ?? 0,
        status: AssignmentStatus.published,
        attachmentUrls: _attachmentUrls,
        createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String assignmentId;
      if (widget.existingAssignment != null) {
        assignmentId = assignment.id;
        await _provider.updateAssignment(assignment);
      } else {
        assignmentId = await _provider.createAssignment(assignment);
      }

      // Send notifications to students
      await _provider.sendAssignmentNotifications(
        assignmentId,
        _selectedClassId!,
        assignment.title,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment published successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish assignment: $e')),
      );
    }
  }

  Future<void> _deleteAssignment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure you want to delete this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _provider.deleteAssignment(widget.existingAssignment!.id);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assignment deleted')));

        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete assignment: $e')),
        );
      }
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return false;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
      return false;
    }
    if (_dueDate!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date must be in the future')),
      );
      return false;
    }
    return true;
  }
}
