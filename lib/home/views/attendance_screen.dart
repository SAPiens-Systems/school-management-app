// staff_attendance_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// -----------------------------
// Models & Enums
// -----------------------------

enum AttendanceStatus { present, absent, late, halfDay, unknown }

extension AttendanceStatusExt on AttendanceStatus {
  String get key {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.halfDay:
        return 'halfDay';
      default:
        return 'unknown';
    }
  }

  static AttendanceStatus fromKey(String? k) {
    switch (k) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'halfDay':
        return AttendanceStatus.halfDay;
      default:
        return AttendanceStatus.unknown;
    }
  }
}

class StudentItem {
  final String id; // studentId
  final String name;
  final String? rollNumber;
  final String classId;

  StudentItem({
    required this.id,
    required this.name,
    this.rollNumber,
    required this.classId,
  });

  factory StudentItem.fromFirestore(DocumentSnapshot doc, String classId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentItem(
      id: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Unknown') as String,
      rollNumber: data['rollNumber'] as String?,
      classId: classId,
    );
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  AttendanceStatus status;
  final String classId;
  final String? markedBy;
  final Timestamp? markedAt;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.classId,
    this.markedBy,
    this.markedAt,
  });

  Map<String, dynamic> toFirestoreMap(String currentUid) {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'status': status.key,
      'markedBy': currentUid,
      'markedAt': FieldValue.serverTimestamp(),
    };
  }
}

// -----------------------------
// Repository: Firestore interactions
// -----------------------------

