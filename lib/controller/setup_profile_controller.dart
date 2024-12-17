import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:major_project/utils/cloudinary_helper.dart'; // Update this path as necessary

class SetupProfileController extends GetxController {
  var profileImage = Rx<File?>(null);
  var frontCitizenshipImage = Rx<File?>(null);
  var backCitizenshipImage = Rx<File?>(null);
  TextEditingController citizenshipNumberController = TextEditingController();
  TextEditingController usernameController = TextEditingController(); // Add controller for username

  final ImagePicker picker = ImagePicker();

  // Cloudinary image URLs
  String? profileImageUrl;
  String? citizenshipFrontUrl;
  String? citizenshipBackUrl;

  // Fetch the username from Firestore
  Future<String?> getUsername() async {
    try {
      // Get the current user's UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch the username from Firestore based on the UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Return the username
        return userDoc['username'];
      }
      return null; // User is not logged in
    } catch (e) {
      print("Error fetching username: $e");
      return null;
    }
  }

  void pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) profileImage.value = File(pickedFile.path);
  }

  void captureImageWithCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) profileImage.value = File(pickedFile.path);
  }

  void pickFrontCitizenshipImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) frontCitizenshipImage.value = File(pickedFile.path);
  }

  void pickBackCitizenshipImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) backCitizenshipImage.value = File(pickedFile.path);
  }

  // Function to upload profile images to Cloudinary
  Future<void> uploadProfileImages({
    required String profileImagePath,
    required String citizenshipFrontPath,
    required String citizenshipBackPath,
    required String username, // Accept username as parameter
  }) async {
    try {
      // Upload profile image
      profileImageUrl = await CloudinaryHelper.uploadImageToCloudinary(profileImagePath, username);
      if (profileImageUrl == null) {
        throw 'Failed to upload profile image.';
      }
      print("Profile Image URL: $profileImageUrl");

      // Upload citizenship front image
      citizenshipFrontUrl = await CloudinaryHelper.uploadImageToCloudinary(citizenshipFrontPath, username);
      if (citizenshipFrontUrl == null) {
        throw 'Failed to upload citizenship front image.';
      }
      print("Front Citizenship Image URL: $citizenshipFrontUrl");

      // Upload citizenship back image
      citizenshipBackUrl = await CloudinaryHelper.uploadImageToCloudinary(citizenshipBackPath, username);
      if (citizenshipBackUrl == null) {
        throw 'Failed to upload citizenship back image.';
      }
      print("Back Citizenship Image URL: $citizenshipBackUrl");

      print("All images uploaded successfully!");
    } catch (e) {
      print("Error uploading images: $e");
      rethrow;
    }
  }

  Future <void>saveProfileToFirestore() async {
  try {
    // Get the current user's UID
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "User not logged in. Please log in again.");
      return;
    }
    String uid = currentUser.uid;

    // Save data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileUrl': profileImageUrl,
      'citizenshipFrontUrl': citizenshipFrontUrl,
      'citizenshipBackUrl': citizenshipBackUrl,
      'citizenshipNumber': citizenshipNumberController.text.trim(),
      'profileUpdated': FieldValue.serverTimestamp(), // Optional: Add a timestamp
    });

    // Notify the user
    Get.snackbar("Success", "Profile information saved successfully!");
  } catch (e) {
    print("Error saving profile data: $e");
    Get.snackbar("Error", "Failed to save profile information: $e");
  }
}

void submitProfile() async {
  if (citizenshipNumberController.text.isEmpty ||
      profileImage.value == null ||
      frontCitizenshipImage.value == null ||
      backCitizenshipImage.value == null) {
    Get.snackbar("Error", "All fields are required!");
    return;
  }

  try {
    // Fetch username dynamically from Firestore
    String? username = await getUsername();
    if (username == null) {
      Get.snackbar("Error", "User not found. Please log in.");
      return;
    }

    // Show loading indicator
    Get.snackbar("Uploading", "Uploading your profile data...");

    // Upload images to Cloudinary
    await uploadProfileImages(
      profileImagePath: profileImage.value!.path,
      citizenshipFrontPath: frontCitizenshipImage.value!.path,
      citizenshipBackPath: backCitizenshipImage.value!.path,
      username: username, // Pass username dynamically
    );

    // Save data to Firestore
    await saveProfileToFirestore();

    // Notify the user
    Get.snackbar("Success", "Profile setup complete!");
  } catch (e) {
    Get.snackbar("Error", "Failed to upload profile data: $e");
    print("Error: $e");
  }
}
}


































// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:major_project/utils/cloudinary_helper.dart'; // Update this path as necessary

