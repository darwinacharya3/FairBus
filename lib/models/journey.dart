import 'package:cloud_firestore/cloud_firestore.dart';

class Journey {
  final String rfid;
  final String entryTime;
  final double startLatitude;
  final double startLongitude;
  final String? exitTime;
  final double? endLatitude;
  final double? endLongitude;
  final double? distance;
  final double? fare;
  final double? remainingBalance;
  final String status;
  final DateTime timestamp;

  Journey({
    required this.rfid,
    required this.entryTime,
    required this.startLatitude,
    required this.startLongitude,
    this.exitTime,
    this.endLatitude,
    this.endLongitude,
    this.distance,
    this.fare,
    this.remainingBalance,
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
      rfid: map['rfid'] ?? '',
      entryTime: map['entry_time'] ?? '',
      startLatitude: (map['start_latitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (map['start_longitude'] as num?)?.toDouble() ?? 0.0,
      exitTime: map['exit_time'],
      endLatitude: (map['end_latitude'] as num?)?.toDouble(),
      endLongitude: (map['end_longitude'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      fare: (map['fare'] as num?)?.toDouble(),
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble(),
      status: map['status'] ?? 'active',
      timestamp: getDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rfid': rfid,
      'entry_time': entryTime,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'exit_time': exitTime,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'distance': distance,
      'fare': fare,
      'remaining_balance': remainingBalance,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),  // Use server timestamp when saving
    };
  }
}








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