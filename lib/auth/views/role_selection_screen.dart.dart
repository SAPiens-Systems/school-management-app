import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/auth/views/login_screen.dart';
import 'package:projects/auth/views/signup_screen.dart';
import 'package:projects/auth/widgets/role_selection_card.dart';
import 'package:projects/core/constants/app_colors.dart';
import 'package:projects/core/constants/app_styles.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Your Role',
          style: AppStyles.headline1.copyWith(fontSize: 24),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to School Management',
              style: AppStyles.headline1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your role to continue',
              style: AppStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            RoleSelectionCard(
              icon: Icons.school,
              title: 'Teacher',
              description: 'Access student records, attendance, and grades',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(role: 'teacher'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            RoleSelectionCard(
              icon: Icons.admin_panel_settings,
              title: 'Administrator',
              description: 'Manage school settings and user permissions',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(role: 'admin'),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                'Already have an account? Log In',
                style: AppStyles.bodyText1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
