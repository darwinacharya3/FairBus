import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:major_project/views/welcome_screen.dart';
import 'package:major_project/views/login_screen.dart';
import 'firebase_options.dart';
import 'package:major_project/views/forget_password_screen.dart';
// import 'package:major_project/views/reset_password_screen.dart';
// import 'package:major_project/views/otp_verification_screen.dart';
import 'package:major_project/views/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
   final textTheme = Theme.of(context).textTheme;

   return GetMaterialApp(
    initialRoute: '/welcome',
  getPages: [
    GetPage(name: '/welcome', page: () => const WelcomeScreen()),
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(name: '/forgetPassword', page: () => const ForgetPasswordScreen()),
    // GetPage(name: '/otpVerification', page: () => const OtpVerificationScreen()),
    // GetPage(name: '/resetPassword', page: () => const ResetPasswordScreen()),
    GetPage(name: '/home', page: () => const HomeScreen()), // Assuming home screen exists
  ],
    theme: ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(textTheme),
      
    ),
    
    home: const WelcomeScreen(),
   );
  }
}








// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:major_project/views/welcome_screen.dart';
// import 'firebase_options.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
// );
//   runApp(const Myapp());
// }

// class Myapp extends StatelessWidget {
//   const Myapp({super.key});

//   @override
//   Widget build(BuildContext context) {
//    final textTheme = Theme.of(context).textTheme;

//    return GetMaterialApp(
//     theme: ThemeData(
//       textTheme: GoogleFonts.poppinsTextTheme(textTheme),
      
//     ),
    
//     home: const WelcomeScreen(),
//    );
//   }
// }