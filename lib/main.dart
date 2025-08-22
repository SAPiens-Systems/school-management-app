import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projects/auth/controllers/auth_controller.dart';
import 'package:projects/auth/repositories/auth_repository.dart';
import 'package:projects/auth/repositories/user_repository.dart';
import 'package:projects/auth/views/login_screen.dart';
import 'package:projects/core/constants/app_colors.dart';
import 'package:projects/firebase_dev_setup.dart';
import 'package:projects/home/views/home_screen.dart';
import 'package:projects/students/controllers/student_controller.dart';
import 'package:projects/students/repositories/student_repository.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // 👇 Only use emulators in debug mode (not in production)
  assert(() {
    useFirebaseEmulators();
    return true;
  }());

  runApp(
    MultiProvider(
      providers: [
        // Option 2: Create repositories directly in controller
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(
            authRepo: AuthRepository(),
            userRepo: UserRepository(),
          ),
        ),

        // Add StudentController with same pattern
        ChangeNotifierProvider<StudentController>(
          create: (_) => StudentController(
            repository: StudentRepository(schoolId: 'default_school'),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: GoogleFonts.lexendTextTheme(Theme.of(context).textTheme),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData && ModalRoute.of(context)?.isCurrent == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
