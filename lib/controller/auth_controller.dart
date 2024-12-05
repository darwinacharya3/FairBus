import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:math';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    Future<void> registerUser({
    required String name,
    required String mobile,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'mobile': mobile,
        'email': email,
        'username': username,
        'password' : password,
        'accepted_terms': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "User registered successfully!");
      Get.toNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Failed to register user: ${e.toString()}");
    }
  }

  // Check if email exists in Firebase
  Future<bool> checkEmailRegistered(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      Get.snackbar("Error", "Failed to check email: ${e.toString()}");
      return false;
    }
  }

  // Send OTP to email
  Future<void> sendOtpToEmail(String email) async {
    try {
      String otp = _generateOtp();
      // Ideally, you would send this OTP via a backend service or Firebase function.
      await _auth.sendPasswordResetEmail(email: email);
      
      Get.snackbar("Success", "OTP sent to your email!");
      // Store OTP in user data for comparison during verification (temporary solution)
      // In practice, you should store this in a secure way
      await _firestore.collection('users').doc(email).update({'otp': otp});

    } catch (e) {
      Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
    }
  }

  // Generate random 6-digit OTP
  String _generateOtp() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Verify OTP and reset password
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      await user?.updatePassword(newPassword);
      Get.snackbar("Success", "Password updated successfully!");
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (query.docs.isEmpty) {
        Get.snackbar("Error", "No user found with this username");
        return false;
      }

      var userDoc = query.docs.first;
      String email = userDoc['email'];

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar("Error", "Login failed: ${e.toString()}");
      return false;
    }
  }
}


































// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Register User
//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password, // Note: Avoid storing passwords as plaintext in production
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // Check if email is already registered
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to user's email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Simulate sending the OTP via email (use backend in production)
//       Get.snackbar("OTP Sent", "Your OTP is: $otp");

