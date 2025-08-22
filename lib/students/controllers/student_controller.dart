import 'package:flutter/foundation.dart';
import 'package:projects/core/exceptions/database_exceptions.dart';
import 'package:projects/students/models/student_model.dart';
import 'package:projects/students/repositories/student_repository.dart';

class StudentController with ChangeNotifier {
  final StudentRepository _repository;

  List<Student> _students = [];
  List<Student> get students => List.unmodifiable(_students);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _selectedClass;
  String? get selectedClass => _selectedClass;

  String? _selectedSection;
  String? get selectedSection => _selectedSection;

  List<String> _availableClasses = [];
  List<String> get availableClasses => List.unmodifiable(_availableClasses);

  List<String> _availableSections = [];
  List<String> get availableSections => List.unmodifiable(_availableSections);

  StudentController({required StudentRepository repository})
    : _repository = repository;

  Future<void> loadStudents() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;

      final students = await _repository.getStudents(
        classFilter: _selectedClass,
        sectionFilter: _selectedSection,
      );

      _students = students;
      _error = null;
    } on DatabaseException catch (e) {
      _error = e.message;
      _students = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadAvailableClasses() async {
    try {
      _availableClasses = await _repository.getAvailableClasses();
      _safeNotifyListeners();
    } on DatabaseException catch (e) {
      _error = e.message;
    }
  }

  Future<void> loadAvailableSections(String studentClass) async {
    try {
      _availableSections = await _repository.getAvailableSections(studentClass);
      _safeNotifyListeners();
    } on DatabaseException catch (e) {
      _error = e.message;
    }
  }

  Future<bool> createStudent(Student student) async {
    try {
      _isLoading = true;
      _error = null;

      await _repository.createStudent(student);
      await loadStudents(); // Reload to include new student

      return true;
    } on DatabaseException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<List<Student>> searchStudents(String query) async {
    try {
      return await _repository.searchStudents(query);
    } on DatabaseException {
      return [];
    }
  }

  void setClassFilter(String? studentClass) {
    _selectedClass = studentClass;
    _selectedSection = null;
    loadStudents();
  }

  void setSectionFilter(String? section) {
    _selectedSection = section;
    loadStudents();
  }

  void clearFilters() {
    _selectedClass = null;
    _selectedSection = null;
    loadStudents();
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  // Safe notification to avoid build phase issues
  void _safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
}
