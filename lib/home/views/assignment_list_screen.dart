// // screens/assignment_list_screen.dart
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_quill/quill_delta.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:projects/auth/repositories/assignment_repository.dart';
// import 'package:projects/models/assigment_model.dart';
// import 'package:provider/provider.dart';

// class AssignmentListScreen extends StatefulWidget {
//   final String schoolId;
//   final String userRole;
//   final String userId;

//   const AssignmentListScreen({
//     Key? key,
//     required this.schoolId,
//     required this.userRole,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   _AssignmentListScreenState createState() => _AssignmentListScreenState();
// }

// class _AssignmentListScreenState extends State<AssignmentListScreen> {
//   final _searchController = TextEditingController();
//   late AssignmentProvider _provider;

//   @override
//   void initState() {
//     super.initState();
//     _provider = AssignmentProvider(
//       repository: AssignmentRepository(schoolId: widget.schoolId),
//       userRole: widget.userRole,
//       userId: widget.userId,
//     );
//     _provider.loadAssignments();

//     _searchController.addListener(() {
//       _provider.setSearchQuery(_searchController.text);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Assignments'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.search),
//               onPressed: () => _showSearchDialog(),
//             ),
//             IconButton(
//               icon: const Icon(Icons.filter_list),
//               onPressed: () => _showFilterDialog(),
//             ),
//           ],
//         ),
//         body: Consumer<AssignmentProvider>(
//           builder: (context, provider, child) {
//             if (provider.isLoading && provider.assignments.isEmpty) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (provider.assignments.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.assignment, size: 64, color: Colors.grey),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'No assignments found',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     if (widget.userRole == 'teacher')
//                       TextButton(
//                         onPressed: _createNewAssignment,
//                         child: const Text('Create Your First Assignment'),
//                       ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               itemCount: provider.assignments.length,
//               itemBuilder: (context, index) {
//                 final assignment = provider.assignments[index];
//                 return _AssignmentListItem(
//                   assignment: assignment,
//                   userRole: widget.userRole,
//                   onTap: () => _viewAssignmentDetails(assignment),
//                 );
//               },
//             );
//           },
//         ),
//         floatingActionButton: widget.userRole == 'teacher'
//             ? FloatingActionButton(
//                 onPressed: _createNewAssignment,
//                 child: const Icon(Icons.add),
//               )
//             : null,
//       ),
//     );
//   }

//   void _createNewAssignment() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AssignmentEditorScreen(
//           schoolId: widget.schoolId,
//           userId: widget.userId,
//         ),
//       ),
//     );
//   }

//   void _viewAssignmentDetails(Assignment assignment) {
//     // Navigate to assignment detail view
//   }

//   void _showSearchDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Search Assignments'),
//         content: TextField(
//           controller: _searchController,
//           decoration: const InputDecoration(
//             hintText: 'Search by title or instructions',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               _provider.setSearchQuery(_searchController.text);
//               Navigator.pop(context);
//             },
//             child: const Text('Search'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Filter Assignments'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Status filter dropdown
//             // Class filter dropdown
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Apply'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // class AssignmentEditorScreen extends StatefulWidget {
// //   final String schoolId;
// //   final String userId;
// //   final Assignment? existingAssignment;

// //   const AssignmentEditorScreen({
// //     Key? key,
// //     required this.schoolId,
// //     required this.userId,
// //     this.existingAssignment,
// //   }) : super(key: key);

// //   @override
// //   _AssignmentEditorScreenState createState() => _AssignmentEditorScreenState();
// // }

// // class _AssignmentEditorScreenState extends State<AssignmentEditorScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _titleController = TextEditingController();
// //   final quill.QuillController _quillController = quill.QuillController.basic();
// //   final _pointsController = TextEditingController();
// //   DateTime? _dueDate;
// //   String? _selectedClassId;
// //   List<String> _attachmentUrls = [];
// //   bool _isLoading = false;

// //   late AssignmentProvider _provider;
// //   List<Map<String, dynamic>> _teacherClasses = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _provider = AssignmentProvider(
// //       repository: AssignmentRepository(schoolId: widget.schoolId),
// //       userRole: 'teacher',
// //       userId: widget.userId,
// //     );

