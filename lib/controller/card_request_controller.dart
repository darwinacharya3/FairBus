import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CardRequestController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString cardStatus = 'none'.obs; // none, requested, active
  final RxBool isVerified = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      cardStatus.value = userData['cardStatus'] ?? 'none';
      isVerified.value = userData['isVerified'] ?? false;
    } catch (e) {
      print('Error loading user status: $e');
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

      await _firestore.collection('users').doc(uid).update({
        'cardStatus': 'requested',
        'cardRequestDate': FieldValue.serverTimestamp(),
      });

      cardStatus.value = 'requested';
      Get.snackbar('Success', 'Card request submitted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to request card: $e');
    }
  }
}