//       // Temporarily store OTP in Firestore
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (query.docs.isNotEmpty) {
//         String uid = query.docs.first.id;
//         await _firestore.collection('users').doc(uid).update({'otp': otp});
//       } else {
//         Get.snackbar("Error", "Email not registered!");
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate a random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String otp,
//     required String newPassword,
//   }) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "Email not found!");
//         return;
//       }

//       String storedOtp = query.docs.first.get('otp');
//       if (storedOtp != otp) {
//         Get.snackbar("Error", "Invalid OTP!");
//         return;
//       }

//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);

//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   // Login User
//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }









// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Register User
//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       User? user = userCredential.user;
//       if (user == null) {
//         throw FirebaseAuthException(
//             code: "USER_CREATION_FAILED", message: "User creation failed.");
//       }

//       String uid = user.uid;

//       // Save user data to Firestore
//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // Check if email exists in Firebase
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Ideally, you would send this OTP via a backend service or Firebase function.
//       await _auth.sendPasswordResetEmail(email: email);

//       Get.snackbar("Success", "OTP sent to your email!");
//       // Store OTP in user data for comparison during verification (temporary solution)
//       // In practice, you should store this in a secure way
//       await _firestore.collection('users').doc(email).update({'otp': otp});
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       if (user == null) {
//         throw FirebaseAuthException(
//             code: "USER_NOT_FOUND", message: "No user is currently signed in.");
//       }

//       await user.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   // Login User
//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }



















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // User Registration
//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'uid': uid,
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'accepted_terms': true,
//         'profileCompleted': false, // Initially profile setup is incomplete
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // Check if Email is Registered
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP for Email Verification
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Sending OTP via backend/email service should replace this placeholder
//       await _auth.sendPasswordResetEmail(email: email);

//       // Temporarily storing OTP in Firestore (For demonstration purposes only)
//       await _firestore
//           .collection('otp_verifications')
//           .doc(email)
//           .set({'otp': otp, 'createdAt': FieldValue.serverTimestamp()});

//       Get.snackbar("Success", "OTP sent to your email!");
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate Random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and Reset Password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String otp,
//     required String newPassword,
//   }) async {
//     try {
//       DocumentSnapshot otpDoc = await _firestore
//           .collection('otp_verifications')
//           .doc(email)
//           .get();

//       if (otpDoc.exists && otpDoc['otp'] == otp) {
//         // Reset password
//         User? user = _auth.currentUser;
//         await user?.updatePassword(newPassword);

//         // Clean up OTP record after successful verification
//         await _firestore.collection('otp_verifications').doc(email).delete();

//         Get.snackbar("Success", "Password updated successfully!");
//         Get.offAllNamed('/login');
//       } else {
//         Get.snackbar("Error", "Invalid or expired OTP.");
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   // Login User
//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);

//       if (!userDoc['profileCompleted']) {
//         Get.toNamed('/setupProfile'); // Redirect to Profile Setup Screen
//       } else {
//         Get.toNamed('/home'); // Redirect to Home Screen
//       }
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }

//   // Update User Profile Completion
//   Future<void> updateUserProfileCompletion({
//     required String profilePhotoUrl,
//     required String citizenshipNumber,
//     required String frontCitizenshipPhotoUrl,
//     required String backCitizenshipPhotoUrl,
//   }) async {
//     try {
//       String uid = _auth.currentUser!.uid;

//       await _firestore.collection('users').doc(uid).update({
//         'profilePhotoUrl': profilePhotoUrl,
//         'citizenshipNumber': citizenshipNumber,
//         'frontCitizenshipPhotoUrl': frontCitizenshipPhotoUrl,
//         'backCitizenshipPhotoUrl': backCitizenshipPhotoUrl,
//         'profileCompleted': true,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "Profile setup completed successfully!");
//       Get.toNamed('/home');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to complete profile setup: ${e.toString()}");
//     }
//   }
// }














// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//     Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password' : password,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // Check if email exists in Firebase
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Ideally, you would send this OTP via a backend service or Firebase function.
//       await _auth.sendPasswordResetEmail(email: email);
      
//       Get.snackbar("Success", "OTP sent to your email!");
//       // Store OTP in user data for comparison during verification (temporary solution)
//       // In practice, you should store this in a secure way
//       await _firestore.collection('users').doc(email).update({'otp': otp});

//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }






















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//     Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password' : password,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   Future<void> updateUserProfile({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//     required String citizenshipNumber,
//     required String profilePhotoUrl,
//     required String frontCitizenshipUrl,
//     required String backCitizenshipUrl,
//   }) async {
//     try {
//       String uid = _auth.currentUser!.uid;
//       await _firestore.collection('users').doc(uid).update({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password,
//         'citizenship_number': citizenshipNumber,
//         'profile_photo_url': profilePhotoUrl,
//         'front_citizenship_url': frontCitizenshipUrl,
//         'back_citizenship_url': backCitizenshipUrl,
//       });
//       Get.snackbar("Success", "Profile updated successfully!");
//     } catch (e) {
//       Get.snackbar("Error", "Failed to update profile: ${e.toString()}");
//     }
//   }


//   // Check if email exists in Firebase
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Ideally, you would send this OTP via a backend service or Firebase function.
//       await _auth.sendPasswordResetEmail(email: email);
      
//       Get.snackbar("Success", "OTP sent to your email!");
//       // Store OTP in user data for comparison during verification (temporary solution)
//       // In practice, you should store this in a secure way
//       await _firestore.collection('users').doc(email).update({'otp': otp});

//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }





























// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   FirebaseAuth get auth => _auth;

//   /// Register a new user
//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       // Create user with Firebase Authentication
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       // Save user data to Firestore
//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//         // Placeholder fields for profile setup
//         'profile_image': null,
//         'front_citizenship_image': null,
//         'back_citizenship_image': null,
//         'citizenship_number': null,
//         'profile_completed_at': null,
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   /// Check if an email is already registered
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   /// Send OTP to email (with dummy implementation for demonstration)
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Ideally, use a backend or service for sending OTP
//       await _auth.sendPasswordResetEmail(email: email);

//       Get.snackbar("Success", "OTP sent to your email!");
//       // Temporarily store OTP in Firestore (for demo purposes)
//       await _firestore.collection('users').doc(email).update({'otp': otp});
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   /// Generate a random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   /// Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   /// Login user with username and password
//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }

//   /// Update user profile after profile setup
//   Future<void> updateUserProfile({
//     required String userId,
//     required String profileImageUrl,
//     required String frontCitizenshipUrl,
//     required String backCitizenshipUrl,
//     required String citizenshipNumber,
//   }) async {
//     try {
//       await _firestore.collection('users').doc(userId).update({
//         'profile_image': profileImageUrl,
//         'front_citizenship_image': frontCitizenshipUrl,
//         'back_citizenship_image': backCitizenshipUrl,
//         'citizenship_number': citizenshipNumber,
//         'profile_completed_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "Profile updated successfully!");
//     } catch (e) {
//       Get.snackbar("Error", "Failed to update profile: ${e.toString()}");
//     }
//   }
// }


































// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Register User
//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password, // Note: Avoid storing passwords as plaintext in production
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // Check if email is already registered
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to user's email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Simulate sending the OTP via email (use backend in production)
//       Get.snackbar("OTP Sent", "Your OTP is: $otp");

//       // Temporarily store OTP in Firestore
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (query.docs.isNotEmpty) {
//         String uid = query.docs.first.id;
//         await _firestore.collection('users').doc(uid).update({'otp': otp});
//       } else {
//         Get.snackbar("Error", "Email not registered!");
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate a random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String otp,
//     required String newPassword,
//   }) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "Email not found!");
//         return;
//       }

//       String storedOtp = query.docs.first.get('otp');
//       if (storedOtp != otp) {
//         Get.snackbar("Error", "Invalid OTP!");
//         return;
//       }

//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);

//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   // Login User
//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }

















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'dart:math';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   

//     Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password' : password,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

  

//   // Check if email exists in Firebase
//   Future<bool> checkEmailRegistered(String email) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       return query.docs.isNotEmpty;
//     } catch (e) {
//       Get.snackbar("Error", "Failed to check email: ${e.toString()}");
//       return false;
//     }
//   }

//   // Send OTP to email
//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       String otp = _generateOtp();
//       // Ideally, you would send this OTP via a backend service or Firebase function.
//       await _auth.sendPasswordResetEmail(email: email);
      
//       Get.snackbar("Success", "OTP sent to your email!");
//       // Store OTP in user data for comparison during verification (temporary solution)
//       // In practice, you should store this in a secure way
//       await _firestore.collection('users').doc(email).update({'otp': otp});

//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   // Generate random 6-digit OTP
//   String _generateOtp() {
//     Random random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Verify OTP and reset password
//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }









// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   Future<void> sendOtpToEmail(String email) async {
//     try {
//       // Example: Firebase backend function to send an OTP
//       await _auth.sendPasswordResetEmail(email: email);
//       Get.snackbar("Success", "OTP sent to your email!");
//       Get.toNamed('/otpVerification', arguments: {'email': email});
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
//     }
//   }

//   Future<void> verifyOtpAndResetPassword({
//     required String email,
//     required String newPassword,
//   }) async {
//     try {
//       User? user = _auth.currentUser;
//       await user?.updatePassword(newPassword);
//       Get.snackbar("Success", "Password updated successfully!");
//       Get.offAllNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
//     }
//   }

//   Future<bool> loginUser(String username, String password) async {
//     try {
//       QuerySnapshot query = await _firestore
//           .collection('users')
//           .where('username', isEqualTo: username)
//           .get();

//       if (query.docs.isEmpty) {
//         Get.snackbar("Error", "No user found with this username");
//         return false;
//       }

//       var userDoc = query.docs.first;
//       String email = userDoc['email'];

//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return true;
//     } catch (e) {
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }
// }














// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       // Register user in Firebase Authentication
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       String uid = userCredential.user!.uid; // Get unique user ID

//       // Save additional user data in Firestore
//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       // Show success message and navigate to the login screen
//       Get.snackbar("Success", "User registered successfully!",
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Get.theme.primaryColor,
//           colorText: Get.theme.colorScheme.onPrimary);

//       Get.toNamed('/login'); // Navigate to login screen
//     } catch (e) {
//       // Handle errors
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}",
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor:const Color.fromARGB(255, 255, 0, 0),
//           colorText: Get.theme.colorScheme.onError);
//     }
//   }
// }












// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       await _firestore.collection('users').doc(mobile).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password, // Encrypt this in production
//         'accepted_terms': true,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar(
//         "Success",
//         "User registered successfully!",
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: const Color(0xFF4CAF50),
//         colorText: Colors.white,
//       );

//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "Failed to register user: ${e.toString()}",
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: const Color.fromARGB(255, 255, 0, 0),
//         colorText: Colors.white,
//       );
//     }
//   }
// }











// import 'dart:async';
// import 'dart:developer';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   String userUid = '';
//   var verId = '';
//   int? resendTokenId;
//   String phoneNumber = '';
//   bool phoneAuthCheck = false;
//   dynamic credentials;
//   Timer? _timer;

//   phoneAuth(String phone) async {
//     try {
//       credentials = null;
//       phoneNumber = phone; // Set the phoneNumber here
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phone,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           log('Completed');
//           credentials = credential;
//           await FirebaseAuth.instance.signInWithCredential(credential);
//         },
//         forceResendingToken: resendTokenId,
//         verificationFailed: (FirebaseAuthException e) {
//           log('Failed');
//           if (e.code == 'invalid-phone-number') {
//             debugPrint('The provided phone number is not valid.');
//             Get.snackbar("Error", "The provided phone number is not valid.");
//           } else if (e.code == 'BILLING_NOT_ENABLED') {
//             debugPrint('Billing is not enabled for this project.');
//             Get.snackbar("Error", "Billing is not enabled for this project.");
//           } else {
//             debugPrint('Verification failed. Error: ${e.message}');
//             Get.snackbar("Error", "Verification failed: ${e.message}");
//           }
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           log('Code sent');
//           verId = verificationId;
//           resendTokenId = resendToken;
//           _startResendTimer();
//           Get.snackbar("OTP Sent", "OTP has been sent successfully.");
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//       );
//     } catch (e) {
//       log("Error occurred: $e");
//       Get.snackbar("Error", "Failed to send OTP. Please try again.");
//     }
//   }

