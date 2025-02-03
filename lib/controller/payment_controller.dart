// lib/controller/PaymentController.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:major_project/utils/esewa_api.dart'; // Our updated eSewa API utility

class PaymentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Processes the payment via eSewa and logs the transaction in Firestore.
  /// 
  /// Parameters:
  /// - [userId]: The ID of the passenger.
  /// - [rfidCardId]: The RFID card used.
  /// - [busOperatorId]: The identifier of the bus operator.
  /// - [entryTime]: The time when the passenger tapped in.
  /// - [exitTime]: The time when the passenger tapped out.
  /// - [entryLocation]: A map with 'latitude' and 'longitude' of the boarding location.
  /// - [exitLocation]: A map with 'latitude' and 'longitude' of the exit location.
  /// - [distance]: The calculated distance traveled.
  /// - [fare]: The computed fare amount.
  ///
  /// Returns a [bool] indicating whether the payment was successful.
  Future<bool> processPayment({
    required String userId,
    required String rfidCardId,
    required String busOperatorId,
    required DateTime entryTime,
    required DateTime exitTime,
    required Map<String, double> entryLocation, // e.g., {'latitude': 27.7000, 'longitude': 85.3333}
    required Map<String, double> exitLocation,  // e.g., {'latitude': 27.7089, 'longitude': 85.3200}
    required double distance,
    required double fare,
  }) async {
    try {
      // Initiate payment via the eSewa API using our direct Epay-v2 integration.
      final paymentResponse = await EsewaApi.processPayment(
        userId: userId,
        amount: fare,
        busOperatorId: busOperatorId,
      );

      // Extract status and reference from the API response.
      String paymentStatus = paymentResponse['status']; // Expected "success" or "failed"
      String esewaReference = paymentResponse['reference'] ?? '';

      // Log the transaction to Firestore.
      await _logTransaction(
        userId: userId,
        rfidCardId: rfidCardId,
        busOperatorId: busOperatorId,
        entryTime: entryTime,
        exitTime: exitTime,
        entryLocation: entryLocation,
        exitLocation: exitLocation,
        distance: distance,
        fare: fare,
        paymentStatus: paymentStatus,
        esewaReference: esewaReference,
      );

      // Return true if payment was successful; otherwise, false.
      return paymentStatus == 'success';
    } catch (e) {
      // In case of an error, log the transaction as failed.
      await _logTransaction(
        userId: userId,
        rfidCardId: rfidCardId,
        busOperatorId: busOperatorId,
        entryTime: entryTime,
        exitTime: exitTime,
        entryLocation: entryLocation,
        exitLocation: exitLocation,
        distance: distance,
        fare: fare,
        paymentStatus: 'failed',
        esewaReference: '',
      );
      Get.snackbar("Payment Error", "Payment processing failed: ${e.toString()}");
      return false;
    }
  }

  /// Private helper method that logs a transaction document in the Firestore 'transactions' collection.
  Future<void> _logTransaction({
    required String userId,
    required String rfidCardId,
    required String busOperatorId,
    required DateTime entryTime,
    required DateTime exitTime,
    required Map<String, double> entryLocation,
    required Map<String, double> exitLocation,
    required double distance,
    required double fare,
    required String paymentStatus,
    required String esewaReference,
  }) async {
    try {
      await _firestore.collection('transactions').add({
        'userId': userId,
        'rfidCardId': rfidCardId,
        'busOperatorId': busOperatorId,
        'entryTime': entryTime,
        'exitTime': exitTime,
        'entryLocation': entryLocation,
        'exitLocation': exitLocation,
        'distance': distance,
        'fare': fare,
        'paymentStatus': paymentStatus,
        'esewaReference': esewaReference,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar("Logging Error", "Failed to log transaction: ${e.toString()}");
    }
  }
}