// //     _loadTeacherClasses();

// //     if (widget.existingAssignment != null) {
// //       _titleController.text = widget.existingAssignment!.title;
// //       _quillController.document = quill.Document.fromDelta(
// //         quill.Delta()..insert(widget.existingAssignment!.instructions),
// //       );
// //       _pointsController.text = widget.existingAssignment!.pointsPossible
// //           .toString();
// //       _dueDate = widget.existingAssignment!.dueDate;
// //       _selectedClassId = widget.existingAssignment!.classId;
// //       _attachmentUrls = widget.existingAssignment!.attachmentUrls;
// //     }
// //   }

// //   Future<void> _loadTeacherClasses() async {
// //     // Load classes where the user is the teacher
// //     // This would come from your existing class repository
// //     setState(() {
// //       _teacherClasses = [
// //         {'id': 'class_10_a', 'name': 'Class 10 A'},
// //         {'id': 'class_10_b', 'name': 'Class 10 B'},
// //       ];
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return ChangeNotifierProvider.value(
// //       value: _provider,
// //       child: Scaffold(
// //         appBar: AppBar(
// //           title: Text(
// //             widget.existingAssignment != null
// //                 ? 'Edit Assignment'
// //                 : 'Create Assignment',
// //           ),
// //           actions: [
// //             if (widget.existingAssignment != null &&
// //                 widget.existingAssignment!.canEdit)
// //               IconButton(
// //                 icon: const Icon(Icons.delete),
// //                 onPressed: _deleteAssignment,
// //               ),
// //             IconButton(icon: const Icon(Icons.save), onPressed: _saveAsDraft),
// //           ],
// //         ),
// //         body: _isLoading
// //             ? const Center(child: CircularProgressIndicator())
// //             : SingleChildScrollView(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Form(
// //                   key: _formKey,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Class selector
// //                       DropdownButtonFormField<String>(
// //                         value: _selectedClassId,
// //                         decoration: const InputDecoration(labelText: 'Class *'),
// //                         items: _teacherClasses.map((classInfo) {
// //                           return DropdownMenuItem<String>(
// //                             value: classInfo['id'],
// //                             child: Text(classInfo['name']),
// //                           );
// //                         }).toList(),
// //                         validator: (value) {
// //                           if (value == null || value.isEmpty) {
// //                             return 'Please select a class';
// //                           }
// //                           return null;
// //                         },
// //                         onChanged: (value) {
// //                           setState(() {
// //                             _selectedClassId = value;
// //                           });
// //                         },
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Title field
// //                       TextFormField(
// //                         controller: _titleController,
// //                         decoration: const InputDecoration(labelText: 'Title *'),
// //                         validator: (value) {
// //                           if (value == null || value.isEmpty) {
// //                             return 'Please enter a title';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Instructions (Rich text editor)
// //                       const Text(
// //                         'Instructions *',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Container(
// //                         decoration: BoxDecoration(
// //                           border: Border.all(color: Colors.grey),
// //                           borderRadius: BorderRadius.circular(4),
// //                         ),
// //                         child: quill.QuillToolbar.basic(
// //                           controller: _quillController,
// //                         ),
// //                       ),
// //                       Container(
// //                         height: 200,
// //                         decoration: BoxDecoration(
// //                           border: Border.all(color: Colors.grey),
// //                           borderRadius: BorderRadius.circular(4),
// //                         ),
// //                         child: quill.QuillEditor(
// //                           controller: _quillController,
// //                           scrollController: ScrollController(),
// //                           scrollable: true,
// //                           focusNode: FocusNode(),
// //                           autoFocus: false,
// //                           readOnly: false,
// //                           expands: false,
// //                           padding: const EdgeInsets.all(8),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Due date
// //                       Row(
// //                         children: [
// //                           Expanded(
// //                             child: TextFormField(
// //                               decoration: const InputDecoration(
// //                                 labelText: 'Due Date *',
// //                               ),
// //                               readOnly: true,
// //                               controller: TextEditingController(
// //                                 text: _dueDate != null
// //                                     ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
// //                                     : '',
// //                               ),
// //                               validator: (value) {
// //                                 if (_dueDate == null) {
// //                                   return 'Please select a due date';
// //                                 }
// //                                 return null;
// //                               },
// //                             ),
// //                           ),
// //                           IconButton(
// //                             icon: const Icon(Icons.calendar_today),
// //                             onPressed: _selectDueDate,
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Points possible
// //                       TextFormField(
// //                         controller: _pointsController,
// //                         decoration: const InputDecoration(
// //                           labelText: 'Points Possible',
// //                         ),
// //                         keyboardType: TextInputType.number,
// //                         validator: (value) {
// //                           if (value != null && value.isNotEmpty) {
// //                             final points = int.tryParse(value);
// //                             if (points == null || points < 0) {
// //                               return 'Please enter a valid number';
// //                             }
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Attachments
// //                       const Text(
// //                         'Attachments',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Wrap(
// //                         spacing: 8,
// //                         children: [
// //                           ..._attachmentUrls.map(
// //                             (url) => Chip(
// //                               label: Text(url.split('/').last),
// //                               onDeleted: () => _removeAttachment(url),
// //                             ),
// //                           ),
// //                           IconButton(
// //                             icon: const Icon(Icons.attach_file),
// //                             onPressed: _addAttachment,
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 24),

