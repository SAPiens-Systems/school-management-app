import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class BulkUploadScreen extends StatefulWidget {
  final String schoolId;

  const BulkUploadScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  _BulkUploadScreenState createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isUploading = false;
  int _successCount = 0;
  int _errorCount = 0;
  String _selectedFileName = '';
  PlatformFile? _selectedFile;

  // Template structure
  final List<Map<String, dynamic>> _templateData = [
    {
      'name': 'John Doe',
      'email': 'john.doe@school.com',
      'gender': 'Male',
      'class': '10',
      'section': 'A',
      'dateOfBirth': '2010-05-15',
      'address': '123 Main Street, City',
      'phone': '9876543210',
    },
    {
      'name': 'Jane Smith',
      'email': 'jane.smith@school.com',
      'gender': 'Female',
      'class': '9',
      'section': 'B',
      'dateOfBirth': '2011-08-22',
      'address': '456 Oak Avenue, Town',
      'phone': '8765432109',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Student Upload'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _isUploading ? null : _uploadStudents,
              tooltip: 'Upload Students',
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTemplate,
            tooltip: 'Download Template',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_isUploading) {
      return _buildUploadProgress();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUploadSection(),
          const SizedBox(height: 24),
          if (_students.isNotEmpty) _buildPreviewSection(),
          const SizedBox(height: 24),
          _buildInstructionsSection(),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Excel File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an Excel file (.xlsx) with student data',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _selectedFileName.isNotEmpty
                          ? _selectedFileName
                          : 'Choose Excel File',
                    ),
                    onPressed: _pickExcelFile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedFileName.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: _clearSelection,
                    tooltip: 'Clear selection',
                  ),
              ],
            ),
            if (_selectedFileName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_students.length} students found',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview Students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Found ${_students.length} students ready for upload',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: min(_students.length, 10), // Show first 10 only
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(student['name'][0]),
                    ),
                    title: Text(student['name']),
                    subtitle: Text(
                      '${student['email']} • Class ${student['class']}${student['section']}',
                    ),
                    trailing: Icon(
                      student['isValid'] == false
                          ? Icons.error
                          : Icons.check_circle,
                      color: student['isValid'] == false
                          ? Colors.red
                          : Colors.green,
                    ),
                  );
                },
              ),
            ),
            if (_students.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${_students.length - 10} more students...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload All Students'),
                onPressed: _uploadStudents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '1. Download the template using the download button above',
            ),
            _buildInstructionItem(
              '2. Fill in student data following the format',
            ),
            _buildInstructionItem(
              '3. Required fields: Name, Email, Gender, Class, Section',
            ),
            _buildInstructionItem(
              '4. Date format: YYYY-MM-DD (e.g., 2010-05-15)',
            ),
            _buildInstructionItem('5. Phone numbers should be 10 digits'),
            _buildInstructionItem('6. Email addresses must be unique'),
            const SizedBox(height: 8),
            Text(
              'Note: Invalid records will be skipped during upload',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing file...'),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: (_successCount + _errorCount) / _students.length,
          ),
          const SizedBox(height: 20),
          Text(
            'Uploading students...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Processed: ${_successCount + _errorCount}/${_students.length}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIndicator('Success', _successCount, Colors.green),
              const SizedBox(width: 16),
              _buildStatusIndicator('Errors', _errorCount, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedFileName = _selectedFile!.name;
          _isLoading = true;
        });

        await _processExcelFile(_selectedFile!);
      }
    } catch (e) {
      _showError('Failed to pick file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processExcelFile(PlatformFile file) async {
    try {
      final bytes = File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> students = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;

        // Skip empty sheets
        if (sheet.rows.length <= 1) continue;

        // Get headers from first row
        final headers = sheet.rows[0]
            .map((cell) => cell?.value.toString().toLowerCase().trim())
            .toList();

        // Process data rows
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;

          Map<String, dynamic> student = {};
          for (int j = 0; j < min(headers.length, row.length); j++) {
            if (headers[j] != null && row[j]?.value != null) {
              student[headers[j]!] = row[j]!.value.toString().trim();
            }
          }

          if (student.isNotEmpty) {
            // Validate and format student data
            student = _validateAndFormatStudent(student);
            students.add(student);
          }
        }
      }

      if (mounted) {
        setState(() => _students = students);
      }

      if (students.isEmpty) {
        _showError('No valid student data found in the file');
      }
    } catch (e) {
      _showError('Error processing Excel file: ${e.toString()}');
      if (mounted) {
        setState(() {
          _students = [];
          _selectedFileName = '';
        });
      }
    }
  }

  Map<String, dynamic> _validateAndFormatStudent(Map<String, dynamic> student) {
    final validatedStudent = Map<String, dynamic>.from(student);

    // Basic validation
    bool isValid = true;
    String? errorMessage;

    // Check required fields
    if (student['name'] == null || student['name'].toString().isEmpty) {
      isValid = false;
      errorMessage = 'Missing name';
    }

    if (student['email'] == null || student['email'].toString().isEmpty) {
      isValid = false;
      errorMessage = 'Missing email';
    } else if (!_isValidEmail(student['email'].toString())) {
      isValid = false;
      errorMessage = 'Invalid email format';
    }

    if (student['class'] == null || student['class'].toString().isEmpty) {
      isValid = false;
      errorMessage = 'Missing class';
    }

    if (student['section'] == null || student['section'].toString().isEmpty) {
      isValid = false;
      errorMessage = 'Missing section';
    }

    // Format class ID
    if (isValid) {
      final classNumber = student['class']
          .toString()
          .replaceAll('Class ', '')
          .trim();
      final section = student['section'].toString().trim().toUpperCase();
      validatedStudent['classId'] =
          'class_${classNumber}_${section.toLowerCase()}';
    }

    validatedStudent['isValid'] = isValid;
    validatedStudent['error'] = errorMessage;

    return validatedStudent;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _uploadStudents() async {
    if (_students.isEmpty) return;

    setState(() {
      _isUploading = true;
      _successCount = 0;
      _errorCount = 0;
    });

    final validStudents = _students.where((s) => s['isValid'] == true).toList();

    for (final student in validStudents) {
      try {
        await _createStudent(student);
        setState(() => _successCount++);
      } catch (e) {
        print('Failed to create student ${student['name']}: $e');
        setState(() => _errorCount++);

        // Add error info to student for potential retry
        student['uploadError'] = e.toString();
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _isUploading = false);

    _showUploadSummary();
  }

  Future<void> _createStudent(Map<String, dynamic> student) async {
    try {
      final payload = {
        'schoolId': widget.schoolId,
        'name': student['name'],
        'email': student['email'],
        'gender': student['gender'] ?? 'Other',
        'classId': student['classId'],
        'address': student['address'] ?? '',
        'phone': student['phone'] ?? '',
        'dateOfBirth':
            student['dateofbirth'] ?? student['dateOfBirth'] ?? '2000-01-01',
      };

      final callable = _functions.httpsCallable('createStudent');
      await callable.call(payload);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Future<void> _downloadTemplate() async {
  //   try {
  //     // Create sample Excel file
  //     final excel = Excel.createExcel();
  //     final sheet = excel['Students'];

  //     // Add headers
  //     final headers = ['Name', 'Email', 'Gender', 'Class', 'Section', 'DateOfBirth', 'Address', 'Phone'];
  //     for (int i = 0; i < headers.length; i++) {
  //       sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')).value = headers[i];
  //     }

  //     // Add sample data
  //     for (int i = 0; i < _templateData.length; i++) {
  //       final student = _templateData[i];
  //       final row = i + 2;

  //       sheet.cell(CellIndex.indexByString('A$row')).value = student['name'];
  //       sheet.cell(CellIndex.indexByString('B$row')).value = student['email'];
  //       sheet.cell(CellIndex.indexByString('C$row')).value = student['gender'];
  //       sheet.cell(CellIndex.indexByString('D$row')).value = student['class'];
  //       sheet.cell(CellIndex.indexByString('E$row')).value = student['section'];
  //       sheet.cell(CellIndex.indexByString('F$row')).value = student['dateOfBirth'];
  //       sheet.cell(CellIndex.indexByString('G$row')).value = student['address'];
  //       sheet.cell(CellIndex.indexByString('H$row')).value = student['phone'];
  //     }

  //     // Save file
  //     final bytes = excel.save();
  //     final directory = await getDownloadsDirectory();
  //     final filePath = '${directory?.path}/student_upload_template.xlsx';
  //     File(filePath).writeAsBytesSync(bytes!);

  //     _showSuccess('Template downloaded to Downloads folder');

  //   } catch (e) {
  //     _showError('Failed to download template: ${e.toString()}');
  //   }
  // }

  // Future<void> _downloadTemplate() async {
  //   try {
  //     // Create sample Excel file
  //     final excel = Excel.createExcel();
  //     final sheet = excel['Students'];

  //     // Add headers
  //     final List<String> headers = [
  //       'Name',
  //       'Email',
  //       'Gender',
  //       'Class',
  //       'Section',
  //       'DateOfBirth',
  //       'Address',
  //       'Phone',
  //     ];
  //     for (int i = 0; i < headers.length; i++) {
  //       final cell = sheet.cell(
  //         CellIndex.indexByString('${String.fromCharCode(65 + i)}1'),
  //       );
  //       cell.value = TextCellValue(
  //         headers[i],
  //       ); // Use TextCellValue instead of String
  //     }

  //     // Add sample data
  //     for (int i = 0; i < _templateData.length; i++) {
  //       final student = _templateData[i];
  //       final row = i + 2;

  //       sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
  //         student['name'],
  //       );
  //       sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
  //         student['email'],
  //       );
  //       sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
  //         student['gender'],
  //       );
  //       sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
  //         student['class'],
  //       );
  //       sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(
  //         student['section'],
  //       );
  //       sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(
  //         student['dateOfBirth'],
  //       );
  //       sheet.cell(CellIndex.indexByString('G$row')).value = TextCellValue(
  //         student['address'],
  //       );
  //       sheet.cell(CellIndex.indexByString('H$row')).value = TextCellValue(
  //         student['phone'],
  //       );
  //     }

  //     // Save file
  //     // Save file
  //     final bytes = excel.save();
  //     if (bytes != null) {
  //       Directory? downloadsDirectory;

  //       if (Platform.isAndroid) {
  //         var status = await Permission.storage.request();
  //         if (status.isGranted) {
  //           // proceed with file saving
  //         } else if (status.isPermanentlyDenied) {
  //           // open app settings if permanently denied
  //           await openAppSettings();
  //           return;
  //         } else {
  //           _showError('Storage permission denied');
  //           return;
  //         }
  //         downloadsDirectory = Directory('/storage/emulated/0/Download');
  //       } else {
  //         downloadsDirectory = await getDownloadsDirectory();
  //       }

  //       final filePath =
  //           '${downloadsDirectory!.path}/student_upload_template.xlsx';
  //       final file = File(filePath);
  //       await file.writeAsBytes(bytes);

  //       // Open the file
  //       await OpenFile.open(filePath);

  //       _showSuccess('Template downloaded successfully!');
  //     } else {
  //       _showError('Failed to create template file');
  //     }
  //   } catch (e) {
  //     _showError('Failed to download template: ${e.toString()}');
  //     print('Template download error: $e');
  //   }
  // }

  Future<void> _downloadTemplate() async {
    try {
      // Create sample Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Students'];

      // Add headers
      final List<String> headers = [
        'Name',
        'Email',
        'Gender',
        'Class',
        'Section',
        'DateOfBirth',
        'Address',
        'Phone',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByString('${String.fromCharCode(65 + i)}1'),
        );
        cell.value = TextCellValue(headers[i]);
      }

      // Add sample data
      for (int i = 0; i < _templateData.length; i++) {
        final student = _templateData[i];
        final row = i + 2;

        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
          student['name'],
        );
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          student['email'],
        );
        sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          student['gender'],
        );
        sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
          student['class'],
        );
        sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(
          student['section'],
        );
        sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(
          student['dateOfBirth'],
        );
        sheet.cell(CellIndex.indexByString('G$row')).value = TextCellValue(
          student['address'],
        );
        sheet.cell(CellIndex.indexByString('H$row')).value = TextCellValue(
          student['phone'],
        );
      }

      // Save file
      final List<int>? bytes = excel.save();
      if (bytes != null) {
        // Use the sharing method which doesn't require permissions
        await _saveAndShareTemplate(bytes);
      } else {
        _showError('Failed to create template file');
      }
    } catch (e) {
      _showError('Failed to create template: ${e.toString()}');
      print('Template creation error: $e');
    }
  }

  Future<void> _saveAndShareTemplate(List<int> bytes) async {
    try {
      // Save to temporary directory (no permissions needed)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/student_upload_template.xlsx');
      await tempFile.writeAsBytes(bytes);

      // Share the file - this lets user choose where to save it
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Save this student upload template to your desired location',
        subject: 'Student Upload Template',
      );

      if (result.status == ShareResultStatus.success) {
        _showSuccess('Template shared successfully!');
      } else {
        _showSuccess('Template ready to be saved');
      }
    } catch (e) {
      print('Sharing failed: $e');
      // Fallback: try direct download with permission handling
      await _tryDirectDownloadWithPermission(bytes);
    }
  }

  Future<void> _tryDirectDownloadWithPermission(List<int> bytes) async {
    try {
      // Check if we have permission
      var status = await Permission.storage.status;

      if (!status.isGranted) {
        // Request permission
        status = await Permission.storage.request();

        if (!status.isGranted) {
          // Show dialog to explain why we need permission
          _showPermissionExplanationDialog();
          return;
        }
      }

      // We have permission, try to save to downloads
      await _saveToDownloadsDirectory(bytes);
    } catch (e) {
      print('Direct download failed: $e');
      _showError('Please save the file manually from your file manager');
    }
  }

  void _showPermissionExplanationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Needed'),
        content: const Text(
          'To download the template directly to your Downloads folder, '
          'we need storage permission. You can also save the template '
          'manually using the share option.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Try the share method again
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _downloadTemplate();
              });
            },
            child: const Text('Try Share Instead'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDownloadsDirectory(List<int> bytes) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to get downloads directory
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Download');
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null || !await directory.exists()) {
        // Fallback to app documents
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/student_upload_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccess('Template saved to: ${directory.path}');

      // Try to open the file
      try {
        await OpenFile.open(filePath);
      } catch (e) {
        print('Could not open file: $e');
      }
    } catch (e) {
      print('Save to downloads failed: $e');
      rethrow;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveFileAndroid(List<int> bytes) async {
    try {
      // Check and request storage permission
      var status = await Permission.storage.status;

      if (!status.isGranted) {
        status = await Permission.storage.request();

        if (!status.isGranted) {
          // If permission is permanently denied, show dialog to open app settings
          if (status.isPermanentlyDenied) {
            _showPermissionSettingsDialog();
            return;
          }
          _showError('Storage permission is required to download the template');
          return;
        }
      }

      // For Android 10+ (API 29+), we need to use MediaStore or Documents directory
      if (await _isAndroid10OrAbove()) {
        await _saveViaMediaStore(bytes);
      } else {
        await _saveToDownloadsDirectory(bytes);
      }
    } catch (e) {
      print('Error saving file: $e');
      // Fallback: save to app documents directory and share
      await _saveToAppDocumentsAndShare(bytes);
    }
  }

  Future<bool> _isAndroid10OrAbove() async {
    if (!Platform.isAndroid) return false;

    try {
      const channel = MethodChannel('flutter.io/deviceInfo');
      final version = await channel.invokeMethod<int>('getAndroidSdkVersion');
      return version != null && version >= 29;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveViaMediaStore(List<int> bytes) async {
    try {
      // Use the downloads_path_provider package or save to documents and share
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/student_upload_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the file so user can save it to their desired location
      await _shareFile(file);
    } catch (e) {
      print('MediaStore save failed: $e');
      await _saveToAppDocumentsAndShare(bytes);
    }
  }

  // Future<void> _saveToDownloadsDirectory(List<int> bytes) async {
  //   try {
  //     // For Android <10, we can save directly to Downloads
  //     final directory = await getExternalStorageDirectory();
  //     if (directory != null) {
  //       final downloadsDir = Directory('${directory.path}/Download');
  //       if (!downloadsDir.existsSync()) {
  //         downloadsDir.createSync(recursive: true);
  //       }

  //       final filePath = '${downloadsDir.path}/student_upload_template.xlsx';
  //       final file = File(filePath);
  //       await file.writeAsBytes(bytes);

  //       // Scan file to make it visible in gallery
  //       await _scanFile(file);

  //       _showSuccess('Template saved to Downloads folder');

  //       try {
  //         await OpenFile.open(filePath);
  //       } catch (e) {
  //         print('Could not open file: $e');
  //       }
  //     }
  //   } catch (e) {
  //     print('Downloads directory save failed: $e');
  //     await _saveToAppDocumentsAndShare(bytes);
  //   }
  // }

  Future<void> _saveToAppDocumentsAndShare(List<int> bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/student_upload_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the file so user can save it where they want
      await _shareFile(file);
    } catch (e) {
      _showError('Failed to save template: ${e.toString()}');
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Student Upload Template - Save this file to your desired location',
        subject: 'Student Upload Template',
      );
    } catch (e) {
      print('File sharing failed: $e');
      _showError('Please save the file manually from your file manager');
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is permanently denied. '
          'Please enable it in app settings to download templates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFile(File file) async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('flutter.io/fileProvider');
        await channel.invokeMethod('scanFile', {'path': file.path});
      } catch (e) {
        print('File scanning failed: $e');
      }
    }
  }
  // Future<void> _saveFileAndroid(List<int> bytes) async {
  //   try {
  //     // Request storage permission
  //     var status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       status = await Permission.storage.request();
  //       if (!status.isGranted) {
  //         _showError('Storage permission is required to download the template');
  //         return;
  //       }
  //     }

  //     // For Android 10+, use the Downloads directory with MediaStore
  //     final directory = await getExternalStorageDirectory();
  //     if (directory != null) {
  //       final downloadsDir = Directory('${directory.path}/Download');
  //       if (!downloadsDir.existsSync()) {
  //         downloadsDir.createSync(recursive: true);
  //       }

  //       final filePath = '${downloadsDir.path}/student_upload_template.xlsx';
  //       final file = File(filePath);
  //       await file.writeAsBytes(bytes);

  //       // Scan the file to make it visible in Downloads app
  //       if (Platform.isAndroid) {
  //         await _scanFile(file);
  //       }

  //       _showSuccess('Template saved to Downloads folder');

  //       // Try to open the file
  //       try {
  //         await OpenFile.open(filePath);
  //       } catch (e) {
  //         print('Could not open file: $e');
  //       }
  //     }
  //   } catch (e) {
  //     // Fallback: save to app documents directory
  //     await _saveToAppDocuments(bytes);
  //   }
  // }

  // Future<void> _scanFile(File file) async {
  //   if (Platform.isAndroid) {
  //     try {
  //       const channel = MethodChannel('flutter.io/fileProvider');
  //       await channel.invokeMethod('scanFile', {'path': file.path});
  //     } catch (e) {
  //       print('File scanning failed: $e');
  //     }
  //   }
  // }

  Future<void> _saveToAppDocuments(List<int> bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/student_upload_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccess('Template saved to app documents');

      // Share the file so user can save it elsewhere
      await _shareFile(file);
    } catch (e) {
      _showError('Failed to save template: ${e.toString()}');
    }
  }

  // Future<void> _shareFile(File file) async {
  //   try {
  //     await Share.shareXFiles([
  //       XFile(file.path),
  //     ], text: 'Student Upload Template');
  //   } catch (e) {
  //     print('File sharing failed: $e');
  //   }
  // }

  Future<void> _saveFileIOS(List<int> bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/student_upload_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccess('Template saved to documents');

      try {
        await OpenFile.open(filePath);
      } catch (e) {
        print('Could not open file: $e');
      }
    } catch (e) {
      _showError('Failed to save template: ${e.toString()}');
    }
  }

  Future<void> _saveFileOther(List<int> bytes) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final filePath = '${directory.path}/student_upload_template.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        _showSuccess('Template downloaded successfully!');

        try {
          await OpenFile.open(filePath);
        } catch (e) {
          print('Could not open file: $e');
        }
      } else {
        await _saveToAppDocuments(bytes);
      }
    } catch (e) {
      await _saveToAppDocuments(bytes);
    }
  }

  void _clearSelection() {
    setState(() {
      _students = [];
      _selectedFileName = '';
      _selectedFile = null;
    });
  }

  void _showUploadSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Success: $_successCount students'),
            Text('❌ Errors: $_errorCount students'),
            if (_errorCount > 0) const SizedBox(height: 8),
            if (_errorCount > 0)
              const Text(
                'Check the console for detailed error messages',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // void _showSuccess(String message) {
  //   Fluttertoast.showToast(
  //     msg: message,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.BOTTOM,
  //     backgroundColor: Colors.green,
  //     textColor: Colors.white,
  //   );
  // }

  // void _showError(String message) {
  //   Fluttertoast.showToast(
  //     msg: message,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.BOTTOM,
  //     backgroundColor: Colors.red,
  //     textColor: Colors.white,
  //   );
  // }

  Future<Directory?> getDownloadsDirectory() async {
    // For mobile, use external storage
    // For web, this will be handled differently
    try {
      return Directory('/storage/emulated/0/Download');
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    // Clean up any temporary files
    if (_selectedFile?.path != null) {
      try {
        File(_selectedFile!.path!).deleteSync();
      } catch (e) {
        print('Error cleaning up file: $e');
      }
    }
    super.dispose();
  }
}
