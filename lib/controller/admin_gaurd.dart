import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminGuard extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<bool> isAdmin() async {
  try {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No current user found');
      return false;
    }

    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    bool isAdmin = userDoc.exists && 
        (userDoc.data() as Map<String, dynamic>)['isAdmin'] == true;
    
    print('Admin check result: $isAdmin for user ${currentUser.uid}');
    return isAdmin;
  } catch (e) {
    print('Error checking admin status: $e');
    return false;
  }
}

  // Middleware to protect admin routes
  Future<bool> protectAdminRoute() async {
    bool isUserAdmin = await isAdmin();
    if (!isUserAdmin) {
      Get.snackbar('Access Denied', 'You need admin privileges to access this section');
      Get.offAllNamed('/home'); // Redirect to home page
      return false;
    }
    return true;
  }
}










// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:get/get.dart';

// class AdminGuard extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<bool> isAdmin() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         print("AdminGuard: No current user"); // Debug print
//         return false;
//       }

//       print("AdminGuard: Checking user ${currentUser.uid}"); // Debug print

//       DocumentSnapshot userDoc = await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();

//       bool isAdmin = userDoc.exists && 
//           (userDoc.data() as Map<String, dynamic>)['isAdmin'] == true;
      
//       print("AdminGuard: isAdmin = $isAdmin"); // Debug print
//       return isAdmin;
//     } catch (e) {
//       print("AdminGuard error: $e"); // Debug print
//       return false;
//     }
//   }
// }

















// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// class AdminGuard extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<bool> isAdmin() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) return false;

//       DocumentSnapshot userDoc = await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();
      

//       return userDoc.exists && (userDoc.data() as Map<String, dynamic>)['isAdmin'] == true;
//     } catch (e) {
//       print('Error checking admin status: $e');
//       return false;
//     }
//   }

//   // Middleware to protect admin routes
//   Future<bool> protectAdminRoute() async {
//     bool isUserAdmin = await isAdmin();
//     if (!isUserAdmin) {
//       Get.snackbar('Access Denied', 'You need admin privileges to access this section');
//       Get.offAllNamed('/home'); // Redirect to home page
//       return false;
//     }
//     return true;
//   }
// }