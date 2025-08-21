import 'package:flutter/material.dart';
import 'package:projects/auth/views/login_screen.dart';
import 'package:projects/core/constants/app_colors.dart';
import 'package:projects/core/constants/app_styles.dart';

class ApprovalPendingScreen extends StatelessWidget {
  const ApprovalPendingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              Text('Account Under Review', style: AppStyles.headline1),
              const SizedBox(height: 10),
              Text(
                'Your account has been created successfully and is waiting for admin approval. You will receive an email when your account is approved.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text('Back to Login', style: AppStyles.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