class AttendanceRepository {
  final FirebaseFirestore firestore;
  AttendanceRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  // Fetch classes for the school
  Stream<List<QueryDocumentSnapshot>> classesStream(String schoolId) {
    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs);
  }

  // Fetch students for a class
  Future<List<StudentItem>> fetchStudents(
    String schoolId,
    String classId,
  ) async {
    try {
      // Query students where classId matches
      final snap = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .where('classId', isEqualTo: classId)
          .orderBy('name')
          .get();

      return snap.docs
          .map((d) => StudentItem.fromFirestore(d, classId))
          .toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // Stream attendance data for a date/class
  Stream<DocumentSnapshot> attendanceStream(
    String schoolId,
    String classId,
    String dateKey,
  ) {
    return firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .doc(dateKey)
        .snapshots();
  }

  // Check if attendance exists for a date/class
  Future<bool> doesAttendanceExist(
    String schoolId,
    String dateKey,
    String classId,
  ) async {
    final doc = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .doc(dateKey)
        .get();

    return doc.exists && (doc.data())?.isNotEmpty == true;
  }

  // Get last marked metadata
  Future<Map<String, dynamic>?> fetchAttendanceMeta(
    String schoolId,
    String dateKey,
    String classId,
  ) async {
    final docRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .doc(dateKey);
    final doc = await docRef.get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    return {'by': data['markedBy'], 'at': data['markedAt']};
  }

  // Write only diffs using a batch
  Future<void> submitAttendanceChanges({
    required String schoolId,
    required String dateKey,
    required String classId,
    required String staffUid,
    required Map<String, AttendanceRecord> changedRecords,
    required List<StudentItem> allStudents, // 👈 pass full student list
    required Map<String, AttendanceStatus>
    currentSelections, // 👈 pass current state
  }) async {
    final attendanceDocRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .doc(dateKey);

    // Prepare the base data
    final attendanceData = {
      'classId': classId,
      'date': dateKey,
      'markedBy': staffUid,
      'markedAt': FieldValue.serverTimestamp(),
    };

    if (changedRecords.isEmpty) {
      // 👇 New attendance case: write all students with currentSelections
      for (final s in allStudents) {
        final status = currentSelections[s.id] ?? AttendanceStatus.present;
        attendanceData[s.id] = status.key;
        attendanceData['${s.id}_name'] = s.name;
      }
    } else {
      // 👇 Existing attendance: write only changed records
      changedRecords.forEach((studentId, rec) {
        attendanceData[studentId] = rec.status.key;
        attendanceData['${studentId}_name'] = rec.studentName;
      });
    }

    await attendanceDocRef.set(attendanceData, SetOptions(merge: true));
  }

  // Helper: export snapshot to CSV string
  Future<String> exportAttendanceToCsv({
    required String schoolId,
    required String dateKey,
    required String classId,
  }) async {
    final doc = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .doc(dateKey)
        .get();

    if (!doc.exists) return '';

    final data = doc.data() ?? {};
    final rows = <List<String>>[];
    rows.add(['studentId', 'name', 'status', 'markedBy', 'markedAt']);

    // Extract student data from the document
    data.forEach((key, value) {
      if (!key.endsWith('_name') &&
          key != 'classId' &&
          key != 'date' &&
          key != 'markedBy' &&
          key != 'markedAt') {
        final studentId = key;
        final studentName = data['${studentId}_name'] ?? '';
        final status = value.toString();
        final markedBy = data['markedBy'] ?? '';
        final markedAt = data['markedAt'] is Timestamp
            ? (data['markedAt'] as Timestamp).toDate().toIso8601String()
            : (data['markedAt']?.toString() ?? '');

        rows.add([studentId, studentName, status, markedBy, markedAt]);
      }
    });

    final sb = StringBuffer();
    for (final r in rows) {
      sb.writeln(r.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
    }
    return sb.toString();
  }
}

// -----------------------------
// Provider / State Manager
// -----------------------------

class StaffAttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // UI state
  DateTime selectedDate = DateTime.now();
  String? selectedClassId;
  String? selectedClassName;
  String? schoolIdClaim;

  // data caches
  List<QueryDocumentSnapshot>? classesCache; // raw class docs
  List<StudentItem> students = [];

  // attendance state: studentId -> AttendanceStatus
  Map<String, AttendanceStatus> currentSelections = {};
  Map<String, AttendanceStatus> originalSelections = {}; // to compute diffs

  // changed records prepared for submit: studentId -> AttendanceRecord
  Map<String, AttendanceRecord> changedRecords = {};

  // loading indicators
  bool isLoading = false;
  bool isSubmitting = false;

  // realtime listeners
  StreamSubscription<DocumentSnapshot>? attendanceSub;
  StreamSubscription<List<QueryDocumentSnapshot>>? classesSub;

  // collaboration indicator
  bool otherStaffEditing = false;

  // last marked metadata
  String? lastMarkedByUid;
  DateTime? lastMarkedAt;

  // undo buffer (store previous snapshot of changedRecords and selections)
  Map<String, AttendanceStatus>? undoSelectionsBackup;
  Map<String, AttendanceRecord>? undoChangedBackup;

  // Track if attendance already exists in database
  bool attendanceExists = false;

  StaffAttendanceProvider({required this.repository}) {
    _init();
  }

  Future<void> _init() async {
    // check auth + claims
    final user = auth.currentUser;
    if (user == null) return; // caller must handle redirect

    // get custom claim for schoolId if present
    final idTokenResult = await user.getIdTokenResult(true);
    final claims = idTokenResult.claims ?? {};
    if (claims.containsKey('schoolId')) {
      schoolIdClaim = claims['schoolId'] as String?;
    }

    // subscribe classes stream if we have schoolId
    if (schoolIdClaim != null) {
      classesSub = repository.classesStream(schoolIdClaim!).listen((docs) {
        classesCache = docs;
        notifyListeners();
      });
    }
  }

  // Role check helper
  Future<bool> ensureIsStaff(BuildContext context) async {
    final user = auth.currentUser;
    if (user == null) return false;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    final role = data?['role'] as String?;
    if (role != 'teacher') {
      return false;
    }
    return true;
  }

  void setDate(DateTime d) {
    selectedDate = d;
    // reload attendance if class selected
    if (selectedClassId != null && schoolIdClaim != null) {
      _listenAttendance();
    }
    notifyListeners();
  }

  Future<void> selectClass(String classId, String className) async {
    selectedClassId = classId;
    selectedClassName = className;
    isLoading = true;
    notifyListeners();

    // Prefetch students
    if (schoolIdClaim != null) {
      students = await repository.fetchStudents(schoolIdClaim!, classId);
    } else {
      students = [];
    }

    // Check if attendance already exists for this date/class
    if (schoolIdClaim != null) {
      attendanceExists = await repository.doesAttendanceExist(
        schoolIdClaim!,
        dateKey,
        classId,
      );
    }

    // Set initial selections based on whether attendance exists
    if (attendanceExists) {
      // If attendance exists, we'll load the actual data from the stream
      // Set temporary defaults that will be overridden by the stream
      currentSelections = {
        for (var s in students) s.id: AttendanceStatus.present,
      };
    } else {
      // If no attendance exists, set default to present
      currentSelections = {
        for (var s in students) s.id: AttendanceStatus.present,
      };
      originalSelections = Map.from(currentSelections);
      changedRecords.clear();
    }

    isLoading = false;
    notifyListeners();

    // start listening to attendance data for this date/class
    _listenAttendance();
  }

  String get dateKey => DateFormat('yyyy-MM-dd').format(selectedDate);

  void _listenAttendance() {
    // cancel old
    attendanceSub?.cancel();
    otherStaffEditing = false;
    lastMarkedByUid = null;
    lastMarkedAt = null;

    if (schoolIdClaim == null || selectedClassId == null) return;

    attendanceSub = repository
        .attendanceStream(schoolIdClaim!, selectedClassId!, dateKey)
        .listen((doc) {
          if (!doc.exists) {
            // No attendance data exists
            attendanceExists = false;
            // Keep default present values if not already set
            if (originalSelections.isEmpty) {
              currentSelections = {
                for (var s in students) s.id: AttendanceStatus.present,
              };
              originalSelections = Map.from(currentSelections);
              changedRecords.clear();
            }
            notifyListeners();
            return;
          }

          // Attendance data exists
          attendanceExists = true;
          final data = doc.data() as Map<String, dynamic>? ?? {};

          // Update selections from database
          final newSelections = <String, AttendanceStatus>{};
          for (var s in students) {
            final statusKey = data[s.id] as String?;
            if (statusKey != null) {
              newSelections[s.id] = AttendanceStatusExt.fromKey(statusKey);
            } else {
              newSelections[s.id] = AttendanceStatus.present;
            }
          }

          currentSelections = newSelections;
          originalSelections = Map.from(currentSelections);
          changedRecords.clear();

          // Get metadata for last marked info
          lastMarkedByUid = data['markedBy'] as String?;
          final markedAt = data['markedAt'];
          if (markedAt is Timestamp) {
            lastMarkedAt = markedAt.toDate();
          }

          // Real-time collaboration hint
          otherStaffEditing = doc.metadata.hasPendingWrites;
          notifyListeners();
        });
  }

  // cycle status when tapping item
  void cycleStatus(String studentId) {
    final current = currentSelections[studentId] ?? AttendanceStatus.present;
    AttendanceStatus next;
    switch (current) {
      case AttendanceStatus.present:
        next = AttendanceStatus.absent;
        break;
      case AttendanceStatus.absent:
        next = AttendanceStatus.late;
        break;
      case AttendanceStatus.late:
        next = AttendanceStatus.halfDay;
        break;
      case AttendanceStatus.halfDay:
        next = AttendanceStatus.present;
        break;
      default:
        next = AttendanceStatus.present;
    }
    setStatus(studentId, next);
  }

  void setStatus(String studentId, AttendanceStatus status) {
    final original = originalSelections[studentId] ?? AttendanceStatus.present;
    currentSelections[studentId] = status;

    // Find student name
    final student = students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => StudentItem(
        id: studentId,
        name: 'Unknown',
        classId: selectedClassId ?? '',
      ),
    );

    if (status != original) {
      // mark to changedRecords
      final rec = AttendanceRecord(
        studentId: studentId,
        studentName: student.name,
        status: status,
        classId: selectedClassId ?? '',
      );
      changedRecords[studentId] = rec;
    } else {
      // no longer changed -> remove
      changedRecords.remove(studentId);
    }
    notifyListeners();
  }

  // batch actions
  void markAllPresent() {
    for (final s in students) {
      setStatus(s.id, AttendanceStatus.present);
    }
  }

  void clearAll() {
    for (final s in students) {
      setStatus(s.id, AttendanceStatus.unknown);
    }
  }

  // submission: only write changedRecords
  Future<void> submit(BuildContext context) async {
    final user = auth.currentUser;
    if (user == null || schoolIdClaim == null || selectedClassId == null) {
      return;
    }

    // Only show "No changes to submit" if attendance already exists AND no changes were made
    if (attendanceExists && changedRecords.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No changes to submit')));
      return;
    }
    // If it's new attendance and no changes were made,
    // create initial attendance with all "present"
    if (!attendanceExists && changedRecords.isEmpty) {
      for (final s in students) {
        changedRecords[s.id] = AttendanceRecord(
          studentId: s.id,
          studentName: s.name,
          status: currentSelections[s.id] ?? AttendanceStatus.present,
          classId: selectedClassId ?? '',
        );
      }
    }

    isSubmitting = true;
    notifyListeners();

    // backup for undo
    undoSelectionsBackup = Map.from(currentSelections);
    undoChangedBackup = Map.from(changedRecords);

    try {
      await repository.submitAttendanceChanges(
        schoolId: schoolIdClaim!,
        dateKey: dateKey,
        classId: selectedClassId!,
        staffUid: user.uid,
        changedRecords: changedRecords,
        allStudents: students,
        currentSelections: currentSelections,
      );

      // on success, update originalSelections
      originalSelections = Map.from(currentSelections);
      changedRecords.clear();
      attendanceExists = true; // After submission, attendance now exists

      isSubmitting = false;
      notifyListeners();

      // show confirm dialog and snackbar with undo
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Attendance Submitted'),
          content: Text(
            'Attendance for $selectedClassName on $dateKey saved successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );

      final snack = SnackBar(
        content: Text('Attendance submitted'),
        // action: SnackBarAction(
        //   label: 'Undo',
        //   onPressed: () async {
        //     await undoSubmission();
        //   },
        // ),
        duration: Duration(seconds: 1),
      );
      ScaffoldMessenger.of(context).showSnackBar(snack);
    } catch (e, st) {
      isSubmitting = false;
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      // restore backups to keep UI consistent
      if (undoSelectionsBackup != null) {
        currentSelections = Map.from(undoSelectionsBackup!);
      }
      if (undoChangedBackup != null) {
        changedRecords = Map.from(undoChangedBackup!);
      }
      notifyListeners();
    }
  }

  Future<void> undoSubmission() async {
    // attempt to write undoChangedBackup back (i.e., revert to previous state). This is conservative.
    if (undoChangedBackup == null || schoolIdClaim == null) return;
    final user = auth.currentUser;
    if (user == null) return;

    final attendanceDocRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolIdClaim!)
        .collection('classes')
        .doc(selectedClassId!)
        .collection('attendance')
        .doc(dateKey);

    // Prepare the attendance data with previous values
    final attendanceData = {
      'classId': selectedClassId!,
      'date': dateKey,
      'markedBy': user.uid,
      'markedAt': FieldValue.serverTimestamp(),
    };

    // Add each student's previous status
    undoChangedBackup!.forEach((studentId, rec) {
      attendanceData[studentId] = rec.status.key;
      attendanceData['${studentId}_name'] = rec.studentName;
    });

    await attendanceDocRef.set(attendanceData, SetOptions(merge: true));

    // restore UI
    if (undoSelectionsBackup != null) {
      currentSelections = Map.from(undoSelectionsBackup!);
      originalSelections = Map.from(undoSelectionsBackup!);
      changedRecords.clear();
      notifyListeners();
    }
  }

  Future<void> exportCsv(BuildContext context) async {
    if (schoolIdClaim == null || selectedClassId == null) return;
    final csv = await repository.exportAttendanceToCsv(
      schoolId: schoolIdClaim!,
      dateKey: dateKey,
      classId: selectedClassId!,
    );
    // save to temp file and share
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/attendance-$selectedClassId-$dateKey.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Attendance for $selectedClassName on $dateKey');
  }

  @override
  void dispose() {
    attendanceSub?.cancel();
    classesSub?.cancel();
    super.dispose();
  }
}