// //                       // Action buttons
// //                       Row(
// //                         children: [
// //                           Expanded(
// //                             child: ElevatedButton(
// //                               onPressed: _saveAsDraft,
// //                               child: const Text('Save as Draft'),
// //                             ),
// //                           ),
// //                           const SizedBox(width: 16),
// //                           Expanded(
// //                             child: ElevatedButton(
// //                               onPressed: _publishAssignment,
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.green,
// //                               ),
// //                               child: const Text('Publish'),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //       ),
// //     );
// //   }

// //   Future<void> _selectDueDate() async {
// //     final date = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime.now(),
// //       lastDate: DateTime.now().add(const Duration(days: 365)),
// //     );

// //     if (date != null) {
// //       final time = await showTimePicker(
// //         context: context,
// //         initialTime: TimeOfDay.now(),
// //       );

// //       if (time != null) {
// //         setState(() {
// //           _dueDate = DateTime(
// //             date.year,
// //             date.month,
// //             date.day,
// //             time.hour,
// //             time.minute,
// //           );
// //         });
// //       }
// //     }
// //   }

// //   Future<void> _addAttachment() async {
// //     final picker = ImagePicker();
// //     final file = await picker.pickImage(source: ImageSource.gallery);

// //     if (file != null) {
// //       setState(() => _isLoading = true);

// //       try {
// //         final downloadUrl = await _provider.uploadAttachment(
// //           widget.existingAssignment?.id ?? 'temp',
// //           File(file.path),
// //         );

// //         setState(() {
// //           _attachmentUrls.add(downloadUrl);
// //           _isLoading = false;
// //         });
// //       } catch (e) {
// //         setState(() => _isLoading = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to upload attachment: $e')),
// //         );
// //       }
// //     }
// //   }

// //   void _removeAttachment(String url) {
// //     setState(() {
// //       _attachmentUrls.remove(url);
// //     });
// //   }

// //   Future<void> _saveAsDraft() async {
// //     if (!_validateForm()) return;

// //     setState(() => _isLoading = true);

// //     try {
// //       final assignment = Assignment(
// //         id: widget.existingAssignment?.id ?? '',
// //         schoolId: widget.schoolId,
// //         title: _titleController.text,
// //         instructions: _quillController.document.toPlainText(),
// //         classId: _selectedClassId!,
// //         className: _teacherClasses.firstWhere(
// //           (c) => c['id'] == _selectedClassId,
// //         )['name'],
// //         teacherId: widget.userId,
// //         teacherName: 'Teacher Name', // Get from user repository
// //         dueDate: _dueDate!,
// //         pointsPossible: int.tryParse(_pointsController.text) ?? 0,
// //         status: AssignmentStatus.draft,
// //         attachmentUrls: _attachmentUrls,
// //         createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
// //         updatedAt: DateTime.now(),
// //       );

