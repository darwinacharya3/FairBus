import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({Key? key}) : super(key: key);

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _profileImage;
  String _username = "Loading...";
  String _greetingText = "Welcome!";
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        setState(() {
          _username = userDoc['username'] ?? "User";
          _greetingText = "Welcome, $_username!";
          _profileImageUrl = userDoc['profileImageUrl'] ?? "";
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user data: ${e.toString()}");
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        User? user = _auth.currentUser;
        if (user != null) {
          // In production, you should upload this to Cloudinary or Firebase Storage
          await _firestore.collection('users').doc(user.uid).update({
            'profileImageUrl': pickedFile.path, // Replace with uploaded URL
          });

          Get.snackbar("Success", "Profile picture updated successfully!");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to upload profile picture: ${e.toString()}");
    }
  }
@override
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5), // Light gray background
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF4CAF50), // Green border color
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Profile Picture with Edit Icon
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : (_profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl)
                      : const AssetImage('assets/avatar_placeholder.png'))
                          as ImageProvider,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _uploadProfileImage,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.green,
                  child:Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // User Details and Balance
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingText,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Balance: NPR 500",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Edit Profile Button
        ElevatedButton.icon(
          onPressed: () {
            debugPrint("Edit Profile clicked.");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.edit, size: 18),
          label: Text(
            "Edit",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

  
}









// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

// class UserProfileSection extends StatefulWidget {
//   const UserProfileSection({Key? key}) : super(key: key);

//   @override
//   State<UserProfileSection> createState() => _UserProfileSectionState();
// }

// class _UserProfileSectionState extends State<UserProfileSection> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   File? _profileImage;
//   String _username = "Loading...";
//   String _greetingText = "Welcome!";
//   String _profileImageUrl = "";

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       User? user = _auth.currentUser;
//       if (user != null) {
//         DocumentSnapshot userDoc =
//             await _firestore.collection('users').doc(user.uid).get();

//         setState(() {
//           _username = userDoc['username'] ?? "User";
//           _greetingText = "Welcome, $_username!";
//           _profileImageUrl = userDoc['profileImageUrl'] ?? "";
//         });
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to load user data: ${e.toString()}");
//     }
//   }

//   Future<void> _uploadProfileImage() async {
//     try {
//       final picker = ImagePicker();
//       final pickedFile =
//           await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

//       if (pickedFile != null) {
//         setState(() {
//           _profileImage = File(pickedFile.path);
//         });

//         User? user = _auth.currentUser;
//         if (user != null) {
//           // For demonstration, we'll only update Firestore with the local file path
//           // In production, you should upload this to Cloudinary or Firebase Storage
//           await _firestore.collection('users').doc(user.uid).update({
//             'profileImageUrl': pickedFile.path, // Replace with uploaded URL
//           });

//           Get.snackbar("Success", "Profile picture updated successfully!");
//         }
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to upload profile picture: ${e.toString()}");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Stack(
//             children: [
//               CircleAvatar(
//                 radius: 40,
//                 backgroundImage: _profileImage != null
//                     ? FileImage(_profileImage!)
//                     : (_profileImageUrl.isNotEmpty
//                         ? NetworkImage(_profileImageUrl)
//                         : const AssetImage('assets/avatar_placeholder.png'))
//                             as ImageProvider,
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: GestureDetector(
//                   onTap: _uploadProfileImage,
//                   child: CircleAvatar(
//                     radius: 12,
//                     backgroundColor: Colors.green,
//                     child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 _greetingText,
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Balance: NPR 500",
//                 style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class UserProfileSection extends StatelessWidget {
//   const UserProfileSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green, Colors.lightGreen],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           // Profile Image
//           CircleAvatar(
//             radius: 40,
//             backgroundColor: Colors.white,
//             child: CircleAvatar(
//               radius: 38,
//               backgroundImage: AssetImage('assets/avatar_placeholder.png'),
//             ),
//           ),
//           const SizedBox(width: 16),

//           // User Info
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "John Doe",
//                 style: GoogleFonts.poppins(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "Balance: NPR 500",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.white70,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: () {
//                   print("Edit Profile button clicked");
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Colors.green,
//                   elevation: 5,
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 8,
//                     horizontal: 16,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 child: Text(
//                   "Edit Profile",
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // Spacer to push Notification Icon to the right
//           const Spacer(),

//           // Notification Icon
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {
//               print("Notification Icon clicked");
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