// -----------------------------
// UI: StaffAttendanceScreen Widget
// -----------------------------

class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          StaffAttendanceProvider(repository: AttendanceRepository()),
      child: _StaffAttendanceScreenBody(),
    );
  }
}

class _StaffAttendanceScreenBody extends StatefulWidget {
  @override
  State<_StaffAttendanceScreenBody> createState() =>
      _StaffAttendanceScreenBodyState();
}

class _StaffAttendanceScreenBodyState
    extends State<_StaffAttendanceScreenBody> {
  bool _roleChecked = false;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final provider = Provider.of<StaffAttendanceProvider>(
      context,
      listen: false,
    );
    final ok = await provider.ensureIsStaff(context);
    if (!ok) {
      // redirect to unauthorized page or pop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Access denied: staff only')));
        Navigator.of(context).pop();
      });
    }
    setState(() {
      _roleChecked = true;
      _isStaff = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleChecked) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isStaff) return SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance', style: GoogleFonts.lexend()),
      ),
      body: Consumer<StaffAttendanceProvider>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // Header: Date picker and class dropdown
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_DateClassHeader()],
                ),
              ),
              // Info row
              if (vm.otherStaffEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 8),
                      Text('Another staff has recent pending changes'),
                    ],
                  ),
                ),
              if (vm.lastMarkedByUid != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(vm.lastMarkedByUid)
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) return SizedBox.shrink();
                    final name =
                        (snap.data!.data()
                            as Map<String, dynamic>?)?['displayName'] ??
                        'Staff';
                    final at = vm.lastMarkedAt != null
                        ? DateFormat.jm().format(vm.lastMarkedAt!)
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'Last marked by $name at $at',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              // Actions: batch
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.students.isEmpty ? null : vm.markAllPresent,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Mark All Present'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: vm.students.isEmpty ? null : vm.clearAll,
                      icon: Icon(Icons.clear),
                      label: Text('Clear All'),
                    ),
                    Spacer(),
                    IconButton(
                      tooltip: 'Export CSV',
                      onPressed: vm.selectedClassId == null
                          ? null
                          : () => vm.exportCsv(context),
                      icon: Icon(Icons.download),
                    ),
                  ],
                ),
              ),
              // Student list
              Expanded(child: _StudentList()),
              // Sticky submit
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting
                        ? null
                        : () => vm.submit(context),
                    child: vm.isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Submit Attendance'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateClassHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StaffAttendanceProvider>(context);
    final classes = vm.classesCache;

    return Row(
      children: [
        // Date picker
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: vm.selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) vm.setDate(picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 4),
                  Text(
                    DateFormat.yMMMEd().format(vm.selectedDate),
                    style: GoogleFonts.lexend(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // Class dropdown
        Expanded(
          child: classes == null
              ? Container(
                  padding: EdgeInsets.all(12),
                  child: Text('Loading classes...'),
                )
              : DropdownButtonFormField<String>(
                  value: vm.selectedClassId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    // hintText: 'Select Class',
                  ),
                  items: classes.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Unnamed'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final doc = classes.firstWhere((d) => d.id == val);
                    final name =
                        (doc.data() as Map<String, dynamic>)['name']
                            as String? ??
                        '';
                    vm.selectClass(val, name);
                  },
                ),
        ),
      ],
    );
  }
}