// //       if (widget.existingAssignment != null) {
// //         await _provider.updateAssignment(assignment);
// //       } else {
// //         await _provider.createAssignment(assignment);
// //       }

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Assignment saved as draft')),
// //       );

// //       Navigator.pop(context);
// //     } catch (e) {
// //       setState(() => _isLoading = false);
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Failed to save assignment: $e')));
// //     }
// //   }

// //   Future<void> _publishAssignment() async {
// //     if (!_validateForm()) return;

// //     setState(() => _isLoading = true);

// //     try {
// //       final assignment = Assignment(
// //         id: widget.existingAssignment?.id ?? '',
// //         schoolId: widget.schoolId,
// //         title: _titleController.text,
// //         instructions: _quillController.document.toPlainText(),
// //         classId: _selectedClassId!,
// //         className: _teacherClasses.firstWhere(
// //           (c) => c['id'] == _selectedClassId,
// //         )['name'],
// //         teacherId: widget.userId,
// //         teacherName: 'Teacher Name', // Get from user repository
// //         dueDate: _dueDate!,
// //         pointsPossible: int.tryParse(_pointsController.text) ?? 0,
// //         status: AssignmentStatus.published,
// //         attachmentUrls: _attachmentUrls,
// //         createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
// //         updatedAt: DateTime.now(),
// //       );

// //       String assignmentId;
// //       if (widget.existingAssignment != null) {
// //         assignmentId = assignment.id;
// //         await _provider.updateAssignment(assignment);
// //       } else {
// //         assignmentId = await _provider.createAssignment(assignment);
// //       }

// //       // Send notifications to students
// //       await _provider.sendAssignmentNotification(
// //         assignmentId,
// //         _selectedClassId!,
// //       );

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Assignment published successfully')),
// //       );

// //       Navigator.pop(context);
// //     } catch (e) {
// //       setState(() => _isLoading = false);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to publish assignment: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _deleteAssignment() async {
// //     final confirmed = await showDialog<bool>(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Delete Assignment'),
// //         content: const Text('Are you sure you want to delete this assignment?'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, false),
// //             child: const Text('Cancel'),
// //           ),
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, true),
// //             child: const Text('Delete'),
// //           ),
// //         ],
// //       ),
// //     );

// //     if (confirmed == true) {
// //       setState(() => _isLoading = true);

// //       try {
// //         await _provider.deleteAssignment(widget.existingAssignment!.id);

// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text('Assignment deleted')));

// //         Navigator.pop(context);
// //       } catch (e) {
// //         setState(() => _isLoading = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to delete assignment: $e')),
// //         );
// //       }
// //     }
// //   }

// //   bool _validateForm() {
// //     if (!_formKey.currentState!.validate()) return false;
// //     if (_selectedClassId == null) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text('Please select a class')));
// //       return false;
// //     }
// //     if (_dueDate == null) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
// //       return false;
// //     }
// //     return true;
// //   }
// // }

// class AssignmentProvider with ChangeNotifier {
//   final AssignmentRepository repository;
//   final String userRole;
//   final String userId;

//   List<Assignment> _assignments = [];
//   List<Assignment> _filteredAssignments = [];
//   bool _isLoading = false;
//   String _searchQuery = '';
//   String _statusFilter = 'all';
//   String _classFilter = 'all';

//   List<Assignment> get assignments => _filteredAssignments;
//   bool get isLoading => _isLoading;

//   AssignmentProvider({
//     required this.repository,
//     required this.userRole,
//     required this.userId,
//   });

//   Future<void> loadAssignments() async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final stream = userRole == 'admin'
//           ? repository.getAllAssignments()
//           : repository.getTeacherAssignments(userId);

//       stream.listen((assignments) {
//         _assignments = assignments;
//         _applyFilters();
//         _isLoading = false;
//         notifyListeners();
//       });
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       rethrow;
//     }
//   }

//   void setSearchQuery(String query) {
//     _searchQuery = query;
//     _applyFilters();
//   }

//   void setStatusFilter(String status) {
//     _statusFilter = status;
//     _applyFilters();
//   }

//   void setClassFilter(String classId) {
//     _classFilter = classId;
//     _applyFilters();
//   }

