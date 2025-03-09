import 'package:cloud_firestore/cloud_firestore.dart';

class Journey {
  final String id;
  final String rfid;
  final String date;
  final String entryTime;
  final String? exitTime;
  final double startLatitude;
  final double startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double? distance;
  final double? fare;
  final String status; // 'active' or 'completed'
  final DateTime timestamp;

  Journey({
    required this.id,
    required this.rfid,
    required this.date,
    required this.entryTime,
    this.exitTime,
    required this.startLatitude,
    required this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.distance,
    this.fare,
    required this.status,
    required this.timestamp,
  });

  factory Journey.fromMap(Map<String, dynamic> map) {
    // Handle Firestore timestamp conversion
    DateTime getDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now();
    }

    return Journey(
      id: map['id'] ?? '',
      rfid: map['rfid'] ?? '',
      date: map['date'] ?? '',
      entryTime: map['entry_time'] ?? '',
      exitTime: map['exit_time'],
      startLatitude: map['start_latitude']?.toDouble() ?? 0.0,
      startLongitude: map['start_longitude']?.toDouble() ?? 0.0,
      endLatitude: map['end_latitude']?.toDouble(),
      endLongitude: map['end_longitude']?.toDouble(),
      distance: map['distance']?.toDouble(),
      fare: map['fare']?.toDouble(),
      status: map['status'] ?? 'active',
      timestamp: getDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rfid': rfid,
      'date': date,
      'entry_time': entryTime,
      'exit_time': exitTime,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'distance': distance,
      'fare': fare,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}








// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class Journey {
//   final String? id;
//   final String? rfid;
//   final String? entryTime;
//   final String? exitTime;
//   final String? startLatitude;
//   final String? startLongitude;
//   final String? endLatitude;
//   final String? endLongitude;
//   final String status; // 'active' or 'completed'
//   final String date; // YYYY-MM-DD format
//   final double? distance;
//   final double? fare;
//   final double? remainingBalance;
//   final DateTime timestamp;

//   Journey({
//     this.id,
//     this.rfid,
//     this.entryTime,
//     this.exitTime,
//     this.startLatitude,
//     this.startLongitude,
//     this.endLatitude,
//     this.endLongitude,
//     required this.status,
//     required this.date,
//     this.distance,
//     this.fare,
//     this.remainingBalance,
//     required this.timestamp,
//   });

//   factory Journey.fromMap(Map<String, dynamic> map, {String? documentId}) {
//     // Improved helper function to handle various data types safely
//     T? convertValue<T>(dynamic value) {
//       if (value == null) return null;
      
//       if (T == String) {
//         return value.toString() as T;
//       } else if (T == double) {
//         if (value is int) return value.toDouble() as T;
//         if (value is String) return double.tryParse(value) as T?;
//         if (value is double) return value as T;
//         return null;
//       } else if (T == int) {
//         if (value is String) return int.tryParse(value) as T?;
//         if (value is double) return value.toInt() as T;
//         if (value is int) return value as T;
//         return null;
//       }
//       return value as T?;
//     }

//     // Handle Firestore timestamp conversion
//     DateTime getDateTime(dynamic timestamp) {
//       if (timestamp is Timestamp) {
//         return timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         return timestamp;
//       }
//       return DateTime.now();
//     }

//     try {
//       return Journey(
//         id: documentId,
//         rfid: convertValue<String>(map['rfid']),
//         entryTime: convertValue<String>(map['entry_time']),
//         exitTime: convertValue<String>(map['exit_time']),
//         startLatitude: convertValue<String>(map['start_latitude']),
//         startLongitude: convertValue<String>(map['start_longitude']),
//         endLatitude: convertValue<String>(map['end_latitude']),
//         endLongitude: convertValue<String>(map['end_longitude']),
//         status: convertValue<String>(map['status']) ?? 'active',
//         date: convertValue<String>(map['date']) ?? '',
//         distance: convertValue<double>(map['distance']),
//         fare: convertValue<double>(map['fare']),
//         remainingBalance: convertValue<double>(map['remaining_balance']),
//         timestamp: getDateTime(map['timestamp']),
//       );
//     } catch (e) {
//       debugPrint('Error parsing Journey: $e');
//       debugPrint('Problematic data: $map');
//       // Return a default journey in case of parsing errors
//       return Journey(
//         id: documentId,
//         status: 'unknown',
//         date: '',
//         timestamp: DateTime.now(),
//       );
//     }
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'rfid': rfid,
//       'entry_time': entryTime,
//       'exit_time': exitTime,
//       'start_latitude': startLatitude,
//       'start_longitude': startLongitude,
//       'end_latitude': endLatitude,
//       'end_longitude': endLongitude,
//       'status': status,
//       'date': date,
//       'distance': distance,
//       'fare': fare,
//       'remaining_balance': remainingBalance,
//       'timestamp': FieldValue.serverTimestamp(), // Use server timestamp when saving
//     };
//   }

//   Journey copyWith({
//     String? id,
//     String? rfid,
//     String? entryTime,
//     String? exitTime,
//     String? startLatitude,
//     String? startLongitude,
//     String? endLatitude,
//     String? endLongitude,
//     String? status,
//     String? date,
//     double? distance,
//     double? fare,
//     double? remainingBalance,
//     DateTime? timestamp,
//   }) {
//     return Journey(
//       id: id ?? this.id,
//       rfid: rfid ?? this.rfid,
//       entryTime: entryTime ?? this.entryTime,
//       exitTime: exitTime ?? this.exitTime,
//       startLatitude: startLatitude ?? this.startLatitude,
//       startLongitude: startLongitude ?? this.startLongitude,
//       endLatitude: endLatitude ?? this.endLatitude,
//       endLongitude: endLongitude ?? this.endLongitude,
//       status: status ?? this.status,
//       date: date ?? this.date,
//       distance: distance ?? this.distance,
//       fare: fare ?? this.fare,
//       remainingBalance: remainingBalance ?? this.remainingBalance,
//       timestamp: timestamp ?? this.timestamp,
//     );
//   }
// }







// import 'package:cloud_firestore/cloud_firestore.dart';

// class Journey {
//   final String rfid;
//   final String entryTime;
//   final double startLatitude;
//   final double startLongitude;
//   final String? exitTime;
//   final double? endLatitude;
//   final double? endLongitude;
//   final double? distance;
//   final double? fare;
//   // final double? remainingBalance;
//   final String status;
//   final DateTime timestamp;

//   Journey({
//     required this.rfid,
//     required this.entryTime,
//     required this.startLatitude,
//     required this.startLongitude,
//     this.exitTime,
//     this.endLatitude,
//     this.endLongitude,
//     this.distance,
//     this.fare,
//     // this.remainingBalance,
//     required this.status,
//     required this.timestamp,
//   });

//   factory Journey.fromMap(Map<String, dynamic> map) {
//     // Handle Firestore timestamp conversion
//     DateTime getDateTime(dynamic timestamp) {
//       if (timestamp is Timestamp) {
//         return timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         return timestamp;
//       }
//       return DateTime.now();
//     }

//     return Journey(
//       rfid: map['rfid'] ?? '',
//       entryTime: map['entry_time'] ?? '',
//       startLatitude: (map['start_latitude'] as num?)?.toDouble() ?? 0.0,
//       startLongitude: (map['start_longitude'] as num?)?.toDouble() ?? 0.0,
//       exitTime: map['exit_time'],
//       endLatitude: (map['end_latitude'] as num?)?.toDouble(),
//       endLongitude: (map['end_longitude'] as num?)?.toDouble(),
//       distance: (map['distance'] as num?)?.toDouble(),
//       fare: (map['fare'] as num?)?.toDouble(),
//       // remainingBalance: (map['remaining_balance'] as num?)?.toDouble(),
//       status: map['status'] ?? 'active',
//       timestamp: getDateTime(map['timestamp']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'rfid': rfid,
//       'entry_time': entryTime,
//       'start_latitude': startLatitude,
//       'start_longitude': startLongitude,
//       'exit_time': exitTime,
//       'end_latitude': endLatitude,
//       'end_longitude': endLongitude,
//       'distance': distance,
//       'fare': fare,
//       // 'remaining_balance': remainingBalance,
//       'status': status,
//       'timestamp': FieldValue.serverTimestamp(),  // Use server timestamp when saving
//     };
//   }
// }








// // journey.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Journey {
//   final String rfid;
//   final String entryTime;
//   final double startLatitude;
//   final double startLongitude;
//   final String? exitTime;
//   final double? endLatitude;
//   final double? endLongitude;
//   final double? distance;
//   final double? fare;
//   final double? remainingBalance;
//   final String status;
//   final DateTime timestamp;

//   Journey({
//     required this.rfid,
//     required this.entryTime,
//     required this.startLatitude,
//     required this.startLongitude,
//     this.exitTime,
//     this.endLatitude,
//     this.endLongitude,
//     this.distance,
//     this.fare,
//     this.remainingBalance,
//     required this.status,
//     required this.timestamp,
//   });

//   factory Journey.fromMap(Map<String, dynamic> map) {
//     // Handle Firestore timestamp conversion
//     DateTime getDateTime(dynamic timestamp) {
//       if (timestamp is Timestamp) {
//         return timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         return timestamp;
//       }
//       return DateTime.now();
//     }

//     return Journey(
//       rfid: map['rfid'] ?? '',
//       entryTime: map['entry_time'] ?? '',
//       startLatitude: (map['start_latitude'] as num?)?.toDouble() ?? 0.0,
//       startLongitude: (map['start_longitude'] as num?)?.toDouble() ?? 0.0,
//       exitTime: map['exit_time'],
//       endLatitude: (map['end_latitude'] as num?)?.toDouble(),
//       endLongitude: (map['end_longitude'] as num?)?.toDouble(),
//       distance: (map['distance'] as num?)?.toDouble(),
//       fare: (map['fare'] as num?)?.toDouble(),
//       remainingBalance: (map['remaining_balance'] as num?)?.toDouble(),
//       status: map['status'] ?? 'active',
//       timestamp: getDateTime(map['timestamp']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'rfid': rfid,
//       'entry_time': entryTime,
//       'start_latitude': startLatitude,
//       'start_longitude': startLongitude,
//       'exit_time': exitTime,
//       'end_latitude': endLatitude,
//       'end_longitude': endLongitude,
//       'distance': distance,
//       'fare': fare,
//       'remaining_balance': remainingBalance,
//       'status': status,
//       'timestamp': FieldValue.serverTimestamp(),  // Use server timestamp when saving
//     };
//   }
// }











// // journey.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Journey {
//   final String rfid;
//   final String entryTime;
//   final double startLatitude;
//   final double startLongitude;
//   final String? exitTime;
//   final double? endLatitude;
//   final double? endLongitude;
//   final double? distance;
//   final double? fare;
//   final double? remainingBalance;
//   final String status;
//   final DateTime timestamp;

//   Journey({
//     required this.rfid,
//     required this.entryTime,
//     required this.startLatitude,
//     required this.startLongitude,
//     this.exitTime,
//     this.endLatitude,
//     this.endLongitude,
//     this.distance,
//     this.fare,
//     this.remainingBalance,
//     required this.status,
//     required this.timestamp,
//   });

//   factory Journey.fromMap(Map<String, dynamic> map) {
//     // Properly handle Firestore timestamp conversion
//     DateTime getDateTime(dynamic timestamp) {
//       if (timestamp is Timestamp) {
//         return timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         return timestamp;
//       }
//       return DateTime.now();
//     }

//     return Journey(
//       rfid: map['rfid'] ?? '',
//       entryTime: map['entry_time'] ?? '',
//       startLatitude: map['start_latitude']?.toDouble() ?? 0.0,
//       startLongitude: map['start_longitude']?.toDouble() ?? 0.0,
//       exitTime: map['exit_time'],
//       endLatitude: map['end_latitude']?.toDouble(),
//       endLongitude: map['end_longitude']?.toDouble(),
//       distance: map['distance']?.toDouble(),
//       fare: map['fare']?.toDouble(),
//       remainingBalance: map['remaining_balance']?.toDouble(),
//       status: map['status'] ?? 'active',
//       timestamp: getDateTime(map['timestamp']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'rfid': rfid,
//       'entry_time': entryTime,
//       'start_latitude': startLatitude,
//       'start_longitude': startLongitude,
//       'exit_time': exitTime,
//       'end_latitude': endLatitude,
//       'end_longitude': endLongitude,
//       'distance': distance,
//       'fare': fare,
//       'remaining_balance': remainingBalance,
//       'status': status,
//       'timestamp': timestamp,
//     };
//   }
// }








// class Journey {
//   final String rfid;
//   final String entryTime;
//   final double startLatitude;
//   final double startLongitude;
//   final String? exitTime;
//   final double? endLatitude;
//   final double? endLongitude;
//   final double? distance;
//   final double? fare;
//   final double? remainingBalance;
//   final String status;
//   final DateTime timestamp;

//   Journey({
//     required this.rfid,
//     required this.entryTime,
//     required this.startLatitude,
//     required this.startLongitude,
//     this.exitTime,
//     this.endLatitude,
//     this.endLongitude,
//     this.distance,
//     this.fare,
//     this.remainingBalance,
//     required this.status,
//     required this.timestamp,
//   });

//   factory Journey.fromMap(Map<String, dynamic> map) {
//     return Journey(
//       rfid: map['rfid'] ?? '',
//       entryTime: map['entry_time'] ?? '',
//       startLatitude: map['start_latitude']?.toDouble() ?? 0.0,
//       startLongitude: map['start_longitude']?.toDouble() ?? 0.0,
//       exitTime: map['exit_time'],
//       endLatitude: map['end_latitude']?.toDouble(),
//       endLongitude: map['end_longitude']?.toDouble(),
//       distance: map['distance']?.toDouble(),
//       fare: map['fare']?.toDouble(),
//       remainingBalance: map['remaining_balance']?.toDouble(),
//       status: map['status'] ?? 'active',
//       timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'rfid': rfid,
//       'entry_time': entryTime,
//       'start_latitude': startLatitude,
//       'start_longitude': startLongitude,
//       'exit_time': exitTime,
//       'end_latitude': endLatitude,
//       'end_longitude': endLongitude,
//       'distance': distance,
//       'fare': fare,
//       'remaining_balance': remainingBalance,
//       'status': status,
//       'timestamp': timestamp,
//     };
//   }
// }