class _StudentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StaffAttendanceProvider>(context);
    if (vm.isLoading) return Center(child: CircularProgressIndicator());
    if (vm.selectedClassId == null) {
      return Center(child: Text('Select a class to load students'));
    }
    if (vm.students.isEmpty) {
      return Center(child: Text('No students in this class'));
    }

    return ListView.builder(
      itemCount: vm.students.length,
      itemBuilder: (context, index) {
        final s = vm.students[index];
        final status = vm.currentSelections[s.id] ?? AttendanceStatus.present;
        return _StudentListItem(student: s, status: status);
      },
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final StudentItem student;
  final AttendanceStatus status;
  const _StudentListItem({required this.student, required this.status});

  Color _bgForStatus(BuildContext context, AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return Colors.green.withOpacity(0.12);
      case AttendanceStatus.absent:
        return Colors.red.withOpacity(0.12);
      case AttendanceStatus.late:
        return Colors.orange.withOpacity(0.12);
      case AttendanceStatus.halfDay:
        return Colors.blue.withOpacity(0.08);
      default:
        return Colors.transparent;
    }
  }

  IconData _iconForStatus(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return Icons.check;
      case AttendanceStatus.absent:
        return Icons.close;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.halfDay:
        return Icons.call_split;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StaffAttendanceProvider>(context, listen: false);
    return InkWell(
      onTap: () => vm.cycleStatus(student.id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: _bgForStatus(context, status)),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(student.name.isEmpty ? '?' : student.name[0]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                student.name,
                style: GoogleFonts.lexend(fontSize: 16),
              ),
            ),
            // quick action buttons
            ToggleButtons(
              constraints: BoxConstraints(minHeight: 36, minWidth: 36),
              isSelected: [
                status == AttendanceStatus.present,
                status == AttendanceStatus.absent,
                status == AttendanceStatus.late,
                status == AttendanceStatus.halfDay,
              ],
              onPressed: (i) {
                final newStatus = [
                  AttendanceStatus.present,
                  AttendanceStatus.absent,
                  AttendanceStatus.late,
                  AttendanceStatus.halfDay,
                ][i];
                vm.setStatus(student.id, newStatus);
              },
              children: [
                Icon(Icons.check, size: 18),
                Icon(Icons.close, size: 18),
                Icon(Icons.access_time, size: 18),
                Icon(Icons.call_split, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