//   _startResendTimer() {
//     _timer?.cancel();
//     _timer = Timer(const Duration(seconds: 90), () {
//       phoneAuth(phoneNumber);
//     });
//   }

//   Future<bool> verifyOtp(String otpNumber) async {
//     log("Verifying OTP...");
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: verId,
//       smsCode: otpNumber,
//     );

//     try {
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       log("Logged in successfully");
//       return true; // OTP verified successfully
//     } catch (e) {
//       log("OTP Verification failed: $e");
//       Get.snackbar("Error", "Invalid OTP or verification failed. Please try again.");
//       return false; // OTP verification failed
//     }
//   }
// }


































// import 'dart:async';
// import 'dart:developer';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   String userUid = '';
//   var verId = '';
//   int? resendTokenId;
//   String phoneNumber = '';
//   bool phoneAuthCheck = false;
//   dynamic credentials;
//   Timer? _timer;

//   phoneAuth(String phone) async {
//     try {
//       credentials = null;
//       phoneNumber = phone; // Set the phoneNumber here
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phone,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           log('Completed');
//           credentials = credential;
//           await FirebaseAuth.instance.signInWithCredential(credential);
//         },
//         forceResendingToken: resendTokenId,
//         verificationFailed: (FirebaseAuthException e) {
//           log('Failed');
//           if (e.code == 'invalid-phone-number') {
//             debugPrint('The provided phone number is not valid.');
//             Get.snackbar("Error", "The provided phone number is not valid.");
//           } else if (e.code == 'BILLING_NOT_ENABLED') {
//             debugPrint('Billing is not enabled for this project.');
//             Get.snackbar("Error", "Billing is not enabled for this project.");
//           } else {
//             debugPrint('Verification failed. Error: ${e.message}');
//             Get.snackbar("Error", "Verification failed: ${e.message}");
//           }
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           log('Code sent');
//           verId = verificationId;
//           resendTokenId = resendToken;
//           _startResendTimer();
//           Get.snackbar("OTP Sent", "OTP has been sent successfully.");
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//       );
//     } catch (e) {
//       log("Error occurred: $e");
//       Get.snackbar("Error", "Failed to send OTP. Please try again.");
//     }
//   }

