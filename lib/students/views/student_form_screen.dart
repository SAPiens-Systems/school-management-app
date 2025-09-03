// import 'package:flutter/material.dart';
// import 'package:projects/core/constants/app_colors.dart';
// import 'package:projects/core/constants/app_styles.dart';
// import 'package:projects/core/utils/validators.dart';
// import 'package:projects/students/controllers/student_controller.dart';
// import 'package:projects/students/models/student_model.dart';
// import 'package:provider/provider.dart';

// class StudentFormScreen extends StatefulWidget {
//   final String schoolId;
//   final String adminId;
//   final Student? existingStudent;

//   const StudentFormScreen({
//     Key? key,
//     required this.schoolId,
//     required this.adminId,
//     this.existingStudent,
//   }) : super(key: key);

//   @override
//   State<StudentFormScreen> createState() => _StudentFormScreenState();
// }

// class _StudentFormScreenState extends State<StudentFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _ageController = TextEditingController();
//   final _parentEmailController = TextEditingController();
//   final _parentMobileController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();

//   String? _selectedClass;
//   String? _selectedSection;
//   DateTime? _selectedDate;
//   bool _isLoading = false;

//   final List<String> _classes = [
//     'N',
//     'LKG',
//     'UKG',
//     '1',
//     '2',
//     '3',
//     '4',
//     '5',
//     '6',
//     '7',
//     '8',
//     '9',
//     '10',
//     '11',
//     '12',
//   ];
//   final Map<String, List<String>> _sections = {
//     'N': ['A', 'B', 'C'],
//     'LKG': ['A', 'B', 'C'],
//     'UKG': ['A', 'B', 'C'],
//     '1': ['A', 'B', 'C'],
//     '2': ['A', 'B', 'C'],
//     '3': ['A', 'B', 'C'],
//     '4': ['A', 'B', 'C'],
//     '5': ['A', 'B', 'C'],
//     '6': ['A', 'B', 'C'],
//     '7': ['A', 'B', 'C'],
//     '8': ['A', 'B', 'C'],
//     '9': ['A', 'B', 'C'],
//   };

//   @override
//   void initState() {
//     super.initState();
//     _loadExistingData();
//   }

//   void _loadExistingData() {
//     if (widget.existingStudent != null) {
//       final student = widget.existingStudent!;
//       _nameController.text = student.name;
//       _ageController.text = student.age.toString();
//       _parentEmailController.text = student.parentEmail;
//       _parentMobileController.text = student.parentMobile;
//       _selectedClass = student.studentClass;
//       _selectedSection = student.section;
//       _addressController.text = student.address;
//       _selectedDate = student.dateOfBirth;
//       _dateOfBirthController.text = _formatDate(student.dateOfBirth);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate:
//           _selectedDate ??
//           DateTime.now().subtract(const Duration(days: 365 * 5)),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _dateOfBirthController.text = _formatDate(picked);
//       });
//     }
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedDate == null ||
//         _selectedClass == null ||
//         _selectedSection == null)
//       return;

//     setState(() => _isLoading = true);

//     try {
//       final controller = context.read<StudentController>();
//       final student = Student(
//         id:
//             widget.existingStudent?.id ??
//             DateTime.now().millisecondsSinceEpoch.toString(),
//         schoolId: widget.schoolId,
//         name: _nameController.text.trim(),
//         age: int.parse(_ageController.text.trim()),
//         parentEmail: _parentEmailController.text.trim(),
//         parentMobile: _parentMobileController.text.trim(),
//         studentClass: _selectedClass!,
//         section: _selectedSection!,
//         dateOfBirth: _selectedDate!,
//         address: _addressController.text.trim(),
//         status: 'Active',
//         createdAt: widget.existingStudent?.createdAt ?? DateTime.now(),
//         createdBy: widget.existingStudent?.createdBy ?? widget.adminId,
//         studentId: widget.existingStudent?.studentId ?? '',
//       );

//       final success = await controller.createStudent(student);

