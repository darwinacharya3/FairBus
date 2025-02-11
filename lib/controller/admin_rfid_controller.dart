import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:major_project/utils/rfid_card.dart';

class AdminRFIDController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final RxList<RFIDCard> rfidCards = <RFIDCard>[].obs;
  final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  late Stream<QuerySnapshot> _pendingRequestsStream;
  late Stream<QuerySnapshot> _rfidCardsStream;

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  void _setupStreams() {
    // Setup stream for pending requests
    _pendingRequestsStream = _firestore
        .collection('users')
        .where('cardStatus', isEqualTo: 'requested')
        .where('isVerified', isEqualTo: true)
        .snapshots();

    // Setup stream for RFID cards
    _rfidCardsStream = _firestore
        .collection('rfid_cards')
        .snapshots();

    // Listen to pending requests changes
    _pendingRequestsStream.listen((snapshot) {
      pendingRequests.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Convert Timestamp to DateTime if it exists
        if (data['cardRequestDate'] != null) {
          data['cardRequestDate'] = (data['cardRequestDate'] as Timestamp).toDate();
        }
        return {
          'uid': doc.id,
          ...data,
        };
      }).toList();
    });

    // Listen to RFID cards changes with user names
    _rfidCardsStream.listen((snapshot) async {
      final updatedCards = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          String? assignedUserName;
          
          // If card is assigned, fetch user's name
          if (data['assignedTo'] != null) {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(data['assignedTo'])
                  .get();
              assignedUserName = userDoc.data()?['name'];
            } catch (e) {
              print('Error fetching user name: $e');
            }
          }
          
          return RFIDCard.fromMap({
            ...data,
            'uid': doc.id,
            'assignedTo': assignedUserName ?? data['assignedTo'],
          });
        }),
      );
      
      rfidCards.value = updatedCards;
    });
  }

  List<RFIDCard> get availableCards =>
      rfidCards.where((card) => !card.isAssigned).toList();

  Future<void> addRFIDCard(String uid) async {
    try {
      // Add to Firestore
      await _firestore.collection('rfid_cards').doc(uid).set({
        'uid': uid,
        'isAssigned': false,
        'assignedTo': null,
        'assignedDate': null,
      });
      
      Get.snackbar('Success', 'RFID card added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add RFID card: $e');
    }
  }

  Future<void> assignCard(String userId, String cardId) async {
    try {
      final Timestamp now = Timestamp.now();
      final int rtdbTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      // First get the user's name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'];
      
      if (userName == null) {
        throw 'User name not found';
      }

      // Update Firestore in a transaction
      await _firestore.runTransaction((transaction) async {
        // Update user document
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'cardStatus': 'active',
            'assignedCardId': cardId,
            'cardAssignmentDate': now,
          },
        );

        // Update card document with both user ID and name
        transaction.update(
          _firestore.collection('rfid_cards').doc(cardId),
          {
            'isAssigned': true,
            'assignedTo': userId,  // Keep ID for reference
            'assignedToName': userName,  // Add name for display
            'assignedDate': now,
          },
        );
      });

      // Update Realtime Database
      await _rtdb.ref().child('users').child(userId).update({
        'cardStatus': 'active',
        'assignedCardId': cardId,
        'cardAssignmentDate': rtdbTimestamp,
        'assignedToName': userName,
      });

      Get.snackbar('Success', 'Card assigned to $userName successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign card: $e');
      
      // Attempt to rollback RTDB if Firestore transaction succeeded but RTDB failed
      try {
        await _rtdb.ref().child('users').child(userId).update({
          'cardStatus': 'requested',
          'assignedCardId': null,
          'cardAssignmentDate': null,
          'assignedToName': null,
        });
      } catch (rollbackError) {
        print('Error rolling back RTDB changes: $rollbackError');
      }
    }
  }
}












// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:major_project/utils/rfid_card.dart';

// class AdminRFIDController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final RxList<RFIDCard> rfidCards = <RFIDCard>[].obs;
//   final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
//   late Stream<QuerySnapshot> _pendingRequestsStream;
//   late Stream<QuerySnapshot> _rfidCardsStream;

//   @override
//   void onInit() {
//     super.onInit();
//     _setupStreams();
//   }

