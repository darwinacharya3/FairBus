import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:major_project/controller/admin_gaurd.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Add RxBool for tracking admin status
  final RxBool isAdmin = false.obs;

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
    // First get the user document by username
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
    
    // Sign in with Firebase Auth
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );

    // Important: After login, fetch the complete user document using the UID
    DocumentSnapshot userSnapshot = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    
    if (!userSnapshot.exists) {
      Get.snackbar("Error", "User document not found");
      return false;
    }

    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    
    // Explicitly check for admin status
    bool isAdminUser = userData['isAdmin'] == true; // Use strict comparison
    isAdmin.value = isAdminUser;

    print("Login successful - Admin status: $isAdminUser"); // Debug print

    // Store admin status in GetX state
   if (isAdminUser) {
  print("Admin login detected - Verifying permissions");
  bool adminVerified = await Get.find<AdminGuard>().isAdmin();
  
  if (!adminVerified) {
    Get.snackbar("Error", "Admin verification failed");
    await _auth.signOut();
    return false;
  }
  
  print("Admin verification successful - Redirecting to admin panel");
  // Change this line to match exact route name
  await Get.offAllNamed('/admin/users');  // Add await here
} else {
  print("Regular user login - Redirecting to home");
  await Get.offAllNamed('/home');  // Add await here
}

    return true;
  } catch (e) {
    print("Login error: $e");
    Get.snackbar("Error", "Login failed: ${e.toString()}");
    return false;
  }
}



  // Add method to check verification status
  Future<bool> isUserVerified(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return (doc.data() as Map<String, dynamic>)['isVerified'] ?? false;
    } catch (e) {
      print("Error checking verification status: $e");
      return false;
    }
  }

   Future<bool> checkAdminStatus() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      bool isAdminUser = userDoc.exists && 
          (userDoc.data() as Map<String, dynamic>)['isAdmin'] == true;
      
      isAdmin.value = isAdminUser;
      return isAdminUser;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }

 
  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login'); // Navigate to login screen
    } catch (e) {
      Get.snackbar("Error", "Failed to logout: ${e.toString()}");
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

//     // Add RxBool for tracking admin status
//   final RxBool isAdmin = false.obs;

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

//   Future<void> logoutUser() async {
//     try {
//       await _auth.signOut();
//       Get.offAllNamed('/login'); // Navigate to login screen
//     } catch (e) {
//       Get.snackbar("Error", "Failed to logout: ${e.toString()}");
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




