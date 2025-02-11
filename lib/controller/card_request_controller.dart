import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class CardRequestController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  final RxString cardStatus = 'none'.obs; // none, requested, active
  final RxBool isVerified = false.obs;
  final RxString assignedCardId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      // Load from both databases in parallel
      final results = await Future.wait([
        _firestore.collection('users').doc(uid).get(),
        _rtdb.ref().child('users').child(uid).get()
      ]);

      DocumentSnapshot firestoreDoc = results[0] as DocumentSnapshot;
      DataSnapshot rtdbDoc = results[1] as DataSnapshot;

      Map<String, dynamic> firestoreData = firestoreDoc.data() as Map<String, dynamic>;
      
      // Update local state from Firestore (source of truth)
      cardStatus.value = firestoreData['cardStatus'] ?? 'none';
      isVerified.value = firestoreData['isVerified'] ?? false;
      assignedCardId.value = firestoreData['assignedCardId'] ?? '';

      // If RTDB data doesn't match Firestore, sync it
      if (rtdbDoc.exists) {
        Map rtdbData = rtdbDoc.value as Map;
        if (rtdbData['cardStatus'] != cardStatus.value || 
            rtdbData['assignedCardId'] != assignedCardId.value) {
          await _rtdb.ref().child('users').child(uid).update({
            'cardStatus': cardStatus.value,
            'assignedCardId': assignedCardId.value,
          });
        }
      } else {
        // Create RTDB entry if it doesn't exist
        await _rtdb.ref().child('users').child(uid).update({
          'cardStatus': cardStatus.value,
          'assignedCardId': assignedCardId.value,
        });
      }
    } catch (e) {
      print('Error loading user status: $e');
      // Attempt to load from RTDB as fallback
      try {
        String uid = _auth.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          final rtdbSnapshot = await _rtdb.ref().child('users').child(uid).get();
          if (rtdbSnapshot.exists) {
            Map rtdbData = rtdbSnapshot.value as Map;
            cardStatus.value = rtdbData['cardStatus'] ?? 'none';
            assignedCardId.value = rtdbData['assignedCardId'] ?? '';
          }
        }
      } catch (fallbackError) {
        print('Error in fallback status loading: $fallbackError');
      }
    }
  }

  Future<void> requestCard() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        Get.snackbar('Error', 'User not logged in');
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (!userData['isVerified']) {
        Get.snackbar('Error', 'Please wait for profile verification before requesting a card');
        return;
      }

      if (userData['cardStatus'] == 'requested') {
        Get.snackbar('Info', 'Card request already pending');
        return;
      }

      if (userData['cardStatus'] == 'active') {
        Get.snackbar('Info', 'Card already assigned');
        return;
      }

      // Update both databases in parallel
      await Future.wait([
        // Update Firestore
        _firestore.collection('users').doc(uid).update({
          'cardStatus': 'requested',
          'cardRequestDate': FieldValue.serverTimestamp(),
        }),
        
        // Update Realtime Database
        _rtdb.ref().child('users').child(uid).update({
          'cardStatus': 'requested',
          'cardRequestDate': ServerValue.timestamp,
        })
      ]);

      cardStatus.value = 'requested';
      Get.snackbar('Success', 'Card request submitted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to request card: $e');
    }
  }

  // Method to update assigned card ID (typically called by admin or system)
  Future<void> updateAssignedCard(String cardId) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        throw 'User not logged in';
      }

      // Update both databases in parallel
      await Future.wait([
        // Update Firestore
        _firestore.collection('users').doc(uid).update({
          'assignedCardId': cardId,
          'cardStatus': 'active',
          'cardAssignedDate': FieldValue.serverTimestamp(),
        }),
        
        // Update Realtime Database
        _rtdb.ref().child('users').child(uid).update({
          'assignedCardId': cardId,
          'cardStatus': 'active',
          'cardAssignedDate': ServerValue.timestamp,
        })
      ]);

      // Update local state
      assignedCardId.value = cardId;
      cardStatus.value = 'active';
      
      Get.snackbar('Success', 'Card assigned successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update assigned card: $e');
    }
  }
}








// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';

// class CardRequestController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final RxString cardStatus = 'none'.obs; // none, requested, active
//   final RxBool isVerified = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _loadUserStatus();
//   }

//   Future<void> _loadUserStatus() async {
//     try {
//       String uid = _auth.currentUser?.uid ?? '';
//       if (uid.isEmpty) return;

//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
//       cardStatus.value = userData['cardStatus'] ?? 'none';
//       isVerified.value = userData['isVerified'] ?? false;
//     } catch (e) {
//       print('Error loading user status: $e');
//     }
//   }

//   Future<void> requestCard() async {
//     try {
//       String uid = _auth.currentUser?.uid ?? '';
//       if (uid.isEmpty) {
//         Get.snackbar('Error', 'User not logged in');
//         return;
//       }

//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       if (!userData['isVerified']) {
//         Get.snackbar('Error', 'Please wait for profile verification before requesting a card');
//         return;
//       }

//       if (userData['cardStatus'] == 'requested') {
//         Get.snackbar('Info', 'Card request already pending');
//         return;
//       }

//       if (userData['cardStatus'] == 'active') {
//         Get.snackbar('Info', 'Card already assigned');
//         return;
//       }

//       await _firestore.collection('users').doc(uid).update({
//         'cardStatus': 'requested',
//         'cardRequestDate': FieldValue.serverTimestamp(),
//       });

//       cardStatus.value = 'requested';
//       Get.snackbar('Success', 'Card request submitted successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to request card: $e');
//     }
//   }
// }