//   void _applyFilters() {
//     _filteredAssignments = _assignments.where((assignment) {
//       // Search filter
//       final matchesSearch =
//           _searchQuery.isEmpty ||
//           assignment.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           assignment.instructions.toLowerCase().contains(
//             _searchQuery.toLowerCase(),
//           );

//       // Status filter
//       final matchesStatus =
//           _statusFilter == 'all' ||
//           assignment.status.toString().split('.').last == _statusFilter;

//       // Class filter
//       final matchesClass =
//           _classFilter == 'all' || assignment.classId == _classFilter;

//       return matchesSearch && matchesStatus && matchesClass;
//     }).toList();

//     notifyListeners();
//   }

//   Future<String> createAssignment(Assignment assignment) async {
//     return await repository.createAssignment(assignment);
//   }

//   Future<void> updateAssignment(Assignment assignment) async {
//     await repository.updateAssignment(assignment);
//   }

//   Future<void> deleteAssignment(String assignmentId) async {
//     await repository.deleteAssignment(assignmentId);
//   }

//   Future<String> uploadAttachment(String assignmentId, File file) async {
//     return await repository.uploadAttachment(assignmentId, file);
//   }

//   Future<void> sendAssignmentNotification(
//     String assignmentId,
//     String classId,
//   ) async {
//     // This would integrate with your email service or notification system
//     final students = await repository.getClassStudents(classId);

//     // Send email notifications to each student
//     for (final student in students) {
//       await _sendEmailNotification(student['email'], student['name']);
//     }
//   }

//   Future<void> _sendEmailNotification(String email, String name) async {
//     // Implement email sending logic using your preferred service
//     // This could be Firebase Functions, SendGrid, etc.
//     print('Sending notification to $email for student $name');
//   }
// }

// class _AssignmentListItem extends StatelessWidget {
//   final Assignment assignment;
//   final String userRole;
//   final VoidCallback onTap;

//   const _AssignmentListItem({
//     Key? key,
//     required this.assignment,
//     required this.userRole,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: _getStatusColor(assignment.status),
//           child: Icon(_getStatusIcon(assignment.status), color: Colors.white),
//         ),
//         title: Text(
//           assignment.title,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Class: ${assignment.className}'),
//             Text('Due: ${_formatDate(assignment.dueDate)}'),
//             if (assignment.isOverdue)
//               const Text('Overdue', style: TextStyle(color: Colors.red)),
//           ],
//         ),
//         trailing: userRole == 'admin' ? const Icon(Icons.chevron_right) : null,
//         onTap: onTap,
//       ),
//     );
//   }

//   Color _getStatusColor(AssignmentStatus status) {
//     switch (status) {
//       case AssignmentStatus.published:
//         return Colors.green;
//       case AssignmentStatus.closed:
//         return Colors.grey;
//       case AssignmentStatus.draft:
//         return Colors.blue;
//     }
//   }

//   IconData _getStatusIcon(AssignmentStatus status) {
//     switch (status) {
//       case AssignmentStatus.published:
//         return Icons.public;
//       case AssignmentStatus.closed:
//         return Icons.lock;
//       case AssignmentStatus.draft:
//         return Icons.edit;
//     }
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }

// class AssignmentEditorScreen extends StatefulWidget {
//   final String schoolId;
//   final String userId;
//   final Assignment? existingAssignment;

//   const AssignmentEditorScreen({
//     Key? key,
//     required this.schoolId,
//     required this.userId,
//     this.existingAssignment,
//   }) : super(key: key);

//   @override
//   _AssignmentEditorScreenState createState() => _AssignmentEditorScreenState();
// }

// class _AssignmentEditorScreenState extends State<AssignmentEditorScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final QuillController _quillController = QuillController.basic();
//   final _pointsController = TextEditingController();
//   DateTime? _dueDate;
//   String? _selectedClassId;
//   List<String> _attachmentUrls = [];
//   bool _isLoading = false;

//   late AssignmentProvider _provider;
//   List<Map<String, dynamic>> _teacherClasses = [];

//   @override
//   void initState() {
//     super.initState();
//     _provider = AssignmentProvider(
//       repository: AssignmentRepository(schoolId: widget.schoolId),
//       userRole: 'teacher',
//       userId: widget.userId,
//     );

