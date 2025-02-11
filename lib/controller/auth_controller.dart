import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:major_project/controller/admin_gaurd.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDB = FirebaseDatabase.instance;

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

      // Create user data map
      Map<String, dynamic> userData = {
        'name': name,
        'mobile': mobile,
        'email': email,
        'username': username,
        'password': password,
        'accepted_terms': true,
        'isVerified': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Store in Firestore with Firestore-specific timestamp
      await _firestore.collection('users').doc(uid).set({
        ...userData,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Store in Realtime Database
      await _realtimeDB.ref().child('users').child(uid).set(userData);

      Get.snackbar("Success", "User registered successfully!");
      Get.toNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Failed to register user: ${e.toString()}");
    }
  }

  Future<void> updateUserAfterRide(String uid, double fare, double distance) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(uid).update({
        'balance': FieldValue.increment(-fare),
        'distance': FieldValue.increment(distance),
        'isOnBus': false,
      });

      // Get current values from Realtime DB for calculation
      DatabaseEvent event = await _realtimeDB.ref().child('users').child(uid).once();
      Map<dynamic, dynamic> userData = (event.snapshot.value as Map<dynamic, dynamic>?) ?? {};
      
      double currentBalance = (userData['balance'] ?? 0.0).toDouble();
      double currentDistance = (userData['distance'] ?? 0.0).toDouble();

      // Update Realtime Database
      await _realtimeDB.ref().child('users').child(uid).update({
        'balance': currentBalance - fare,
        'distance': currentDistance + distance,
        'isOnBus': false,
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to update ride data: ${e.toString()}");
    }
  }

  Future<bool> checkEmailRegistered(String email) async {
    try {
      // Check in Firestore
      QuerySnapshot firestoreQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Check in Realtime Database
      DatabaseEvent realtimeDBEvent = await _realtimeDB
          .ref()
          .child('users')
          .orderByChild('email')
          .equalTo(email)
          .once();

      return firestoreQuery.docs.isNotEmpty || 
             (realtimeDBEvent.snapshot.value != null);
    } catch (e) {
      Get.snackbar("Error", "Failed to check email: ${e.toString()}");
      return false;
    }
  }

  Future<void> sendOtpToEmail(String email) async {
    try {
      String otp = _generateOtp();
      await _auth.sendPasswordResetEmail(email: email);

      // Store OTP in both databases
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        String uid = query.docs.first.id;
        
        // Update Firestore
        await _firestore.collection('users').doc(uid).update({'otp': otp});
        
        // Update Realtime Database
        await _realtimeDB.ref().child('users').child(uid).update({'otp': otp});
      }

      Get.snackbar("Success", "OTP sent to your email!");
    } catch (e) {
      Get.snackbar("Error", "Failed to send OTP: ${e.toString()}");
    }
  }

  String _generateOtp() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      await user?.updatePassword(newPassword);

      // Update password in both databases
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        String uid = query.docs.first.id;
        
        // Update Firestore
        await _firestore.collection('users').doc(uid).update({
          'password': newPassword,
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update Realtime Database
        await _realtimeDB.ref().child('users').child(uid).update({
          'password': newPassword,
          'passwordUpdatedAt': DateTime.now().toIso8601String(),
        });
      }

      Get.snackbar("Success", "Password updated successfully!");
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Failed to reset password: ${e.toString()}");
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      // First try Firestore
      QuerySnapshot firestoreQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // If not found in Firestore, try Realtime Database
      String? email;
      if (firestoreQuery.docs.isEmpty) {
        DatabaseEvent realtimeDBEvent = await _realtimeDB
            .ref()
            .child('users')
            .orderByChild('username')
            .equalTo(username)
            .once();

        if (realtimeDBEvent.snapshot.value != null) {
          Map<dynamic, dynamic> userData = 
              (realtimeDBEvent.snapshot.value as Map<dynamic, dynamic>).values.first;
          email = userData['email'];
        }
      } else {
        email = firestoreQuery.docs.first['email'];
      }

      if (email == null) {
        Get.snackbar("Error", "No user found with this username");
        return false;
      }

      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      String uid = userCredential.user!.uid;

      // Fetch user data from both databases
      DocumentSnapshot firestoreUser = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      DatabaseEvent realtimeDBEvent = await _realtimeDB
          .ref()
          .child('users')
          .child(uid)
          .once();

      if (!firestoreUser.exists && realtimeDBEvent.snapshot.value == null) {
        Get.snackbar("Error", "User data not found");
        return false;
      }

      // Prefer Firestore data, fall back to Realtime DB
      Map<String, dynamic> userData;
      if (firestoreUser.exists) {
        userData = firestoreUser.data() as Map<String, dynamic>;
      } else {
        userData = Map<String, dynamic>.from(
          realtimeDBEvent.snapshot.value as Map<dynamic, dynamic>
        );
      }

      // Check admin status
      bool isAdminUser = userData['isAdmin'] == true;
      isAdmin.value = isAdminUser;

      if (isAdminUser) {
        bool adminVerified = await Get.find<AdminGuard>().isAdmin();
        if (!adminVerified) {
          Get.snackbar("Error", "Admin verification failed");
          await _auth.signOut();
          return false;
        }
        await Get.offAllNamed('/admin/dashboard');
      } else {
        await Get.offAllNamed('/home');
      }

      // Sync data between databases if needed
      await syncUserData(uid);
      
      return true;
    } catch (e) {
      Get.snackbar("Error", "Login failed: ${e.toString()}");
      return false;
    }
  }

  Future<bool> isUserVerified(String userId) async {
    try {
      // Check Firestore
      DocumentSnapshot firestoreDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      // Check Realtime Database
      DatabaseEvent realtimeDBEvent = await _realtimeDB
          .ref()
          .child('users')
          .child(userId)
          .once();

      bool firestoreVerified = firestoreDoc.exists && 
          (firestoreDoc.data() as Map<String, dynamic>)['isVerified'] == true;
      
      bool realtimeDBVerified = false;
      if (realtimeDBEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData = 
            realtimeDBEvent.snapshot.value as Map<dynamic, dynamic>;
        realtimeDBVerified = userData['isVerified'] == true;
      }

      return firestoreVerified || realtimeDBVerified;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkAdminStatus() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check Firestore
      DocumentSnapshot firestoreDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Check Realtime Database
      DatabaseEvent realtimeDBEvent = await _realtimeDB
          .ref()
          .child('users')
          .child(currentUser.uid)
          .once();

      bool isAdminUser = false;

      if (firestoreDoc.exists) {
        isAdminUser = (firestoreDoc.data() as Map<String, dynamic>)['isAdmin'] == true;
      } else if (realtimeDBEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData = 
            realtimeDBEvent.snapshot.value as Map<dynamic, dynamic>;
        isAdminUser = userData['isAdmin'] == true;
      }

      isAdmin.value = isAdminUser;
      return isAdminUser;
    } catch (e) {
      return false;
    }
  }

  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Failed to logout: ${e.toString()}");
    }
  }

  Future<void> syncUserData(String uid) async {
    try {
      // Get data from both databases
      DocumentSnapshot firestoreDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      DatabaseEvent realtimeDBEvent = await _realtimeDB
          .ref()
          .child('users')
          .child(uid)
          .once();

      // If data exists in Firestore but not in Realtime DB
      if (firestoreDoc.exists && realtimeDBEvent.snapshot.value == null) {
        Map<String, dynamic> firestoreData = 
            firestoreDoc.data() as Map<String, dynamic>;
        await _realtimeDB.ref().child('users').child(uid).set(firestoreData);
      }
      // If data exists in Realtime DB but not in Firestore
      else if (!firestoreDoc.exists && realtimeDBEvent.snapshot.value != null) {
        Map<dynamic, dynamic> realtimeData = 
            realtimeDBEvent.snapshot.value as Map<dynamic, dynamic>;
        await _firestore.collection('users').doc(uid).set(
          Map<String, dynamic>.from(realtimeData)
        );
      }
    } catch (e) {
      print("Error syncing user data: $e");
    }
  }
}














// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart'; 
// import 'package:get/get.dart';
// import 'dart:math';
// import 'package:major_project/controller/admin_gaurd.dart';

// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

//   // Add RxBool for tracking admin status
//   final RxBool isAdmin = false.obs;

//   Future<void> registerUser({
//     required String name,
//     required String mobile,
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       String uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'name': name,
//         'mobile': mobile,
//         'email': email,
//         'username': username,
//         'password': password,
//         'accepted_terms': true,
//         // 'balance': 0.00, // NEW: Initial balance
//         'isVerified': false, // NEW: Verification status
//         'created_at': FieldValue.serverTimestamp(),
//       });
      

//       Get.snackbar("Success", "User registered successfully!");
//       Get.toNamed('/login');
//     } catch (e) {
//       Get.snackbar("Error", "Failed to register user: ${e.toString()}");
//     }
//   }

//   // NEW: Add method to update fare/distance after ride
//   Future<void> updateUserAfterRide(
//       String uid, double fare, double distance) async {
//     try {
//       await _firestore.collection('users').doc(uid).update({
//         'balance': FieldValue.increment(-fare),
//         'distance': FieldValue.increment(distance),
//         'isOnBus': false,
//       });
//     } catch (e) {
//       Get.snackbar("Error", "Failed to update ride data: ${e.toString()}");
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
//       // First get the user document by username
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

