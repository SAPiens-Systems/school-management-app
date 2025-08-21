import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/auth/controllers/auth_controller.dart';
import 'package:projects/auth/views/role_selection_screen.dart.dart';
import 'package:projects/auth/widgets/auth_text_field.dart';
import 'package:projects/core/constants/app_colors.dart';
import 'package:projects/core/constants/app_styles.dart';
import 'package:projects/core/exceptions/auth_exceptions.dart';
import 'package:projects/core/utils/validators.dart';
import 'package:projects/home/views/home_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isNavigating = false;

  @override
  void dispose() {
    // Dispose all your controllers first
    _emailController.dispose();
    _passwordController.dispose();

    // Then set navigation flag
    _isNavigating = false;

    // Call super.dispose() last
    super.dispose();
  }

  // Future<void> _submitForm() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);
  //   HapticFeedback.lightImpact();

  //   try {
  //     await context.read<AuthController>().login(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );

  //     // ADD NAVIGATION HERE - After successful login
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } on AuthException catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Login failed: $e'),
  //         backgroundColor: AppColors.error,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if widget is still mounted before any state changes
    if (!mounted) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await context.read<AuthController>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check mounted before navigation
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      // Check mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      // Check mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      // Check mounted before setting state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> _resetPassword() async {
  //   if (_emailController.text.isEmpty ||
  //       Validators.validateEmail(_emailController.text) != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please enter a valid email address'),
  //         backgroundColor: AppColors.error,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   try {
  //     await context.read<AuthController>().sendPasswordResetEmail(
  //       _emailController.text.trim(),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Password reset email sent'),
  //         backgroundColor: AppColors.success,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome back', style: AppStyles.headline1),
              const SizedBox(height: 8),
              Text(
                'Log in to access your account',
                style: AppStyles.bodyText1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                validator: Validators.validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                // child: TextButton(
                //   onPressed: _isLoading ? null : _resetPassword,
                //   child: Text(
                //     'Forgot password?',
                //     style: AppStyles.bodyText1.copyWith(
                //       color: AppColors.textSecondary,
                //       decoration: TextDecoration.underline,
                //     ),
                //   ),
                // ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Log In', style: AppStyles.buttonText),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                ),
                child: Text(
                  'Don\'t have an account? Sign Up',
                  style: AppStyles.bodyText1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
