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