//   void _setupStreams() {
//     // Setup stream for pending requests
//     _pendingRequestsStream = _firestore
//         .collection('users')
//         .where('cardStatus', isEqualTo: 'requested')
//         .where('isVerified', isEqualTo: true)
//         .snapshots();

//     // Setup stream for RFID cards
//     _rfidCardsStream = _firestore
//         .collection('rfid_cards')
//         .snapshots();

//     // Listen to pending requests changes
//     _pendingRequestsStream.listen((snapshot) {
//       pendingRequests.value = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         // Convert Timestamp to DateTime if it exists
//         if (data['cardRequestDate'] != null) {
//           data['cardRequestDate'] = (data['cardRequestDate'] as Timestamp).toDate();
//         }
//         return {
//           'uid': doc.id,
//           ...data,
//         };
//       }).toList();
//     });

//     // Listen to RFID cards changes with user names
//     _rfidCardsStream.listen((snapshot) async {
//       final updatedCards = await Future.wait(
//         snapshot.docs.map((doc) async {
//           final data = doc.data() as Map<String, dynamic>;
//           String? assignedUserName;
          
//           // If card is assigned, fetch user's name
//           if (data['assignedTo'] != null) {
//             try {
//               final userDoc = await _firestore
//                   .collection('users')
//                   .doc(data['assignedTo'])
//                   .get();
//               assignedUserName = userDoc.data()?['name'];
//             } catch (e) {
//               print('Error fetching user name: $e');
//             }
//           }
          
//           return RFIDCard.fromMap({
//             ...data,
//             'uid': doc.id,
//             'assignedTo': assignedUserName ?? data['assignedTo'],
//           });
//         }),
//       );
      
//       rfidCards.value = updatedCards;
//     });
//   }

//   List<RFIDCard> get availableCards =>
//       rfidCards.where((card) => !card.isAssigned).toList();

//   Future<void> addRFIDCard(String uid) async {
//     try {
//       await _firestore.collection('rfid_cards').doc(uid).set({
//         'uid': uid,
//         'isAssigned': false,
//         'assignedTo': null,
//         'assignedDate': null,
//       });
      
//       Get.snackbar('Success', 'RFID card added successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to add RFID card: $e');
//     }
//   }

//   Future<void> assignCard(String userId, String cardId) async {
//     try {
//       final Timestamp now = Timestamp.now();
      
//       // First get the user's name
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final userName = userDoc.data()?['name'];
      
//       if (userName == null) {
//         throw 'User name not found';
//       }

//       await _firestore.runTransaction((transaction) async {
//         // Update user document
//         transaction.update(
//           _firestore.collection('users').doc(userId),
//           {
//             'cardStatus': 'active',
//             'assignedCardId': cardId,
//             'cardAssignmentDate': now,
//           },
//         );

//         // Update card document with both user ID and name
//         transaction.update(
//           _firestore.collection('rfid_cards').doc(cardId),
//           {
//             'isAssigned': true,
//             'assignedTo': userId,  // Keep ID for reference
//             'assignedToName': userName,  // Add name for display
//             'assignedDate': now,
//           },
//         );
//       });

//       Get.snackbar('Success', 'Card assigned to $userName successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to assign card: $e');
//     }
//   }

// }












// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:major_project/utils/rfid_card.dart';

// class AdminRFIDController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final RxList<RFIDCard> rfidCards = <RFIDCard>[].obs;
//   final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
//   late Stream<QuerySnapshot> _pendingRequestsStream;
//   late Stream<QuerySnapshot> _rfidCardsStream;

//   @override
//   void onInit() {
//     super.onInit();
//     _setupStreams();
//   }

//   void _setupStreams() {
//     // Setup stream for pending requests
//     _pendingRequestsStream = _firestore
//         .collection('users')
//         .where('cardStatus', isEqualTo: 'requested')
//         .where('isVerified', isEqualTo: true)
//         .snapshots();

//     // Setup stream for RFID cards
//     _rfidCardsStream = _firestore
//         .collection('rfid_cards')
//         .snapshots();

