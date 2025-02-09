import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:major_project/views/welcome_screen.dart';
import 'package:major_project/views/login_screen.dart';
import 'firebase_options.dart';
import 'package:major_project/views/forget_password_screen.dart';
import 'package:major_project/views/home_screen.dart';
import 'package:major_project/views/admin_user_list_screen.dart';
import 'package:major_project/views/user_verification_screen.dart';
import 'package:major_project/controller/admin_gaurd.dart';
import 'package:major_project/views/admin_dashboard_screen.dart';
import 'package:major_project/controller/auth_controller.dart';
import 'package:major_project/views/busjourney_monitor_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Initialize the AdminGuard
    Get.put(AdminGuard());

    return GetMaterialApp(
      title: 'Bus Fare Collection',
      initialRoute: '/welcome',
      getPages: [
        // Public routes (no guard needed)
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
            name: '/forgetPassword', page: () => const ForgetPasswordScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),

       GetPage(
          name: '/admin/dashboard',
          page: () => AdminDashboardScreen(),
          middlewares: [RouteGuard()],
          transition: Transition.fadeIn
      ),

    GetPage(
        name: '/admin/journeys',
        page: () => BusJourneyMonitorScreen(),
        middlewares: [RouteGuard()],
),
        // Protected admin routes with middleware
        GetPage(
            name: '/admin/users',
            page: () => AdminUserListScreen(),
            middlewares: [
              RouteGuard(),
            ],
            transition: Transition.fadeIn),

        GetPage(
          name: '/admin/verify-user',
          page: () => UserVerificationScreen(
            userData: Get.arguments['userData'],
            userId: Get.arguments['userId'],
          ),
          middlewares: [
            RouteGuard(),
          ],
        ),
      ],

      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(textTheme),
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),

      // Error handling for invalid routes
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: Center(
            child: Text(
              '404 - Page Not Found',
              style: GoogleFonts.poppins(fontSize: 20),
            ),
          ),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}



class RouteGuard extends GetMiddleware {
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    try {
      final adminGuard = Get.find<AdminGuard>();
      bool isAdmin = await adminGuard.isAdmin();

      if (!isAdmin) {
        Get.snackbar(
          'Access Denied',
          'You need admin privileges to access this section',
          backgroundColor: Colors.red[100],
          duration: const Duration(seconds: 3),
        );
        return GetNavConfig.fromRoute('/home');
      }

      // If user is admin but trying to access /admin, redirect to dashboard
      if (route.location == '/admin') {
        return GetNavConfig.fromRoute('/admin/dashboard');
      }

      return route;
    } catch (e) {
      return GetNavConfig.fromRoute('/home');
    }
  }
}






// class RouteGuard extends GetMiddleware {
//   @override
//   Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
//     try {
//       final adminGuard = Get.find<AdminGuard>();
//       bool isAdmin = await adminGuard.isAdmin();

//       // print("RouteGuard - Checking admin status: $isAdmin");

//       if (!isAdmin) {
//         // print("Access denied - Redirecting to home");
//         Get.snackbar(
//           'Access Denied',
//           'You need admin privileges to access this section',
//           backgroundColor: Colors.red[100],
//           duration: const Duration(seconds: 3),
//         );
//         return GetNavConfig.fromRoute('/home');
//       }

//       // print("Access granted - Proceeding to admin route: ${route.location}");
//       return route; // Return the original route instead of using super
//     } catch (e) {
//       // print("RouteGuard error: $e");
//       return GetNavConfig.fromRoute('/home');
//     }
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:major_project/views/welcome_screen.dart';
// import 'package:major_project/views/login_screen.dart';
// import 'firebase_options.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/views/forget_password_screen.dart';
// import 'package:major_project/views/home_screen.dart';
// import 'package:major_project/views/admin_user_list_screen.dart';
// import 'package:major_project/views/user_verification_screen.dart';
// import 'package:major_project/controller/admin_gaurd.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   Get.put(AuthController());

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return GetMaterialApp(
//       title: 'Bus Fare Collection',
//       initialRoute: '/welcome',
//       getPages: [
//         GetPage(name: '/welcome', page: () => const WelcomeScreen()),
//         GetPage(name: '/login', page: () => const LoginScreen()),
//         GetPage(name: '/forgetPassword', page: () => const ForgetPasswordScreen()),
//         GetPage(name: '/home', page: () => const HomeScreen()),

//         // Admin routes
//         GetPage(
//           name: '/admin/users',
//           page: () => AdminUserListScreen(),
//           middlewares: [AdminGuard()]  // Remove middleware temporarily
//         ),
//         GetPage(
//           name: '/admin/verify-user',
//           page: () => UserVerificationScreen(
//             userData: Get.arguments['userData'],
//             userId: Get.arguments['userId'],
//           ),
//           middlewares: [AdminGuard()]  // Remove middleware temporarily
//         ),
//       ],
//       theme: ThemeData(
//         textTheme: GoogleFonts.poppinsTextTheme(textTheme),
//         primarySwatch: Colors.green,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: const WelcomeScreen(),
//     );
//   }
// }

// class RouteGuard extends GetMiddleware {
//   @override
//   RouteSettings? redirect(String? route) {
//     return null; // Don't redirect, let the route proceed
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:major_project/views/welcome_screen.dart';
// import 'package:major_project/views/login_screen.dart';
// import 'firebase_options.dart';
// import 'package:major_project/views/forget_password_screen.dart';
// import 'package:major_project/views/home_screen.dart';
// import 'package:major_project/views/admin_user_list_screen.dart';
// import 'package:major_project/views/user_verification_screen.dart';

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
//     initialRoute: '/welcome',
//   getPages: [
//     GetPage(name: '/welcome', page: () => const WelcomeScreen()),
//     GetPage(name: '/login', page: () => const LoginScreen()),
//     GetPage(name: '/forgetPassword', page: () => const ForgetPasswordScreen()),
//     GetPage(name: '/home', page: () => const HomeScreen()),
//     GetPage(name: '/admin/users', page: () => AdminUserListScreen(),),
//     GetPage(
//         name: '/admin/verify-user',
//         page: () => UserVerificationScreen(
//         userData: Get.arguments['userData'],
//         userId: Get.arguments['userId'],
//   ),
// ),

//   ],

//     theme: ThemeData(
//       textTheme: GoogleFonts.poppinsTextTheme(textTheme),

//     ),

//     home: const WelcomeScreen(),
//    );
//   }
// }

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
