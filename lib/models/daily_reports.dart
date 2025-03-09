import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReport {
  final String date;
  final double totalAmount;
  final int totalJourneys;
  final List<String> rfidsScanned;
  final DateTime timestamp;

  DailyReport({
    required this.date,
    required this.totalAmount,
    required this.totalJourneys,
    required this.rfidsScanned,
    required this.timestamp,
  });

  factory DailyReport.fromMap(Map<String, dynamic> map) {
    // Handle Firestore timestamp conversion
    DateTime getDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now();
    }

    return DailyReport(
      date: map['date'] ?? '',
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      totalJourneys: map['total_journeys']?.toInt() ?? 0,
      rfidsScanned: List<String>.from(map['rfids_scanned'] ?? []),
      timestamp: getDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_amount': totalAmount,
      'total_journeys': totalJourneys,
      'rfids_scanned': rfidsScanned,
      'timestamp': FieldValue.serverTimestamp(),  // Use server timestamp when saving
    };
  }

  DailyReport copyWith({
    String? date,
    double? totalAmount,
    int? totalJourneys,
    List<String>? rfidsScanned,
    DateTime? timestamp,
  }) {
    return DailyReport(
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      totalJourneys: totalJourneys ?? this.totalJourneys,
      rfidsScanned: rfidsScanned ?? this.rfidsScanned,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}








// import 'package:cloud_firestore/cloud_firestore.dart';

// class DailyReport {
//   final String date;
//   final double totalAmount;
//   final int totalJourneys;
//   final List<String> rfidsScanned;
//   final DateTime timestamp;

//   DailyReport({
//     required this.date,
//     required this.totalAmount,
//     required this.totalJourneys,
//     required this.rfidsScanned,
//     required this.timestamp,
//   });

//   factory DailyReport.fromMap(Map<String, dynamic> map) {
//     // Handle Firestore timestamp conversion
//     DateTime getDateTime(dynamic timestamp) {
//       if (timestamp is Timestamp) {
//         return timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         return timestamp;
//       }
//       return DateTime.now();
//     }

//     return DailyReport(
//       date: map['date'] ?? '',
//       totalAmount: map['total_amount']?.toDouble() ?? 0.0,
//       totalJourneys: map['total_journeys']?.toInt() ?? 0,
//       rfidsScanned: List<String>.from(map['rfids_scanned'] ?? []),
//       timestamp: getDateTime(map['timestamp']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date,
//       'total_amount': totalAmount,
//       'total_journeys': totalJourneys,
//       'rfids_scanned': rfidsScanned,
//       'timestamp': FieldValue.serverTimestamp(),  // Use server timestamp when saving
//     };
//   }

//   DailyReport copyWith({
//     String? date,
//     double? totalAmount,
//     int? totalJourneys,
//     List<String>? rfidsScanned,
//     DateTime? timestamp,
//   }) {
//     return DailyReport(
//       date: date ?? this.date,
//       totalAmount: totalAmount ?? this.totalAmount,
//       totalJourneys: totalJourneys ?? this.totalJourneys,
//       rfidsScanned: rfidsScanned ?? this.rfidsScanned,
//       timestamp: timestamp ?? this.timestamp,
//     );
//   }
// }














// class DailyReport {
//   final String date;
//   final double totalAmount;
//   final int totalJourneys;
//   final List<String> rfidsScanned;
//   final DateTime timestamp;

//   DailyReport({
//     required this.date,
//     required this.totalAmount,
//     required this.totalJourneys,
//     required this.rfidsScanned,
//     required this.timestamp,
//   });

//   factory DailyReport.fromMap(Map<String, dynamic> map) {
//     return DailyReport(
//       date: map['date'] ?? '',
//       totalAmount: map['total_amount']?.toDouble() ?? 0.0,
//       totalJourneys: map['total_journeys']?.toInt() ?? 0,
//       rfidsScanned: List<String>.from(map['rfids_scanned'] ?? []),
//       timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date,
//       'total_amount': totalAmount,
//       'total_journeys': totalJourneys,
//       'rfids_scanned': rfidsScanned,
//       'timestamp': timestamp,
//     };
//   }

//   DailyReport copyWith({
//     String? date,
//     double? totalAmount,
//     int? totalJourneys,
//     List<String>? rfidsScanned,
//     DateTime? timestamp,
//   }) {
//     return DailyReport(
//       date: date ?? this.date,
//       totalAmount: totalAmount ?? this.totalAmount,
//       totalJourneys: totalJourneys ?? this.totalJourneys,
//       rfidsScanned: rfidsScanned ?? this.rfidsScanned,
//       timestamp: timestamp ?? this.timestamp,
//     );
//   }
// }








// class DailyReport {
//   final String date;
//   final double totalAmount;
//   final int totalJourneys;
//   final List<String> rfidsScanned;
//   final DateTime timestamp;

//   DailyReport({
//     required this.date,
//     required this.totalAmount,
//     required this.totalJourneys,
//     required this.rfidsScanned,
//     required this.timestamp,
//   });

//   factory DailyReport.fromMap(Map<String, dynamic> map) {
//     return DailyReport(
//       date: map['date'] ?? '',
//       totalAmount: map['total_amount']?.toDouble() ?? 0.0,
//       totalJourneys: map['total_journeys']?.toInt() ?? 0,
//       rfidsScanned: List<String>.from(map['rfids_scanned'] ?? []),
//       timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date,
//       'total_amount': totalAmount,
//       'total_journeys': totalJourneys,
//       'rfids_scanned': rfidsScanned,
//       'timestamp': timestamp,
//     };
//   }

//   DailyReport copyWith({
//     String? date,
//     double? totalAmount,
//     int? totalJourneys,
//     List<String>? rfidsScanned,
//     DateTime? timestamp,
//   }) {
//     return DailyReport(
//       date: date ?? this.date,
//       totalAmount: totalAmount ?? this.totalAmount,
//       totalJourneys: totalJourneys ?? this.totalJourneys,
//       rfidsScanned: rfidsScanned ?? this.rfidsScanned,
//       timestamp: timestamp ?? this.timestamp,
//     );
//   }
// }