//     // Listen to pending requests changes
//     _pendingRequestsStream.listen((snapshot) {
//       pendingRequests.value = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         // Convert Timestamp to DateTime if it exists
//         if (data['cardRequestDate'] != null) {
//           data['cardRequestDate'] = (data['cardRequestDate'] as Timestamp).toDate();
//         }
//         return {
//           'uid': doc.id,
//           ...data,
//         };
//       }).toList();
//     });

//     // Listen to RFID cards changes
//     _rfidCardsStream.listen((snapshot) {
//       rfidCards.value = snapshot.docs
//           .map((doc) => RFIDCard.fromMap({...doc.data() as Map<String, dynamic>, 'uid': doc.id}))
//           .toList();
//     });
//   }

//   List<RFIDCard> get availableCards =>
//       rfidCards.where((card) => !card.isAssigned).toList();

//   Future<void> addRFIDCard(String uid) async {
//     try {
//       await _firestore.collection('rfid_cards').doc(uid).set({
//         'uid': uid,
//         'isAssigned': false,
//         'assignedTo': null,
//         'assignedDate': null,
//       });
      
//       Get.snackbar('Success', 'RFID card added successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to add RFID card: $e');
//     }
//   }

//   Future<void> assignCard(String userId, String cardId) async {
//     try {
//       final Timestamp now = Timestamp.now();
      
//       await _firestore.runTransaction((transaction) async {
//         // Update user document
//         transaction.update(
//           _firestore.collection('users').doc(userId),
//           {
//             'cardStatus': 'active',
//             'assignedCardId': cardId,
//             'cardAssignmentDate': now,
//           },
//         );

//         // Update card document
//         transaction.update(
//           _firestore.collection('rfid_cards').doc(cardId),
//           {
//             'isAssigned': true,
//             'assignedTo': userId,
//             'assignedDate': now,
//           },
//         );
//       });

//       Get.snackbar('Success', 'Card assigned successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to assign card: $e');
//     }
//   }

//   @override
//   void onClose() {
//     super.onClose();
//   }
// }

















// // import 'package:get/get.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:major_project/utils/rfid_card.dart';

// // class AdminRFIDController extends GetxController {
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   final RxList<RFIDCard> rfidCards = <RFIDCard>[].obs;
// //   final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;

// //   @override
// //   void onInit() {
// //     super.onInit();
// //     _loadRFIDCards();
// //     _loadPendingRequests();
// //   }

// //   Future<void> _loadRFIDCards() async {
// //     try {
// //       final snapshot = await _firestore.collection('rfid_cards').get();
// //       rfidCards.value = snapshot.docs
// //           .map((doc) => RFIDCard.fromMap({...doc.data(), 'uid': doc.id}))
// //           .toList();
// //     } catch (e) {
// //       print('Error loading RFID cards: $e');
// //     }
// //   }

// //   Future<void> _loadPendingRequests() async {
// //     try {
// //       final snapshot = await _firestore
// //           .collection('users')
// //           .where('cardStatus', isEqualTo: 'requested')
// //           .where('isVerified', isEqualTo: true)
// //           .get();

// //       pendingRequests.value = snapshot.docs.map((doc) {
// //         final data = doc.data();
// //         // Convert Timestamp to DateTime if it exists
// //         if (data['cardRequestDate'] != null) {
// //           data['cardRequestDate'] = (data['cardRequestDate'] as Timestamp).toDate();
// //         }
// //         return {
// //           'uid': doc.id,
// //           ...data,
// //         };
// //       }).toList();
// //     } catch (e) {
// //       print('Error loading pending requests: $e');
// //     }
// //   }

// //   List<RFIDCard> get availableCards =>
// //       rfidCards.where((card) => !card.isAssigned).toList();

// //   Future<void> addRFIDCard(String uid) async {
// //     try {
// //       // Use set() with the UID as document ID instead of add()
// //       await _firestore.collection('rfid_cards').doc(uid).set({
// //         'uid': uid,
// //         'isAssigned': false,
// //         'assignedTo': null,
// //         'assignedDate': null,
// //       });
      
// //       await _loadRFIDCards();
// //       Get.snackbar('Success', 'RFID card added successfully');
// //     } catch (e) {
// //       Get.snackbar('Error', 'Failed to add RFID card: $e');
// //     }
// //   }

