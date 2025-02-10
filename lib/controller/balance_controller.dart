// First, create a new file: lib/controllers/balance_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Rx<double> balance = 0.0.obs;

  Future<void> updateBalance(double amount) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "User not authenticated";

      // Get current balance
      DocumentSnapshot<Map<String, dynamic>> userDoc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) throw "User document not found";
      
      double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
      double newBalance = currentBalance + amount;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'balance': newBalance,
      });

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

      DocumentSnapshot<Map<String, dynamic>> userDoc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) throw "User document not found";
      
      balance.value = (userDoc.data()?['balance'] ?? 0.0).toDouble();
    } catch (e) {
      print("Error loading balance: $e");
    }
  }
}

