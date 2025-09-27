import 'dart:ui';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:projects/models/class_model.dart';

class StudentCreationScreen extends StatefulWidget {
  final String schoolId;

  const StudentCreationScreen({Key? key, required this.schoolId})
    : super(key: key);

  @override
  _StudentCreationScreenState createState() => _StudentCreationScreenState();
}

class _StudentCreationScreenState extends State<StudentCreationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  // Form fields
  String _name = '';
  String _email = '';
  String _age = '';
  String _gender = '';
  String _selectedClass = '';
  String _address = '';
  String _phone = '';
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  String _selectedSection = '';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Class and section options
  final List<String> _classOptions = List.generate(
    10,
    (index) => 'Class ${index + 1}',
  );
  final List<String> _sectionOptions = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);

        // Calculate age based on date of birth
        final now = DateTime.now();
        int age = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _age = age.toString();
      });
    }
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_dateOfBirth == null) {
      Fluttertoast.showToast(msg: "Please select date of birth");
      return;
    }

    if (_selectedClass.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a class");
      return;
    }

    if (_selectedSection.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a section");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Extract class number from selected class (e.g., "Class 5" -> "5")
      final classNumber = _selectedClass.replaceAll('Class ', '');

      // Create combined class ID in the format "class_X_y" (e.g., class_5_e)
      final combinedClassId =
          'class_${classNumber}_${_selectedSection.toLowerCase()}';

      // Create class with proper structure (same as class management screen)
      final classRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .doc(combinedClassId);

      final classDoc = await classRef.get();
      if (!classDoc.exists) {
        // Create class with the same structure as class management screen
        final schoolClass = SchoolClass(
          id: combinedClassId,
          name: 'Class $classNumber', // 'Class 5' not 'Class5E'
          section: _selectedSection, // 'E'
          subject: null,
          schedule: null,
          room: null,
          teacherId: '',
          teacherName: 'Unassigned',
          studentCount: 0,
          createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await classRef.set(schoolClass.toMap());
      }

      // Then send combinedClassId to your Cloud Function
      final payload = {
        'schoolId': widget.schoolId,
        'name': _name,
        'email': _email,
        'gender': _gender,
        'classId': combinedClassId,
        'address': _address,
        'phone': _phone,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
      };

      // Ensure your admin token is fresh (optional but helpful)
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('createStudent');

      final result = await callable.call(payload);
      final data = Map<String, dynamic>.from(result.data as Map);
      final uid = data['uid'] as String?;
      final tempPassword = data['tempPassword'] as String?;

      Fluttertoast.showToast(
        msg: "Student created. UID: $uid\nTemp password: $tempPassword",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

      if (mounted) Navigator.of(context).pop();
    } on FirebaseFunctionsException catch (e) {
      String msg = "Failed to create student.";
      if (e.code == 'permission-denied') {
        msg = "Only approved admins can create students.";
      }
      if (e.code == 'already-exists') msg = "Email already in use.";
      if (e.code == 'unauthenticated') msg = "Please sign in as an admin.";
      if (e.code == 'invalid-argument') msg = "Invalid student details.";
      Fluttertoast.showToast(msg: "$msg\n(${e.message})");
    } catch (e) {
      Fluttertoast.showToast(msg: "Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Student'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the information for the new student.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      controller: null,
                      label: 'Full Name *',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!.trim(),
                    ),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      controller: null,
                      label: 'Email Address *',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value!.trim(),
                    ),
                    const SizedBox(height: 16.0),

                    // Date of Birth & Age in a Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _dateController,
                            label: 'Date of Birth *',
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Select date of birth';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            value: _gender.isNotEmpty ? _gender : null,
                            label: 'Gender *',
                            icon: Icons.transgender,
                            items: _genders,
                            onChanged: (value) =>
                                setState(() => _gender = value!),
                            validator: (value) =>
                                value == null ? 'Please select gender' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    // Class & Section in a Row
                    Row(
                      children: [
                        const SizedBox(width: 2),
                        Expanded(
                          child: _buildDropdownField(
                            value: _selectedClass.isNotEmpty
                                ? _selectedClass
                                : null,
                            label: 'Class *',
                            icon: Icons.groups_outlined,
                            items: _classOptions,
                            onChanged: (value) =>
                                setState(() => _selectedClass = value!),
                            validator: (value) =>
                                value == null ? 'Please select class' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            value: _selectedSection.isNotEmpty
                                ? _selectedSection
                                : null,
                            label: 'Section *',
                            icon: Icons.view_module_outlined,
                            items: _sectionOptions,
                            onChanged: (value) =>
                                setState(() => _selectedSection = value!),
                            validator: (value) =>
                                value == null ? 'Please select section' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // Contact Information Section
                    _buildSectionHeader('Contact Information'),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      controller: null,
                      label: 'Address *',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                      onSaved: (value) => _address = value!.trim(),
                    ),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      controller: null,
                      label: 'Phone Number *',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (value.length != 10) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                      onSaved: (value) => _phone = value!.trim(),
                    ),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      initialValue: widget.schoolId,
                      label: 'School ID',
                      icon: Icons.school_outlined,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 32.0),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Create Student Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget to create a consistent text field style
  Widget _buildTextField({
    TextEditingController? controller,
    String? label,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
    int? maxLines = 1,
    String? initialValue,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        labelStyle: TextStyle(color: enabled ? null : Colors.grey.shade700),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      onTap: onTap,
    );
  }

  // Helper widget to create a consistent dropdown field style
  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      validator: validator,
      onChanged: onChanged,
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey,
      ),
    );
  }
}