// class SetupProfileController extends GetxController {
//   var profileImage = Rx<File?>(null);
//   var frontCitizenshipImage = Rx<File?>(null);
//   var backCitizenshipImage = Rx<File?>(null);
//   TextEditingController citizenshipNumberController = TextEditingController();
//   TextEditingController usernameController = TextEditingController(); // Add controller for username

//   final ImagePicker picker = ImagePicker();

//   // Cloudinary image URLs
//   String? profileImageUrl;
//   String? citizenshipFrontUrl;
//   String? citizenshipBackUrl;

//   // Fetch the username from Firestore
//   Future<String?> getUsername() async {
//     try {
//       // Get the current user's UID
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Fetch the username from Firestore based on the UID
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         // Return the username
//         return userDoc['username'];
//       }
//       return null; // User is not logged in
//     } catch (e) {
//       print("Error fetching username: $e");
//       return null;
//     }
//   }

//   void pickImageFromGallery() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) profileImage.value = File(pickedFile.path);
//   }

//   void captureImageWithCamera() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) profileImage.value = File(pickedFile.path);
//   }

//   void pickFrontCitizenshipImage() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) frontCitizenshipImage.value = File(pickedFile.path);
//   }

//   void pickBackCitizenshipImage() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) backCitizenshipImage.value = File(pickedFile.path);
//   }

//   // Function to upload profile images to Cloudinary
//   Future<void> uploadProfileImages({
//     required String profileImagePath,
//     required String citizenshipFrontPath,
//     required String citizenshipBackPath,
//     required String username, // Accept username as parameter
//   }) async {
//     try {
//       // Upload profile image
//       profileImageUrl = await CloudinaryHelper.uploadImageToCloudinary(profileImagePath, username);
//       if (profileImageUrl == null) {
//         throw 'Failed to upload profile image.';
//       }
//       print("Profile Image URL: $profileImageUrl");

//       // Upload citizenship front image
//       citizenshipFrontUrl = await CloudinaryHelper.uploadImageToCloudinary(citizenshipFrontPath, username);
//       if (citizenshipFrontUrl == null) {
//         throw 'Failed to upload citizenship front image.';
//       }
//       print("Front Citizenship Image URL: $citizenshipFrontUrl");

//       // Upload citizenship back image
//       citizenshipBackUrl = await CloudinaryHelper.uploadImageToCloudinary(citizenshipBackPath, username);
//       if (citizenshipBackUrl == null) {
//         throw 'Failed to upload citizenship back image.';
//       }
//       print("Back Citizenship Image URL: $citizenshipBackUrl");

//       print("All images uploaded successfully!");
//     } catch (e) {
//       print("Error uploading images: $e");
//       rethrow;
//     }
//   }

//   Future <void>saveProfileToFirestore() async {
//   try {
//     // Get the current user's UID
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       Get.snackbar("Error", "User not logged in. Please log in again.");
//       return;
//     }
//     String uid = currentUser.uid;

//     // Save data to Firestore
//     await FirebaseFirestore.instance.collection('users').doc(uid).update({
//       'profileUrl': profileImageUrl,
//       'citizenshipFrontUrl': citizenshipFrontUrl,
//       'citizenshipBackUrl': citizenshipBackUrl,
//       'citizenshipNumber': citizenshipNumberController.text.trim(),
//       'profileUpdated': FieldValue.serverTimestamp(), // Optional: Add a timestamp
//     });

//     // Notify the user
//     Get.snackbar("Success", "Profile information saved successfully!");
//   } catch (e) {
//     print("Error saving profile data: $e");
//     Get.snackbar("Error", "Failed to save profile information: $e");
//   }
// }

// void submitProfile() async {
//   if (citizenshipNumberController.text.isEmpty ||
//       profileImage.value == null ||
//       frontCitizenshipImage.value == null ||
//       backCitizenshipImage.value == null) {
//     Get.snackbar("Error", "All fields are required!");
//     return;
//   }

//   try {
//     // Fetch username dynamically from Firestore
//     String? username = await getUsername();
//     if (username == null) {
//       Get.snackbar("Error", "User not found. Please log in.");
//       return;
//     }

//     // Show loading indicator
//     Get.snackbar("Uploading", "Uploading your profile data...");

//     // Upload images to Cloudinary
//     await uploadProfileImages(
//       profileImagePath: profileImage.value!.path,
//       citizenshipFrontPath: frontCitizenshipImage.value!.path,
//       citizenshipBackPath: backCitizenshipImage.value!.path,
//       username: username, // Pass username dynamically
//     );

//     // Save data to Firestore
//     await saveProfileToFirestore();

//     // Notify the user
//     Get.snackbar("Success", "Profile setup complete!");
//   } catch (e) {
//     Get.snackbar("Error", "Failed to upload profile data: $e");
//     print("Error: $e");
//   }
// }
// }




























