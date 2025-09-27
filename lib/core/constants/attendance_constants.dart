import 'package:flutter/material.dart';

class AttendanceConstants {
  static const List<String> statusOptions = [
    'present',
    'absent',
    'late',
    'halfDay',
  ];

  static const Map<String, String> statusEmojis = {
    'present': '✅',
    'absent': '❌',
    'late': '⏰',
    'halfDay': '➗',
  };

  static const Map<String, Color> statusColors = {
    'present': Color(0xFF4CAF50),
    'absent': Color(0xFFF44336),
    'late': Color(0xFFFF9800),
    'halfDay': Color(0xFF2196F3),
  };
}
