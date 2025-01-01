import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:major_project/views/setup_profile_screen.dart';
import 'package:major_project/views/login_screen.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green, // Green color theme
      title: Text(
        'Bus Fare Collection',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Profile Icon with Popup Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) {
            if (value == 'setupProfile') {
              // Navigate to Setup Profile screen
              Get.to(() => SetupProfileScreen());
            } else if (value == 'logout') {
              // Perform logout
              _logout(context);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // Popup Menu items styled to match the app theme
              PopupMenuItem<String>(
                value: 'setupProfile',
                child: Text(
                  'Setup Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.green, // Text color matches app theme
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: Colors.red, // Red color for logout to signify action
                  ),
                ),
              ),
            ];
          },
          color: Colors.white, // White background for the popup
          elevation: 5,
        ),
        
        // Notification Icon (Settings)
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Handle notifications click
            print("Notification Icon clicked");
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height

  // Logout method
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen after logout
      Get.offAll(() => const LoginScreen());  // Replace with your actual login screen
    } catch (e) {
      print("Error logging out: $e");
      // Optionally show an error dialog or message
    }
  }
}








// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/views/setup_profile_screen.dart';
// import 'package:major_project/views/login_screen.dart';

// class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   const AppBarWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.green,
//       title: Text(
//         'Bus Fare Collection',
//         style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//       ),
//       actions: [
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.person),
//           onSelected: (value) {
//             if (value == 'setupProfile') {
//               Get.to(() => SetupProfileScreen());
//             } else if (value == 'logout') {
//               _logout(context);
//             }
//           },
//           itemBuilder: (context) => [
//             PopupMenuItem(
//               value: 'setupProfile',
//               child: Text('Setup Profile', style: GoogleFonts.poppins(),
//               ),
              
//             ),
//             PopupMenuItem(
//               value: 'logout',
//               child: Text('Logout', style: GoogleFonts.poppins()),
//             ),
//           ],
//         ),
//         IconButton(
//           icon: const Icon(Icons.notifications),
//           onPressed: () {
//             debugPrint("Notification icon tapped.");
//           },
//         ),
//       ],
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   Future<void> _logout(BuildContext context) async {
//     debugPrint("User logged out.");
//     Get.offAll(() => const LoginScreen());
//   }
// }