//       // Sign in with Firebase Auth
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: email, password: password);

//       // Important: After login, fetch the complete user document using the UID
//       DocumentSnapshot userSnapshot = await _firestore
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .get();

//       if (!userSnapshot.exists) {
//         Get.snackbar("Error", "User document not found");
//         return false;
//       }

//       Map<String, dynamic> userData =
//           userSnapshot.data() as Map<String, dynamic>;

//       // Explicitly check for admin status
//       bool isAdminUser = userData['isAdmin'] == true; // Use strict comparison
//       isAdmin.value = isAdminUser;

//       // print("Login successful - Admin status: $isAdminUser"); // Debug print

//       // Store admin status in GetX state
//       if (isAdminUser) {
//         // print("Admin login detected - Verifying permissions");
//         bool adminVerified = await Get.find<AdminGuard>().isAdmin();

//         if (!adminVerified) {
//           Get.snackbar("Error", "Admin verification failed");
//           await _auth.signOut();
//           return false;
//         }

//         // print("Admin verification successful - Redirecting to admin panel");
//         // Change this line to match exact route name
//         await Get.offAllNamed('/admin/dashboard'); // Add await here
//       } else {
//         // print("Regular user login - Redirecting to home");
//         await Get.offAllNamed('/home'); // Add await here
//       }

//       return true;
//     } catch (e) {
//       // print("Login error: $e");
//       Get.snackbar("Error", "Login failed: ${e.toString()}");
//       return false;
//     }
//   }

//   // Add method to check verification status
//   Future<bool> isUserVerified(String userId) async {
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection('users').doc(userId).get();

//       return (doc.data() as Map<String, dynamic>)['isVerified'] ?? false;
//     } catch (e) {
//       // print("Error checking verification status: $e");
//       return false;
//     }
//   }

//   Future<bool> checkAdminStatus() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) return false;

//       DocumentSnapshot userDoc =
//           await _firestore.collection('users').doc(currentUser.uid).get();

//       bool isAdminUser = userDoc.exists &&
//           (userDoc.data() as Map<String, dynamic>)['isAdmin'] == true;

//       isAdmin.value = isAdminUser;
//       return isAdminUser;
//     } catch (e) {
//       // print("Error checking admin status: $e");
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