// //   Future<void> assignCard(String userId, String cardId) async {
// //     try {
// //       final Timestamp now = Timestamp.now();
      
// //       await _firestore.runTransaction((transaction) async {
// //         // Update user document
// //         transaction.update(
// //           _firestore.collection('users').doc(userId),
// //           {
// //             'cardStatus': 'active',
// //             'assignedCardId': cardId,
// //             'cardAssignmentDate': now,
// //           },
// //         );

// //         // Update card document
// //         transaction.update(
// //           _firestore.collection('rfid_cards').doc(cardId),
// //           {
// //             'isAssigned': true,
// //             'assignedTo': userId,
// //             'assignedDate': now,
// //           },
// //         );
// //       });

// //       await _loadRFIDCards();
// //       await _loadPendingRequests();
// //       Get.snackbar('Success', 'Card assigned successfully');
// //     } catch (e) {
// //       Get.snackbar('Error', 'Failed to assign card: $e');
// //     }
// //   }
// // }











// // // import 'package:get/get.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:major_project/utils/rfid_card.dart';


// // // class AdminRFIDController extends GetxController {
// // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// // //   final RxList<RFIDCard> rfidCards = <RFIDCard>[].obs;
// // //   final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;

// // //   @override
// // //   void onInit() {
// // //     super.onInit();
// // //     _loadRFIDCards();
// // //     _loadPendingRequests();
// // //   }

// // //   Future<void> _loadRFIDCards() async {
// // //     try {
// // //       final snapshot = await _firestore.collection('rfid_cards').get();
// // //       rfidCards.value = snapshot.docs
// // //           .map((doc) => RFIDCard.fromMap({...doc.data(), 'uid': doc.id}))
// // //           .toList();
// // //     } catch (e) {
// // //       // print('Error loading RFID cards: $e');
// // //     }
// // //   }

// // //   Future<void> _loadPendingRequests() async {
// // //     try {
// // //       final snapshot = await _firestore
// // //           .collection('users')
// // //           .where('cardStatus', isEqualTo: 'requested')
// // //           .where('isVerified', isEqualTo: true)
// // //           .get();

// // //       pendingRequests.value = snapshot.docs.map((doc) {
// // //         return {
// // //           'uid': doc.id,
// // //           ...doc.data(),
// // //         };
// // //       }).toList();
// // //     } catch (e) {
// // //       // print('Error loading pending requests: $e');
// // //     }
// // //   }

// // //   List<RFIDCard> get availableCards =>
// // //       rfidCards.where((card) => !card.isAssigned).toList();

// // //   Future<void> addRFIDCard(String uid) async {
// // //     try {
// // //       await _firestore.collection('rfid_cards').add({
// // //         'uid': uid,
// // //         'isAssigned': false,
// // //         'assignedTo': null,
// // //         'assignedDate': null,
// // //       });
      
// // //       await _loadRFIDCards();
// // //       Get.snackbar('Success', 'RFID card added successfully');
// // //     } catch (e) {
// // //       Get.snackbar('Error', 'Failed to add RFID card: $e');
// // //     }
// // //   }

// // //   Future<void> assignCard(String userId, String cardId) async {
// // //     try {
// // //       await _firestore.runTransaction((transaction) async {
// // //         // Update user document
// // //         transaction.update(
// // //           _firestore.collection('users').doc(userId),
// // //           {
// // //             'cardStatus': 'active',
// // //             'assignedCardId': cardId,
// // //             'cardAssignmentDate': FieldValue.serverTimestamp(),
// // //           },
// // //         );

// // //         // Update card document
// // //         transaction.update(
// // //           _firestore.collection('rfid_cards').doc(cardId),
// // //           {
// // //             'isAssigned': true,
// // //             'assignedTo': userId,
// // //             'assignedDate': FieldValue.serverTimestamp(),
// // //           },
// // //         );
// // //       });

// // //       await _loadRFIDCards();
// // //       await _loadPendingRequests();
// // //       Get.snackbar('Success', 'Card assigned successfully');
// // //     } catch (e) {
// // //       Get.snackbar('Error', 'Failed to assign card: $e');
// // //     }
// // //   }
// // // }