//   _startResendTimer() {
//     _timer?.cancel();
//     _timer = Timer(const Duration(seconds: 45), () {
//       phoneAuth(phoneNumber);
//     });
//   }

//   verifyOtp(String otpNumber) async {
//     log("Verifying OTP...");
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: verId,
//       smsCode: otpNumber,
//     );

//     try {
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       log("Logged in successfully");
//     } catch (e) {
//       log("OTP Verification failed: $e");
//       Get.snackbar("Error", "Invalid OTP or verification failed. Please try again.");
//     }
//   }
// }




























































// import 'dart:async';
// import 'dart:developer';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController {
//   String userUid = '';
//   var verId = '';
//   int? resendTokenId;
//   String phoneNumber = '';
//   bool phoneAuthCheck = false;
//   dynamic credentials;
//   Timer? _timer;

//   phoneAuth(String phone) async {
//     try {
//       credentials = null;
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phone,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           log('Completed');
//           credentials = credential;
//           await FirebaseAuth.instance.signInWithCredential(credential);
//         },
//         forceResendingToken: resendTokenId,
//         verificationFailed: (FirebaseAuthException e) {
//           log('Failed');
//           if (e.code == 'invalid-phone-number') {
//             debugPrint('The provided phone number is not valid.');
//           } else if (e.code == 'BILLING_NOT_ENABLED') {
//             debugPrint('Billing is not enabled for this project.');
//           } else {
//             debugPrint('Verification failed. Error: ${e.message}');
//           }
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           log('Code sent');
//           verId = verificationId;
//           resendTokenId = resendToken;
//           _startResendTimer();
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//       );
//     } catch (e) {
//       log("Error occurred: $e");
//     }
//   }

//   _startResendTimer() {
//     _timer?.cancel();
//     _timer = Timer(const Duration(seconds: 45), () {
//       phoneAuth(phoneNumber);
//     });
//   }

//   verifyOtp(String otpNumber) async {
//     log("Verifying OTP...");
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: verId,
//       smsCode: otpNumber,
//     );

//     try {
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       log("Logged in successfully");
//     } catch (e) {
//       log("OTP Verification failed: $e");
//       Get.snackbar("Error", "Invalid OTP or verification failed. Please try again.");
//     }
//   }
// }



































































































// import 'dart:developer';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AuthController extends GetxController{

//   String userUid = '';
//   var verId = '';
//   int? resendTokenId;
//   bool phoneAuthCheck = false;
//   dynamic credentials;


//   phoneAuth(String phone) async {
//     try {
//       credentials = null;
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phone,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           log('Completed');
//           credentials = credential;
//           await FirebaseAuth.instance.signInWithCredential(credential);
//         },
//         forceResendingToken: resendTokenId,
//         verificationFailed: (FirebaseAuthException e) {
//           log('Failed');
//           if (e.code == 'invalid-phone-number') {
//             debugPrint('The provided phone number is not valid.');
//           }
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           log('Code sent');
//           verId = verificationId;
//           resendTokenId = resendToken;
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//       );
//     } catch (e) {
//       log("Error occured $e");
//     }
//   }

//    verifyOtp(String otpNumber) async {
//     log("Called");
//     PhoneAuthCredential credential =
//         PhoneAuthProvider.credential(verificationId: verId, smsCode: otpNumber);

//     log("LogedIn");

//     await FirebaseAuth.instance.signInWithCredential(credential);
//       }
// }