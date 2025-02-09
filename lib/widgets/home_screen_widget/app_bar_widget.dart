import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:major_project/controller/auth_controller.dart';
import 'package:major_project/views/setup_profile_screen.dart';
import 'package:major_project/views/notification_screen.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final AuthController authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      title: Text(
        'Bus Fare Collection',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) async {
            if (value == 'setupProfile') {
              Get.to(() => SetupProfileScreen());
            } else if (value == 'logout') {
              await _showLogoutDialog(context);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'setupProfile',
              child: Text(
                'Setup Profile',
                style: GoogleFonts.poppins(color: Colors.green),
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
          color: Colors.white,
          elevation: 5,
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => Get.to(() => const NotificationScreen()),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await authController.logoutUser();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}





















// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/views/setup_profile_screen.dart';
// // import 'package:major_project/views/login_screen.dart';

// class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   final AuthController authController = Get.find<AuthController>();
  
//   AppBarWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.green,
//       title: Text(
//         'Bus Fare Collection',
//         style: GoogleFonts.poppins(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       actions: [
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.person),
//           onSelected: (value) async {
//             if (value == 'setupProfile') {
//               Get.to(() => SetupProfileScreen());
//             } else if (value == 'logout') {
//               await _showLogoutDialog(context);
//             }
//           },
//           itemBuilder: (BuildContext context) => [
//             PopupMenuItem<String>(
//               value: 'setupProfile',
//               child: Text(
//                 'Setup Profile',
//                 style: GoogleFonts.poppins(color: Colors.green),
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'logout',
//               child: Text(
//                 'Logout',
//                 style: GoogleFonts.poppins(color: Colors.red),
//               ),
//             ),
//           ],
//           color: Colors.white,
//           elevation: 5,
//         ),
//         IconButton(
//           icon: const Icon(Icons.notifications),
//           onPressed: () {
//             // print("Notification Icon clicked");
//           },
//         ),
//       ],
//     );
//   }

//   Future<void> _showLogoutDialog(BuildContext context) async {
//     return showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Confirm Logout'),
//           content: const Text('Are you sure you want to logout?'),
//           actions: [
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Logout'),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await authController.logoutUser();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }








// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// import 'package:major_project/views/setup_profile_screen.dart';
// // import 'package:major_project/views/login_screen.dart';
// import 'package:major_project/controller/auth_controller.dart';
// // import 'package:major_project/controllers/auth_controller.dart';

// class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   final AuthController authController = Get.find<AuthController>();
  
//   AppBarWidget({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.green,
//       title: Text(
//         'Bus Fare Collection',
//         style: GoogleFonts.poppins(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       leading: Navigator.canPop(context)
//           ? IconButton(
//               icon: const Icon(Icons.arrow_back),
//               onPressed: () => Navigator.pop(context),
//             )
//           : null,
//       actions: [
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.person),
//           onSelected: (value) async {
//             switch (value) {
//               case 'setupProfile':
//                 Get.to(() => SetupProfileScreen());
//                 break;
//               case 'logout':
//                 await _showLogoutConfirmation(context);
//                 break;
//             }
//           },
//           itemBuilder: (BuildContext context) {
//             return [
//               PopupMenuItem<String>(
//                 value: 'setupProfile',
//                 child: Text(
//                   'Setup Profile',
//                   style: GoogleFonts.poppins(
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//               PopupMenuItem<String>(
//                 value: 'logout',
//                 child: Text(
//                   'Logout',
//                   style: GoogleFonts.poppins(
//                     color: Colors.red,
//                   ),
//                 ),
//               ),
//             ];
//           },
//           color: Colors.white,
//           elevation: 5,
//         ),
//         IconButton(
//           icon: const Icon(Icons.notifications),
//           onPressed: () {
//             print("Notification Icon clicked");
//           },
//         ),
//       ],
//     );
//   }

//   Future<void> _showLogoutConfirmation(BuildContext context) async {
//     final bool confirm = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Confirm Logout',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Are you sure you want to logout?',
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             TextButton(
//               child: Text(
//                 'Cancel',
//                 style: GoogleFonts.poppins(color: Colors.grey),
//               ),
//               onPressed: () => Navigator.of(context).pop(false),
//             ),
//             TextButton(
//               child: Text(
//                 'Logout',
//                 style: GoogleFonts.poppins(color: Colors.red),
//               ),
//               onPressed: () => Navigator.of(context).pop(true),
//             ),
//           ],
//         );
//       },
//     ) ?? false;

//     if (confirm) {
//       try {
//         await authController.logoutUser();
//       } catch (e) {
//         Get.snackbar(
//           "Error",
//           "Failed to logout. Please try again.",
//           backgroundColor: Colors.red.withOpacity(0.1),
//           duration: const Duration(seconds: 3),
//         );
//       }
//     }
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