//       if (success && mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               widget.existingStudent == null
//                   ? 'Student created successfully'
//                   : 'Student updated successfully',
//             ),
//             backgroundColor: AppColors.success,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: AppColors.error,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _ageController.dispose();
//     _parentEmailController.dispose();
//     _parentMobileController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.existingStudent == null ? 'Add Student' : 'Edit Student',
//         ),
//         backgroundColor: AppColors.primary,
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildReadOnlyField('School ID', widget.schoolId),
//               const SizedBox(height: 20),

//               _buildTextField(
//                 controller: _nameController,
//                 label: 'Student Name *',
//                 validator: (val) =>
//                     Validators.validateRequired(val, 'Student name'),
//               ),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                       controller: _ageController,
//                       label: 'Age *',
//                       keyboardType: TextInputType.number,
//                       validator: (val) =>
//                           Validators.validateNumeric(val, 'Age'),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(child: _buildDateField()),
//                 ],
//               ),

//               _buildTextField(
//                 controller: _parentEmailController,
//                 label: 'Parent Email *',
//                 keyboardType: TextInputType.emailAddress,
//                 validator: Validators.validateEmail,
//               ),

//               _buildTextField(
//                 controller: _parentMobileController,
//                 label: 'Parent Mobile *',
//                 keyboardType: TextInputType.phone,
//                 validator: Validators.validatePhone,
//               ),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildDropdown(
//                       value: _selectedClass,
//                       items: _classes,
//                       hint: 'Select Class *',
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedClass = value;
//                           _selectedSection = null;
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildDropdown(
//                       value: _selectedSection,
//                       items: _selectedClass != null
//                           ? _sections[_selectedClass] ?? []
//                           : [],
//                       hint: 'Select Section *',
//                       onChanged: (value) {
//                         setState(() => _selectedSection = value);
//                       },
//                     ),
//                   ),
//                 ],
//               ),

//               _buildTextField(
//                 controller: _addressController,
//                 label: 'Address *',
//                 maxLines: 3,
//                 validator: (val) => Validators.validateRequired(val, 'Address'),
//               ),

//               const SizedBox(height: 24),

//               Consumer<StudentController>(
//                 builder: (context, controller, child) {
//                   if (controller.error != null) {
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Text(
//                         controller.error!,
//                         style: const TextStyle(color: AppColors.error),
//                         textAlign: TextAlign.center,
//                       ),
//                     );
//                   }
//                   return const SizedBox();
//                 },
//               ),

//               ElevatedButton(
//                 onPressed: _isLoading ? null : _submitForm,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : Text(
//                         widget.existingStudent == null
//                             ? 'Create Student'
//                             : 'Update Student',
//                         style: AppStyles.buttonText.copyWith(fontSize: 16),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: AppStyles.bodyText1.copyWith(
//             fontWeight: FontWeight.w600,
//             color: AppColors.textSecondary,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.grey.shade50,
//           ),
//           child: Text(value, style: AppStyles.bodyText1),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: AppStyles.bodyText1.copyWith(
//               fontWeight: FontWeight.w600,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           TextFormField(
//             controller: controller,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: const EdgeInsets.all(16),
//             ),
//             validator: validator,
//             keyboardType: keyboardType,
//             maxLines: maxLines,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Date of Birth *',
//           style: AppStyles.bodyText1.copyWith(
//             fontWeight: FontWeight.w600,
//             color: AppColors.textSecondary,
//           ),
//         ),
//         const SizedBox(height: 4),
//         TextFormField(
//           controller: _dateOfBirthController,
//           readOnly: true,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.all(16),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.calendar_today),
//               onPressed: () => _selectDate(context),
//             ),
//           ),
//           validator: (val) => Validators.validateRequired(val, 'Date of birth'),
//           onTap: () => _selectDate(context),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdown({
//     required String? value,
//     required List<String> items,
//     required String hint,
//     required Function(String?) onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           hint,
//           style: AppStyles.bodyText1.copyWith(
//             fontWeight: FontWeight.w600,
//             color: AppColors.textSecondary,
//           ),
//         ),
//         const SizedBox(height: 4),
//         DropdownButtonFormField<String>(
//           value: value,
//           items: items.map((item) {
//             return DropdownMenuItem<String>(value: item, child: Text(item));
//           }).toList(),
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//           ),
//           validator: (val) => val == null ? 'Please select $hint' : null,
//         ),
//       ],
//     );
//   }
// }