//     _loadTeacherClasses();

//     if (widget.existingAssignment != null) {
//       _titleController.text = widget.existingAssignment!.title;

//       // Load Quill content from JSON
//       try {
//         final document = Document.fromJson(
//           jsonDecode(widget.existingAssignment!.instructions),
//         );
//         _quillController.document = document;
//       } catch (e) {
//         // Fallback to plain text
//         _quillController.document = Document()
//           ..insert(0, widget.existingAssignment!.instructions);
//       }

//       _pointsController.text = widget.existingAssignment!.pointsPossible
//           .toString();
//       _dueDate = widget.existingAssignment!.dueDate;
//       _selectedClassId = widget.existingAssignment!.classId;
//       _attachmentUrls = widget.existingAssignment!.attachmentUrls;
//     }
//   }

//   Future<void> _loadTeacherClasses() async {
//     // Load classes where the user is the teacher
//     // This would come from your existing class repository
//     setState(() {
//       _teacherClasses = [
//         {'id': 'class_10_a', 'name': 'Class 10 A'},
//         {'id': 'class_10_b', 'name': 'Class 10 B'},
//       ];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             widget.existingAssignment != null
//                 ? 'Edit Assignment'
//                 : 'Create Assignment',
//           ),
//           actions: [
//             if (widget.existingAssignment != null &&
//                 widget.existingAssignment!.canEdit)
//               IconButton(
//                 icon: const Icon(Icons.delete),
//                 onPressed: _deleteAssignment,
//               ),
//             IconButton(icon: const Icon(Icons.save), onPressed: _saveAsDraft),
//           ],
//         ),
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Class selector
//                       DropdownButtonFormField<String>(
//                         value: _selectedClassId,
//                         decoration: const InputDecoration(labelText: 'Class *'),
//                         items: _teacherClasses.map((classInfo) {
//                           return DropdownMenuItem<String>(
//                             value: classInfo['id'],
//                             child: Text(classInfo['name']),
//                           );
//                         }).toList(),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please select a class';
//                           }
//                           return null;
//                         },
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedClassId = value;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Title field
//                       TextFormField(
//                         controller: _titleController,
//                         decoration: const InputDecoration(labelText: 'Title *'),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a title';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Instructions (Rich text editor)
//                       const Text(
//                         'Instructions *',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),

//                       // Quill Toolbar
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: QuillToolbar.basic(controller: _quillController),
//                       ),

