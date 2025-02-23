import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/daily_reports.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Modified to avoid composite index
  Stream<List<Journey>> getTodaysJourneys() {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('Fetching journeys for date: $today');
      return _firestore
          .collection('journey_history')
          .where('date', isEqualTo: today)
          .snapshots()
          .map((snapshot) {
            debugPrint('Received ${snapshot.docs.length} journeys');
            // Sort the journeys in memory instead of in the query
            final journeys = snapshot.docs
                .map((doc) => Journey.fromMap(doc.data()))
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return journeys;
          })
          .handleError((error) {
            debugPrint('Error in getTodaysJourneys: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('Exception in getTodaysJourneys: $e');
      rethrow;
    }
  }

  Stream<DailyReport> getTodaysReport() {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('Fetching report for date: $today');
      return _firestore
          .collection('analytics_and_report')
          .doc(today)
          .snapshots()
          .map((doc) {
            debugPrint('Received report data: ${doc.data()}');
            return doc.exists
                ? DailyReport.fromMap(doc.data()!)
                : DailyReport(
                    date: today,
                    totalAmount: 0,
                    totalJourneys: 0,
                    rfidsScanned: [],
                    timestamp: DateTime.now(),
                  );
          })
          .handleError((error) {
            debugPrint('Error in getTodaysReport: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('Exception in getTodaysReport: $e');
      rethrow;
    }
  }

  Future<void> updateDailyReport(String rfid, double fare) async {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('Updating report for date: $today with fare: $fare');
      final reportRef = _firestore.collection('analytics_and_report').doc(today);
      
      await _firestore.runTransaction((transaction) async {
        final reportDoc = await transaction.get(reportRef);
        
        if (reportDoc.exists) {
          final currentReport = DailyReport.fromMap(reportDoc.data()!);
          final updatedReport = currentReport.copyWith(
            totalAmount: currentReport.totalAmount + fare,
            totalJourneys: currentReport.totalJourneys + 1,
            rfidsScanned: [...currentReport.rfidsScanned, rfid],
          );
          transaction.update(reportRef, updatedReport.toMap());
          debugPrint('Updated existing report');
        } else {
          final newReport = DailyReport(
            date: today,
            totalAmount: fare,
            totalJourneys: 1,
            rfidsScanned: [rfid],
            timestamp: DateTime.now(),
          );
          transaction.set(reportRef, newReport.toMap());
          debugPrint('Created new report');
        }
      });
    } catch (e) {
      debugPrint('Error updating daily report: $e');
      rethrow;
    }
  }

  void setupRealtimeDatabaseListener() {
    try {
      // Listen for new entries
      _database.ref('bus_entries').onChildAdded.listen((event) async {
        if (event.snapshot.value == null) return;
        debugPrint('New entry detected: ${event.snapshot.key}');

        final rfidId = event.snapshot.key!;
        final entryData = event.snapshot.value as Map<dynamic, dynamic>;

        final existingJourney = await _firestore
            .collection('journey_history')
            .where('rfid', isEqualTo: rfidId)
            .where('entry_time', isEqualTo: entryData['entry_time'])
            .get();

        if (existingJourney.docs.isEmpty) {
          await storeJourneyHistory(rfidId, entryData, null);
          debugPrint('Stored new journey');
        }
      }, onError: (error) {
        debugPrint('Error in bus_entries listener: $error');
      });

      // Listen for exits
      _database.ref('bus_exits').onChildAdded.listen((event) async {
        if (event.snapshot.value == null) return;
        debugPrint('New exit detected: ${event.snapshot.key}');

        final rfidId = event.snapshot.key!;
        final exitData = event.snapshot.value as Map<dynamic, dynamic>;

        final activeJourney = await _firestore
            .collection('journey_history')
            .where('rfid', isEqualTo: rfidId)
            .where('status', isEqualTo: 'active')
            .get();

        if (activeJourney.docs.isNotEmpty) {
          await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
          debugPrint('Updated journey with exit data');
        }
      }, onError: (error) {
        debugPrint('Error in bus_exits listener: $error');
      });

      debugPrint('Realtime database listeners setup complete');
    } catch (e) {
      debugPrint('Error setting up realtime listeners: $e');
    }
  }

  Future<void> storeJourneyHistory(
    String rfid,
    Map<dynamic, dynamic> entryData,
    Map<dynamic, dynamic>? exitData,
  ) async {
    try {
      final journeyData = {
        'rfid': rfid,
        'entry_time': entryData['entry_time'],
        'start_latitude': entryData['start_latitude'],
        'start_longitude': entryData['start_longitude'],
        'exit_time': exitData?['exit_time'],
        'end_latitude': exitData?['end_latitude'],
        'end_longitude': exitData?['end_longitude'],
        'distance': exitData?['distance'],
        'fare': exitData?['fare'],
        // 'remaining_balance': exitData?['remaining_balance'],
        'status': exitData != null ? 'completed' : 'active',
        'date': CustomDateUtils.getTodayFormattedDate(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('journey_history').add(journeyData);
      debugPrint('Journey stored successfully');

      if (exitData != null) {
        await updateDailyReport(rfid, exitData['fare']);
      }
    } catch (e) {
      debugPrint('Error storing journey: $e');
      rethrow;
    }
  }

  Future<void> updateJourneyWithExit(
    String docId,
    Map<dynamic, dynamic> exitData,
  ) async {
    try {
      await _firestore.collection('journey_history').doc(docId).update({
        'exit_time': exitData['exit_time'],
        'end_latitude': exitData['end_latitude'],
        'end_longitude': exitData['end_longitude'],
        'distance': exitData['distance'],
        'fare': exitData['fare'],
        // 'remaining_balance': exitData['remaining_balance'],
        'status': 'completed',
      });
      debugPrint('Journey exit updated successfully');

      final journeyDoc = await _firestore.collection('journey_history').doc(docId).get();
      if (journeyDoc.exists) {
        final journeyData = journeyDoc.data()!;
        await updateDailyReport(journeyData['rfid'], exitData['fare']);
      }
    } catch (e) {
      debugPrint('Error updating journey: $e');
      rethrow;
    }
  }
}




















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import '../models/journey.dart';
// import '../models/daily_reports.dart';
// import '../utils/date_utils.dart';

// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   // Journey Collection Methods
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching journeys for date: $today');
//       return _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .orderBy('timestamp', descending: true)
//           .snapshots()
//           .map((snapshot) {
//             debugPrint('Received ${snapshot.docs.length} journeys');
//             return snapshot.docs.map((doc) => Journey.fromMap(doc.data())).toList();
//           })
//           .handleError((error) {
//             debugPrint('Error in getTodaysJourneys: $error');
//             throw error;
//           });
//     } catch (e) {
//       debugPrint('Exception in getTodaysJourneys: $e');
//       rethrow;
//     }
//   }

//   Stream<DailyReport> getTodaysReport() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching report for date: $today');
//       return _firestore
//           .collection('analytics_and_report')
//           .doc(today)
//           .snapshots()
//           .map((doc) {
//             debugPrint('Received report data: ${doc.data()}');
//             return doc.exists
//                 ? DailyReport.fromMap(doc.data()!)
//                 : DailyReport(
//                     date: today,
//                     totalAmount: 0,
//                     totalJourneys: 0,
//                     rfidsScanned: [],
//                     timestamp: DateTime.now(),
//                   );
//           })
//           .handleError((error) {
//             debugPrint('Error in getTodaysReport: $error');
//             throw error;
//           });
//     } catch (e) {
//       debugPrint('Exception in getTodaysReport: $e');
//       rethrow;
//     }
//   }

//   Future<void> updateDailyReport(String rfid, double fare) async {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Updating report for date: $today with fare: $fare');
//       final reportRef = _firestore.collection('analytics_and_report').doc(today);
      
//       await _firestore.runTransaction((transaction) async {
//         final reportDoc = await transaction.get(reportRef);
        
//         if (reportDoc.exists) {
//           final currentReport = DailyReport.fromMap(reportDoc.data()!);
//           final updatedReport = currentReport.copyWith(
//             totalAmount: currentReport.totalAmount + fare,
//             totalJourneys: currentReport.totalJourneys + 1,
//             rfidsScanned: [...currentReport.rfidsScanned, rfid],
//           );
//           transaction.update(reportRef, updatedReport.toMap());
//           debugPrint('Updated existing report');
//         } else {
//           final newReport = DailyReport(
//             date: today,
//             totalAmount: fare,
//             totalJourneys: 1,
//             rfidsScanned: [rfid],
//             timestamp: DateTime.now(),
//           );
//           transaction.set(reportRef, newReport.toMap());
//           debugPrint('Created new report');
//         }
//       });
//     } catch (e) {
//       debugPrint('Error updating daily report: $e');
//       rethrow;
//     }
//   }

//   void setupRealtimeDatabaseListener() {
//     try {
//       // Listen for new entries
//       _database.ref('bus_entries').onChildAdded.listen((event) async {
//         if (event.snapshot.value == null) return;
//         debugPrint('New entry detected: ${event.snapshot.key}');

//         final rfidId = event.snapshot.key!;
//         final entryData = event.snapshot.value as Map<dynamic, dynamic>;

//         final existingJourney = await _firestore
//             .collection('journey_history')
//             .where('rfid', isEqualTo: rfidId)
//             .where('entry_time', isEqualTo: entryData['entry_time'])
//             .get();

//         if (existingJourney.docs.isEmpty) {
//           await storeJourneyHistory(rfidId, entryData, null);
//           debugPrint('Stored new journey');
//         }
//       }, onError: (error) {
//         debugPrint('Error in bus_entries listener: $error');
//       });

//       // Listen for exits
//       _database.ref('bus_exits').onChildAdded.listen((event) async {
//         if (event.snapshot.value == null) return;
//         debugPrint('New exit detected: ${event.snapshot.key}');

//         final rfidId = event.snapshot.key!;
//         final exitData = event.snapshot.value as Map<dynamic, dynamic>;

//         final activeJourney = await _firestore
//             .collection('journey_history')
//             .where('rfid', isEqualTo: rfidId)
//             .where('status', isEqualTo: 'active')
//             .get();

//         if (activeJourney.docs.isNotEmpty) {
//           await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//           debugPrint('Updated journey with exit data');
//         }
//       }, onError: (error) {
//         debugPrint('Error in bus_exits listener: $error');
//       });

//       debugPrint('Realtime database listeners setup complete');
//     } catch (e) {
//       debugPrint('Error setting up realtime listeners: $e');
//     }
//   }

//   Future<void> storeJourneyHistory(
//     String rfid,
//     Map<dynamic, dynamic> entryData,
//     Map<dynamic, dynamic>? exitData,
//   ) async {
//     try {
//       final journeyData = {
//         'rfid': rfid,
//         'entry_time': entryData['entry_time'],
//         'start_latitude': entryData['start_latitude'],
//         'start_longitude': entryData['start_longitude'],
//         'exit_time': exitData?['exit_time'],
//         'end_latitude': exitData?['end_latitude'],
//         'end_longitude': exitData?['end_longitude'],
//         'distance': exitData?['distance'],
//         'fare': exitData?['fare'],
//         'remaining_balance': exitData?['remaining_balance'],
//         'status': exitData != null ? 'completed' : 'active',
//         'date': CustomDateUtils.getTodayFormattedDate(),
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       await _firestore.collection('journey_history').add(journeyData);
//       debugPrint('Journey stored successfully');

//       if (exitData != null) {
//         await updateDailyReport(rfid, exitData['fare']);
//       }
//     } catch (e) {
//       debugPrint('Error storing journey: $e');
//       rethrow;
//     }
//   }

//   Future<void> updateJourneyWithExit(
//     String docId,
//     Map<dynamic, dynamic> exitData,
//   ) async {
//     try {
//       await _firestore.collection('journey_history').doc(docId).update({
//         'exit_time': exitData['exit_time'],
//         'end_latitude': exitData['end_latitude'],
//         'end_longitude': exitData['end_longitude'],
//         'distance': exitData['distance'],
//         'fare': exitData['fare'],
//         'remaining_balance': exitData['remaining_balance'],
//         'status': 'completed',
//       });
//       debugPrint('Journey exit updated successfully');

//       final journeyDoc = await _firestore.collection('journey_history').doc(docId).get();
//       if (journeyDoc.exists) {
//         final journeyData = journeyDoc.data()!;
//         await updateDailyReport(journeyData['rfid'], exitData['fare']);
//       }
//     } catch (e) {
//       debugPrint('Error updating journey: $e');
//       rethrow;
//     }
//   }
// }











// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../models/journey.dart';
// import 'package:major_project/models/daily_reports.dart';
// import '../utils/date_utils.dart';

// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   // Journey Collection Methods
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = DateUtils.getTodayFormattedDate();
//     return _firestore
//         .collection('journey_history')
//         .where('date', isEqualTo: today)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) =>
//             snapshot.docs.map((doc) => Journey.fromMap(doc.data())).toList());
//   }

//   Future<void> storeJourneyHistory(
//     String rfid,
//     Map<dynamic, dynamic> entryData,
//     Map<dynamic, dynamic>? exitData,
//   ) async {
//     try {
//       final journeyData = {
//         'rfid': rfid,
//         'entry_time': entryData['entry_time'],
//         'start_latitude': entryData['start_latitude'],
//         'start_longitude': entryData['start_longitude'],
//         'exit_time': exitData?['exit_time'],
//         'end_latitude': exitData?['end_latitude'],
//         'end_longitude': exitData?['end_longitude'],
//         'distance': exitData?['distance'],
//         'fare': exitData?['fare'],
//         'remaining_balance': exitData?['remaining_balance'],
//         'status': exitData != null ? 'completed' : 'active',
//         'date': DateUtils.getTodayFormattedDate(),
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       await _firestore.collection('journey_history').add(journeyData);

//       if (exitData != null) {
//         await updateDailyReport(rfid, exitData['fare']);
//       }
//     } catch (e) {
//       print('Error storing journey: $e');
//       rethrow;
//     }
//   }

//   // Analytics and Reports Methods
//   Future<void> updateDailyReport(String rfid, double fare) async {
//     final today = DateUtils.getTodayFormattedDate();
//     final reportRef = _firestore
//         .collection('analytics_and_report')
//         .doc(today);

//     try {
//       await _firestore.runTransaction((transaction) async {
//         final reportDoc = await transaction.get(reportRef);

//         if (reportDoc.exists) {
//           final currentReport = DailyReport.fromMap(reportDoc.data()!);
//           final updatedReport = currentReport.copyWith(
//             totalAmount: currentReport.totalAmount + fare,
//             totalJourneys: currentReport.totalJourneys + 1,
//             rfidsScanned: [...currentReport.rfidsScanned, rfid],
//           );
//           transaction.update(reportRef, updatedReport.toMap());
//         } else {
//           final newReport = DailyReport(
//             date: today,
//             totalAmount: fare,
//             totalJourneys: 1,
//             rfidsScanned: [rfid],
//             timestamp: DateTime.now(),
//           );
//           transaction.set(reportRef, newReport.toMap());
//         }
//       });
//     } catch (e) {
//       print('Error updating daily report: $e');
//       rethrow;
//     }
//   }

//   Stream<DailyReport> getTodaysReport() {
//     final today = DateUtils.getTodayFormattedDate();
//     return _firestore
//         .collection('analytics_and_report')
//         .doc(today)
//         .snapshots()
//         .map((doc) => doc.exists
//             ? DailyReport.fromMap(doc.data()!)
//             : DailyReport(
//                 date: today,
//                 totalAmount: 0,
//                 totalJourneys: 0,
//                 rfidsScanned: [],
//                 timestamp: DateTime.now(),
//               ));
//   }

//   void setupRealtimeDatabaseListener() {
//     // Listen for new entries
//     _database.ref('bus_entries').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;

//       final rfidId = event.snapshot.key!;
//       final entryData = event.snapshot.value as Map<dynamic, dynamic>;

//       // Check if journey already exists
//       final existingJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('entry_time', isEqualTo: entryData['entry_time'])
//           .get();

//       if (existingJourney.docs.isEmpty) {
//         await storeJourneyHistory(rfidId, entryData, null);
//       }
//     });

//     // Listen for exits
//     _database.ref('bus_exits').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;

//       final rfidId = event.snapshot.key!;
//       final exitData = event.snapshot.value as Map<dynamic, dynamic>;

//       final activeJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('status', isEqualTo: 'active')
//           .get();

//       if (activeJourney.docs.isNotEmpty) {
//         final journeyDoc = activeJourney.docs.first;
//         await updateJourneyWithExit(journeyDoc.id, exitData);
//       }
//     });
//   }

//   Future<void> updateJourneyWithExit(
//     String docId,
//     Map<dynamic, dynamic> exitData,
//   ) async {
//     try {
//       await _firestore.collection('journey_history').doc(docId).update({
//         'exit_time': exitData['exit_time'],
//         'end_latitude': exitData['end_latitude'],
//         'end_longitude': exitData['end_longitude'],
//         'distance': exitData['distance'],
//         'fare': exitData['fare'],
//         'remaining_balance': exitData['remaining_balance'],
//         'status': 'completed',
//       });

//       // Update daily report with the fare
//       await updateDailyReport(docId, exitData['fare']);
//     } catch (e) {
//       print('Error updating journey: $e');
//       rethrow;
//     }
//   }
// }