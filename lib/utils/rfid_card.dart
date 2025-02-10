import 'package:cloud_firestore/cloud_firestore.dart';


class RFIDCard {
  final String uid;
  final bool isAssigned;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedDate;

  RFIDCard({
    required this.uid,
    required this.isAssigned,
    this.assignedTo,
    this.assignedToName,
    this.assignedDate,
  });

  factory RFIDCard.fromMap(Map<String, dynamic> map) {
    return RFIDCard(
      uid: map['uid'] ?? '',
      isAssigned: map['isAssigned'] ?? false,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      assignedDate: map['assignedDate'] != null 
          ? (map['assignedDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'isAssigned': isAssigned,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedDate': assignedDate != null ? Timestamp.fromDate(assignedDate!) : null,
    };
  }
}


// class RFIDCard {
//   final String uid;
//   final String? assignedTo;
//   final bool isAssigned;
//   final DateTime? assignedDate;

//   RFIDCard({
//     required this.uid,
//     this.assignedTo,
//     required this.isAssigned,
//     this.assignedDate,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'assignedTo': assignedTo,
//       'isAssigned': isAssigned,
//       'assignedDate': assignedDate,
//     };
//   }

//   factory RFIDCard.fromMap(Map<String, dynamic> map) {
//     return RFIDCard(
//       uid: map['uid'] ?? '',
//       assignedTo: map['assignedTo'],
//       isAssigned: map['isAssigned'] ?? false,
//       assignedDate: map['assignedDate']?.toDate(),
//     );
//   }
// }