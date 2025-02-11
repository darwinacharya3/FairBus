import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BalanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  
  final Rx<double> balance = 0.0.obs;

  Future<void> updateBalance(double amount) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "User not authenticated";

      // Get current balance from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) throw "User document not found";
      
      double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
      double newBalance = currentBalance + amount;

      // Update both databases in parallel
      await Future.wait([
        // Update Firestore
        _firestore.collection('users').doc(user.uid).update({
          'balance': newBalance,
        }),
        
        // Update Realtime Database
        _rtdb.ref().child('users').child(user.uid).update({
          'balance': newBalance,
        })
      ]);

      // Update local state
      balance.value = newBalance;
      
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update balance: $e",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  Future<void> loadBalance() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "User not authenticated";

      // Load from both databases in parallel
      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(),
        _rtdb.ref().child('users').child(user.uid).get()
      ]);

      DocumentSnapshot<Map<String, dynamic>> firestoreDoc = 
          results[0] as DocumentSnapshot<Map<String, dynamic>>;
      DataSnapshot rtdbDoc = results[1] as DataSnapshot;
      
      if (!firestoreDoc.exists) throw "User document not found in Firestore";
      
      // Get balances from both databases
      double firestoreBalance = (firestoreDoc.data()?['balance'] ?? 0.0).toDouble();
      double rtdbBalance = (rtdbDoc.value != null && (rtdbDoc.value as Map).containsKey('balance')) 
          ? (rtdbDoc.value as Map)['balance'].toDouble() 
          : 0.0;
      
      // Use Firestore balance as source of truth, but log if there's a mismatch
      if (firestoreBalance != rtdbBalance) {
        print("Balance mismatch detected: Firestore=$firestoreBalance, RTDB=$rtdbBalance");
        // Sync RTDB with Firestore
        await _rtdb.ref().child('users').child(user.uid).update({
          'balance': firestoreBalance,
        });
      }
      
      balance.value = firestoreBalance;
      
    } catch (e) {
      print("Error loading balance: $e");
      // Attempt to load from RTDB as fallback
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          final rtdbSnapshot = await _rtdb.ref().child('users').child(user.uid).get();
          if (rtdbSnapshot.exists) {
            balance.value = (rtdbSnapshot.value as Map)['balance']?.toDouble() ?? 0.0;
          }
        }
      } catch (fallbackError) {
        print("Error in fallback balance loading: $fallbackError");
      }
    }
  }
}








// // First, create a new file: lib/controllers/balance_controller.dart
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class BalanceController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   final Rx<double> balance = 0.0.obs;

//   Future<void> updateBalance(double amount) async {
//     try {
//       User? user = _auth.currentUser;
//       if (user == null) throw "User not authenticated";

//       // Get current balance
//       DocumentSnapshot<Map<String, dynamic>> userDoc = 
//           await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) throw "User document not found";
      
//       double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
//       double newBalance = currentBalance + amount;

//       // Update Firestore
//       await _firestore.collection('users').doc(user.uid).update({
//         'balance': newBalance,
//       });

//       // Update local state
//       balance.value = newBalance;
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "Failed to update balance: $e",
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[900],
//       );
//     }
//   }

//   Future<void> loadBalance() async {
//     try {
//       User? user = _auth.currentUser;
//       if (user == null) throw "User not authenticated";

//       DocumentSnapshot<Map<String, dynamic>> userDoc = 
//           await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) throw "User document not found";
      
//       balance.value = (userDoc.data()?['balance'] ?? 0.0).toDouble();
//     } catch (e) {
//       print("Error loading balance: $e");
//     }
//   }
// }

