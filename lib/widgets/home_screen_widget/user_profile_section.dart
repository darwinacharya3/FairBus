import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:major_project/utils/cloudinary_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:major_project/controller/balance_controller.dart';

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({super.key});

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BalanceController _balanceController = Get.put(BalanceController());

  String _username = "";
  String _profileImageUrl = "";
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = "";
  
  bool _isVerified = false;
  String _verificationStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = "";
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw "No authenticated user found";
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw "User document not found";
      }

      Map<String, dynamic> userData = userDoc.data()!;

      setState(() {
        _username = userData['username']?.toString() ?? "User";
        _profileImageUrl = userData['profileUrl']?.toString() ?? "";
        _isVerified = userData['isVerified'] ?? false;
        _verificationStatus =
            userData['verificationStatus']?.toString() ?? 'pending';
      });

      await _balanceController.loadBalance();

        
     
    } catch (e) {
      // print("Error in _loadUserData: $e");
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _username = "User";
        _profileImageUrl = "";
        
        _isVerified = false;
        _verificationStatus = 'pending';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadNewProfileImage() async {
    try {
      setState(() => _isLoading = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        User? user = _auth.currentUser;
        if (user == null) throw "User not authenticated";

        String? cloudinaryUrl = await CloudinaryHelper.uploadImageToCloudinary(
          pickedFile.path,
          _username,
        );

        if (cloudinaryUrl != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'profileUrl': cloudinaryUrl,
          });

          setState(() {
            _profileImageUrl = cloudinaryUrl;
            _isError = false;
            _errorMessage = "";
          });

          Get.snackbar(
            "Success",
            "Profile picture updated successfully!",
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
          );
        } else {
          throw "Failed to upload image to Cloudinary";
        }
      }
    } catch (e) {
      // print("Error in _uploadNewProfileImage: $e");
      Get.snackbar(
        "Error",
        "Failed to update profile picture: $e",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildVerificationBadge() {
    if (_isVerified) {
      return Tooltip(
        message: 'Verified Account',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 16,
            color: Colors.white,
          ),
        ),
      );
    } else if (_verificationStatus == 'pending') {
      return Tooltip(
        message: 'Verification Pending',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange[400],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_empty,
            size: 16,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _profileImageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 40),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _uploadNewProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Welcome, $_username!",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildVerificationBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(() => Text(
                      "NPR ${_balanceController.balance.value.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 12,
                      //     vertical: 6,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFF4CAF50).withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Text(
                      //     "NPR ${_balance.toStringAsFixed(2)}",
                      //     style: GoogleFonts.poppins(
                      //       fontSize: 14,
                      //       color: const Color(0xFF4CAF50),
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}













  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: const Color(0xFF4CAF50).withOpacity(0.3),
  //         width: 1.5,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: _isLoading 
  //         ? const Center(
  //             child: CircularProgressIndicator(
  //               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
  //             ),
  //           )
  //         : Row(
  //             children: [
  //               Stack(
  //                 children: [
  //                   Container(
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       border: Border.all(
  //                         color: const Color(0xFF4CAF50),
  //                         width: 2,
  //                       ),
  //                     ),
  //                     child: ClipOval(
  //                       child: _profileImageUrl.isNotEmpty
  //                           ? CachedNetworkImage(
  //                               imageUrl: _profileImageUrl,
  //                               width: 80,
  //                               height: 80,
  //                               fit: BoxFit.cover,
  //                               placeholder: (context, url) => Container(
  //                                 color: Colors.grey[200],
  //                                 child: const Icon(Icons.person, size: 40),
  //                               ),
  //                               errorWidget: (context, url, error) =>
  //                                   const Icon(Icons.error),
  //                             )
  //                           : Container(
  //                               width: 80,
  //                               height: 80,
  //                               color: Colors.grey[200],
  //                               child: const Icon(Icons.person, size: 40),
  //                             ),
  //                     ),
  //                   ),
  //                   Positioned(
  //                     bottom: 0,
  //                     right: 0,
  //                     child: GestureDetector(
  //                       onTap: _isLoading ? null : _uploadNewProfileImage,
  //                       child: Container(
  //                         padding: const EdgeInsets.all(6),
  //                         decoration: BoxDecoration(
  //                           color: const Color(0xFF4CAF50),
  //                           shape: BoxShape.circle,
  //                           border: Border.all(color: Colors.white, width: 2),
  //                         ),
  //                         child: const Icon(
  //                           Icons.camera_alt,
  //                           size: 14,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Text(
  //                           "Welcome, $_username!",
  //                           style: GoogleFonts.poppins(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.black87,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         _buildVerificationBadge(),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF4CAF50).withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: Text(
  //                         "NPR ${_balance.toStringAsFixed(2)}",
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 14,
  //                           color: const Color(0xFF4CAF50),
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //   );
  // }
// }













// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:major_project/utils/cloudinary_helper.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class UserProfileSection extends StatefulWidget {
//   const UserProfileSection({Key? key}) : super(key: key);

//   @override
//   State<UserProfileSection> createState() => _UserProfileSectionState();
// }

// class _UserProfileSectionState extends State<UserProfileSection> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String _username = "";
//   String _profileImageUrl = "";
//   bool _isLoading = false;
//   bool _isError = false;
//   String _errorMessage = "";
//   double _balance = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     setState(() {
//       _isLoading = true;
//       _isError = false;
//       _errorMessage = "";
//     });

//     try {
//       User? user = _auth.currentUser;
//       if (user == null) {
//         throw "No authenticated user found";
//       }

//       // Get user document with error handling
//       DocumentSnapshot<Map<String, dynamic>> userDoc = 
//           await _firestore.collection('users').doc(user.uid).get();

//       if (!userDoc.exists || userDoc.data() == null) {
//         throw "User document not found";
//       }

//       // Safely access the fields with null checking
//       Map<String, dynamic> userData = userDoc.data()!;
      
//       setState(() {
//         // Safely get username with null check and type casting
//         _username = userData['username']?.toString() ?? "User";
        
//         // Safely get profileUrl with null check
//         _profileImageUrl = userData['profileUrl']?.toString() ?? "";
        
//         // Safely get balance with null check and conversion
//         var balanceData = userData['balance'];
//         if (balanceData != null) {
//           if (balanceData is int) {
//             _balance = balanceData.toDouble();
//           } else if (balanceData is double) {
//             _balance = balanceData;
//           } else {
//             _balance = 0.0;
//           }
//         }
        
//         _isError = false;
//         _errorMessage = "";
//       });
//     } catch (e) {
//       print("Error in _loadUserData: $e"); // Debug print
//       setState(() {
//         _isError = true;
//         _errorMessage = e.toString();
//         // Set default values in case of error
//         _username = "User";
//         _profileImageUrl = "";
//         _balance = 0.0;
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _uploadNewProfileImage() async {
//     try {
//       setState(() => _isLoading = true);
      
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );

//       if (pickedFile != null) {
//         User? user = _auth.currentUser;
//         if (user == null) throw "User not authenticated";

//         // Upload to Cloudinary
//         String? cloudinaryUrl = await CloudinaryHelper.uploadImageToCloudinary(
//           pickedFile.path,
//           _username,
//         );

//         if (cloudinaryUrl != null) {
//           // Update Firestore with new URL
//           await _firestore.collection('users').doc(user.uid).update({
//             'profileUrl': cloudinaryUrl,
//           });

//           setState(() {
//             _profileImageUrl = cloudinaryUrl;
//             _isError = false;
//             _errorMessage = "";
//           });
          
//           Get.snackbar(
//             "Success",
//             "Profile picture updated successfully!",
//             backgroundColor: Colors.green[100],
//             colorText: Colors.green[900],
//           );
//         } else {
//           throw "Failed to upload image to Cloudinary";
//         }
//       }
//     } catch (e) {
//       print("Error in _uploadNewProfileImage: $e");
//       Get.snackbar(
//         "Error",
//         "Failed to update profile picture: $e",
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[900],
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: const Color(0xFF4CAF50).withOpacity(0.3),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: _isLoading 
//           ? const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
//               ),
//             )
//           : Row(
//               children: [
//                 // Profile Picture
//                 Stack(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: const Color(0xFF4CAF50),
//                           width: 2,
//                         ),
//                       ),
//                       child: ClipOval(
//                         child: _profileImageUrl.isNotEmpty
//                             ? CachedNetworkImage(
//                                 imageUrl: _profileImageUrl,
//                                 width: 80,
//                                 height: 80,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => Container(
//                                   color: Colors.grey[200],
//                                   child: const Icon(Icons.person, size: 40),
//                                 ),
//                                 errorWidget: (context, url, error) =>
//                                     const Icon(Icons.error),
//                               )
//                             : Container(
//                                 width: 80,
//                                 height: 80,
//                                 color: Colors.grey[200],
//                                 child: const Icon(Icons.person, size: 40),
//                               ),
//                       ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: _isLoading ? null : _uploadNewProfileImage,
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF4CAF50),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 2),
//                           ),
//                           child: const Icon(
//                             Icons.camera_alt,
//                             size: 14,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 16),
//                 // User Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Welcome, $_username!",
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF4CAF50).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           "NPR ${_balance.toStringAsFixed(2)}",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: const Color(0xFF4CAF50),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }



















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
// @override
// Widget build(BuildContext context) {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: const Color(0xFFF5F5F5), // Light gray background
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: const Color(0xFF4CAF50), // Green border color
//         width: 1.5,
//       ),
//       boxShadow: const [
//         BoxShadow(
//           color: Colors.black12,
//           blurRadius: 10,
//           offset: Offset(0, 4),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         // Profile Picture with Edit Icon
//         Stack(
//           children: [
//             CircleAvatar(
//               radius: 40,
//               backgroundImage: _profileImage != null
//                   ? FileImage(_profileImage!)
//                   : (_profileImageUrl.isNotEmpty
//                       ? NetworkImage(_profileImageUrl)
//                       : const AssetImage('assets/avatar_placeholder.png'))
//                           as ImageProvider,
//             ),
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: GestureDetector(
//                 onTap: _uploadProfileImage,
//                 child: const CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.green,
//                   child:Icon(
//                     Icons.camera_alt,
//                     size: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(width: 16),
//         // User Details and Balance
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 _greetingText,
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "Balance: NPR 500",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Edit Profile Button
//         ElevatedButton.icon(
//           onPressed: () {
//             debugPrint("Edit Profile clicked.");
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF4CAF50),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           ),
//           icon: const Icon(Icons.edit, size: 18),
//           label: Text(
//             "Edit",
//             style: GoogleFonts.poppins(fontSize: 14),
//           ),
//         ),
//       ],
//     ),
//   );
// }  
// }