//                       // Quill Editor
//                       Container(
//                         height: 200,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: QuillEditor(
//                           controller: _quillController,
//                           scrollController: ScrollController(),
//                           scrollable: true,
//                           focusNode: FocusNode(),
//                           autoFocus: false,
//                           readOnly: false,
//                           expands: false,
//                           padding: const EdgeInsets.all(8),
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Due date
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               decoration: const InputDecoration(
//                                 labelText: 'Due Date *',
//                               ),
//                               readOnly: true,
//                               controller: TextEditingController(
//                                 text: _dueDate != null
//                                     ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
//                                     : '',
//                               ),
//                               validator: (value) {
//                                 if (_dueDate == null) {
//                                   return 'Please select a due date';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.calendar_today),
//                             onPressed: _selectDueDate,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),

//                       // Points possible
//                       TextFormField(
//                         controller: _pointsController,
//                         decoration: const InputDecoration(
//                           labelText: 'Points Possible',
//                         ),
//                         keyboardType: TextInputType.number,
//                         validator: (value) {
//                           if (value != null && value.isNotEmpty) {
//                             final points = int.tryParse(value);
//                             if (points == null || points < 0) {
//                               return 'Please enter a valid number';
//                             }
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Attachments
//                       const Text(
//                         'Attachments',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children: [
//                           ..._attachmentUrls.map(
//                             (url) => Chip(
//                               label: Text(url.split('/').last),
//                               onDeleted: () => _removeAttachment(url),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.attach_file),
//                             onPressed: _addAttachment,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),

//                       // Action buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: _saveAsDraft,
//                               child: const Text('Save as Draft'),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: _publishAssignment,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                               ),
//                               child: const Text('Publish'),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Future<void> _selectDueDate() async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );

//     if (date != null) {
//       final time = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );

//       if (time != null) {
//         setState(() {
//           _dueDate = DateTime(
//             date.year,
//             date.month,
//             date.day,
//             time.hour,
//             time.minute,
//           );
//         });
//       }
//     }
//   }

//   Future<void> _addAttachment() async {
//     final picker = ImagePicker();
//     final file = await picker.pickImage(source: ImageSource.gallery);

//     if (file != null) {
//       setState(() => _isLoading = true);

//       try {
//         final downloadUrl = await _provider.uploadAttachment(
//           widget.existingAssignment?.id ?? 'temp',
//           File(file.path),
//         );

//         setState(() {
//           _attachmentUrls.add(downloadUrl);
//           _isLoading = false;
//         });
//       } catch (e) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to upload attachment: $e')),
//         );
//       }
//     }
//   }

//   void _removeAttachment(String url) {
//     setState(() {
//       _attachmentUrls.remove(url);
//     });
//   }

//   Future<void> _saveAsDraft() async {
//     if (!_validateForm()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Convert Quill content to JSON
//       final instructionsJson = jsonEncode(
//         _quillController.document.toDelta().toJson(),
//       );

//       final assignment = Assignment(
//         id: widget.existingAssignment?.id ?? '',
//         schoolId: widget.schoolId,
//         title: _titleController.text,
//         instructions: instructionsJson,
//         classId: _selectedClassId!,
//         className: _teacherClasses.firstWhere(
//           (c) => c['id'] == _selectedClassId,
//         )['name'],
//         teacherId: widget.userId,
//         teacherName: 'Teacher Name', // Get from user repository
//         dueDate: _dueDate!,
//         pointsPossible: int.tryParse(_pointsController.text) ?? 0,
//         status: AssignmentStatus.draft,
//         attachmentUrls: _attachmentUrls,
//         createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//       );

//       if (widget.existingAssignment != null) {
//         await _provider.updateAssignment(assignment);
//       } else {
//         await _provider.createAssignment(assignment);
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Assignment saved as draft')),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to save assignment: $e')));
//     }
//   }

//   Future<void> _publishAssignment() async {
//     if (!_validateForm()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Convert Quill content to JSON
//       final instructionsJson = jsonEncode(
//         _quillController.document.toDelta().toJson(),
//       );

//       final assignment = Assignment(
//         id: widget.existingAssignment?.id ?? '',
//         schoolId: widget.schoolId,
//         title: _titleController.text,
//         instructions: instructionsJson,
//         classId: _selectedClassId!,
//         className: _teacherClasses.firstWhere(
//           (c) => c['id'] == _selectedClassId,
//         )['name'],
//         teacherId: widget.userId,
//         teacherName: 'Teacher Name', // Get from user repository
//         dueDate: _dueDate!,
//         pointsPossible: int.tryParse(_pointsController.text) ?? 0,
//         status: AssignmentStatus.published,
//         attachmentUrls: _attachmentUrls,
//         createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//       );

//       String assignmentId;
//       if (widget.existingAssignment != null) {
//         assignmentId = assignment.id;
//         await _provider.updateAssignment(assignment);
//       } else {
//         assignmentId = await _provider.createAssignment(assignment);
//       }

//       // Send notifications to students
//       await _provider.sendAssignmentNotification(
//         assignmentId,
//         _selectedClassId!,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Assignment published successfully')),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to publish assignment: $e')),
//       );
//     }
//   }

//   Future<void> _deleteAssignment() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Assignment'),
//         content: const Text('Are you sure you want to delete this assignment?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       setState(() => _isLoading = true);

//       try {
//         await _provider.deleteAssignment(widget.existingAssignment!.id);

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Assignment deleted')));

//         Navigator.pop(context);
//       } catch (e) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to delete assignment: $e')),
//         );
//       }
//     }
//   }

//   bool _validateForm() {
//     if (!_formKey.currentState!.validate()) return false;
//     if (_selectedClassId == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select a class')));
//       return false;
//     }
//     if (_dueDate == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
//       return false;
//     }
//     return true;
//   }
// }
