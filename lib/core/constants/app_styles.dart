import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  static TextStyle headline1 = GoogleFonts.lexend(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyText1 = GoogleFonts.lexend(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle buttonText = GoogleFonts.lexend(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
