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
    // Get today's date components for comparison
    final now = DateTime.now();
    final todayYear = now.year;
    final todayMonth = now.month;
    final todayDay = now.day;
    
    debugPrint('Setting up listeners for today: ${now.year}-${now.month}-${now.day}');
    
    // Listen for new entries
    _database.ref('bus_entries').onChildAdded.listen((event) async {
      if (event.snapshot.value == null) return;
      
      final entryData = event.snapshot.value as Map<dynamic, dynamic>;
      final rfidId = entryData['scannedCardId'];
      final entryTimeString = entryData['entry_time']?.toString();
      
      if (rfidId == null || entryTimeString == null) {
        debugPrint('Missing RFID ID or entry time in entry data');
        return;
      }
      
      // Parse the entry time to check if it's from today
      try {
        // Handle the format "2025-3-1 16:13:13"
        final parts = entryTimeString.split(' ');
        if (parts.length >= 2) {
          final dateParts = parts[0].split('-');
          if (dateParts.length >= 3) {
            final year = int.tryParse(dateParts[0]) ?? 0;
            final month = int.tryParse(dateParts[1]) ?? 0;
            final day = int.tryParse(dateParts[2]) ?? 0;
            
            // Check if this entry is from today
            if (year != todayYear || month != todayMonth || day != todayDay) {
              debugPrint('Ignoring entry from different date: $entryTimeString (not today)');
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing entry date: $e');
        // Continue processing if date parsing fails
      }
      
      debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

      // Check if the journey already exists in Firestore
      try {
        final existingJourney = await _firestore
            .collection('journey_history')
            .where('rfid', isEqualTo: rfidId)
            .where('entry_time', isEqualTo: entryTimeString)
            .get();

        if (existingJourney.docs.isEmpty) {
          await storeJourneyHistory(rfidId, entryData, null);
          debugPrint('Stored new journey for RFID: $rfidId');
        } else {
          debugPrint('Journey already exists for RFID: $rfidId');
        }
      } catch (e) {
        debugPrint('Error checking or storing journey: $e');
      }
    }, onError: (error) {
      debugPrint('Error in bus_entries listener: $error');
    });

    // Listen for exits with similar date validation
    _database.ref('bus_exits').onChildAdded.listen((event) async {
      if (event.snapshot.value == null) return;
      
      final exitData = event.snapshot.value as Map<dynamic, dynamic>;
      final rfidId = exitData['scannedCardId'];
      final exitTimeString = exitData['exit_time']?.toString();
      
      if (rfidId == null || exitTimeString == null) {
        debugPrint('Missing RFID ID or exit time in exit data');
        return;
      }
      
      // Parse the exit time to check if it's from today
      try {
        // Handle the format "2025-3-1 16:14:37"
        final parts = exitTimeString.split(' ');
        if (parts.length >= 2) {
          final dateParts = parts[0].split('-');
          if (dateParts.length >= 3) {
            final year = int.tryParse(dateParts[0]) ?? 0;
            final month = int.tryParse(dateParts[1]) ?? 0;
            final day = int.tryParse(dateParts[2]) ?? 0;
            
            // Check if this exit is from today
            if (year != todayYear || month != todayMonth || day != todayDay) {
              debugPrint('Ignoring exit from different date: $exitTimeString (not today)');
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing exit date: $e');
        // Continue processing if date parsing fails
      }
      
      debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

      try {
        // Find active journey for this RFID
        final activeJourney = await _firestore
            .collection('journey_history')
            .where('rfid', isEqualTo: rfidId)
            .where('status', isEqualTo: 'active')
            .get();

        if (activeJourney.docs.isNotEmpty) {
          await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
          debugPrint('Updated journey with exit data for RFID: $rfidId');
        } else {
          debugPrint('No active journey found for RFID: $rfidId');
        }
      } catch (e) {
        debugPrint('Error finding or updating journey: $e');
      }
    }, onError: (error) {
      debugPrint('Error in bus_exits listener: $error');
    });

    debugPrint('Realtime database listeners setup complete');
  } catch (e) {
    debugPrint('Error setting up realtime listeners: $e');
  }
}




  // void setupRealtimeDatabaseListener() {
  //   try {
  //     // Listen for new entries
  //     _database.ref('bus_entries').onChildAdded.listen((event) async {
  //       if (event.snapshot.value == null) return;
  //       debugPrint('New entry detected: ${event.snapshot.key}');

  //       final rfidId = event.snapshot.key!;
  //       final entryData = event.snapshot.value as Map<dynamic, dynamic>;

  //       final existingJourney = await _firestore
  //           .collection('journey_history')
  //           .where('rfid', isEqualTo: rfidId)
  //           .where('entry_time', isEqualTo: entryData['entry_time'])
  //           .get();

  //       if (existingJourney.docs.isEmpty) {
  //         await storeJourneyHistory(rfidId, entryData, null);
  //         debugPrint('Stored new journey');
  //       }
  //     }, onError: (error) {
  //       debugPrint('Error in bus_entries listener: $error');
  //     });

  //     // Listen for exits
  //     _database.ref('bus_exits').onChildAdded.listen((event) async {
  //       if (event.snapshot.value == null) return;
  //       debugPrint('New exit detected: ${event.snapshot.key}');

  //       final rfidId = event.snapshot.key!;
  //       final exitData = event.snapshot.value as Map<dynamic, dynamic>;

  //       final activeJourney = await _firestore
  //           .collection('journey_history')
  //           .where('rfid', isEqualTo: rfidId)
  //           .where('status', isEqualTo: 'active')
  //           .get();

  //       if (activeJourney.docs.isNotEmpty) {
  //         await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
  //         debugPrint('Updated journey with exit data');
  //       }
  //     }, onError: (error) {
  //       debugPrint('Error in bus_exits listener: $error');
  //     });

  //     debugPrint('Realtime database listeners setup complete');
  //   } catch (e) {
  //     debugPrint('Error setting up realtime listeners: $e');
  //   }
  // }

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
        'remaining_balance': exitData?['remaining_balance'],
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
        'remaining_balance': exitData['remaining_balance'],
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

//   // Modified to avoid composite index
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching journeys for date: $today');
//       return _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .snapshots()
//           .map((snapshot) {
//             debugPrint('Received ${snapshot.docs.length} journeys');
//             // Sort the journeys in memory instead of in the query
//             final journeys = snapshot.docs
//                 .map((doc) => Journey.fromMap(doc.data()))
//                 .toList()
//               ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
//             return journeys;
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
//   try {
//     final String todayDate = CustomDateUtils.getTodayFormattedDate();
//     debugPrint('Setting up listeners for today: $todayDate');
    
//     // Listen for new entries
//     _database.ref('bus_entries').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;
      
//       final entryData = event.snapshot.value as Map<dynamic, dynamic>;
//       final rfidId = entryData['scannedCardId'];
//       final entryTimeString = entryData['entry_time']?.toString();
      
//       if (rfidId == null || entryTimeString == null) {
//         debugPrint('Missing RFID ID or entry time in entry data');
//         return;
//       }
      
//       // Extract date from entry_time and compare with today's date
//       final entryDateParts = entryTimeString.split(' ')[0].split('-');
//       if (entryDateParts.length >= 3) {
//         final year = entryDateParts[0];
//         final month = entryDateParts[1].padLeft(2, '0');
//         final day = entryDateParts[2].padLeft(2, '0');
//         final entryDate = '$year-$month-$day';
        
//         // Only process entries from today
//         if (entryDate != todayDate) {
//           debugPrint('Ignoring entry from different date: $entryTimeString, today is $todayDate');
//           return;
//         }
//       } else {
//         debugPrint('Invalid date format in entry time: $entryTimeString');
//         return;
//       }
      
//       debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

//       // Continue with your existing code to process the entry
//       final existingJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('entry_time', isEqualTo: entryData['entry_time'])
//           .get();

//       if (existingJourney.docs.isEmpty) {
//         await storeJourneyHistory(rfidId, entryData, null);
//         debugPrint('Stored new journey for RFID: $rfidId');
//       } else {
//         debugPrint('Journey already exists for RFID: $rfidId');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_entries listener: $error');
//     });

//     // Apply similar date filtering for bus_exits
//     _database.ref('bus_exits').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;
      
//       final exitData = event.snapshot.value as Map<dynamic, dynamic>;
//       final rfidId = exitData['scannedCardId'];
//       final exitTimeString = exitData['exit_time']?.toString();
      
//       if (rfidId == null || exitTimeString == null) {
//         debugPrint('Missing RFID ID or exit time in exit data');
//         return;
//       }
      
//       // Extract date from exit_time and compare with today's date
//       final exitDateParts = exitTimeString.split(' ')[0].split('-');
//       if (exitDateParts.length >= 3) {
//         final year = exitDateParts[0];
//         final month = exitDateParts[1].padLeft(2, '0');
//         final day = exitDateParts[2].padLeft(2, '0');
//         final exitDate = '$year-$month-$day';
        
//         // Only process exits from today
//         if (exitDate != todayDate) {
//           debugPrint('Ignoring exit from different date: $exitTimeString, today is $todayDate');
//           return;
//         }
//       } else {
//         debugPrint('Invalid date format in exit time: $exitTimeString');
//         return;
//       }
      
//       debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

//       // Continue with existing code
//       final activeJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('status', isEqualTo: 'active')
//           .get();

//       if (activeJourney.docs.isNotEmpty) {
//         await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//         debugPrint('Updated journey with exit data for RFID: $rfidId');
//       } else {
//         debugPrint('No active journey found for RFID: $rfidId');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_exits listener: $error');
//     });

//     debugPrint('Realtime database listeners setup complete for date: $todayDate');
//   } catch (e) {
//     debugPrint('Error setting up realtime listeners: $e');
//   }
// }

// // void setupRealtimeDatabaseListener() {
// //   try {
// //     // Track the timestamp when the listener is initialized
// //     final DateTime initializationTime = DateTime.now();
    
// //     // Listen for new entries
// //     _database.ref('bus_entries').onChildAdded.listen((event) async {
// //       if (event.snapshot.value == null) return;
      
// //       final entryData = event.snapshot.value as Map<dynamic, dynamic>;
// //       final rfidId = entryData['scannedCardId'];
// //       final entryTimeString = entryData['entry_time']?.toString();
      
// //       if (rfidId == null || entryTimeString == null) {
// //         debugPrint('Missing RFID ID or entry time in entry data');
// //         return;
// //       }
      
// //       // Skip processing for old data
// //       try {
// //         // Parse the timestamp (assuming format like "2025-2-26 1:6:49")
// //         final DateTime entryTime = DateTime.parse(
// //             entryTimeString.replaceAll(' ', 'T'));
        
// //         // Ignore events that happened before listener initialization
// //         if (entryTime.isBefore(initializationTime)) {
// //           debugPrint('Ignoring old entry data from: $entryTimeString');
// //           return;
// //         }
// //       } catch (e) {
// //         debugPrint('Error parsing entry time: $e');
// //         // Continue with processing if timestamp parsing fails
// //       }
      
// //       debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

// //       final existingJourney = await _firestore
// //           .collection('journey_history')
// //           .where('rfid', isEqualTo: rfidId)
// //           .where('entry_time', isEqualTo: entryData['entry_time'])
// //           .get();

// //       if (existingJourney.docs.isEmpty) {
// //         await storeJourneyHistory(rfidId, entryData, null);
// //         debugPrint('Stored new journey for RFID: $rfidId');
// //       } else {
// //         debugPrint('Journey already exists for RFID: $rfidId');
// //       }
// //     }, onError: (error) {
// //       debugPrint('Error in bus_entries listener: $error');
// //     });

// //     // Listen for exits with similar timestamp validation
// //     _database.ref('bus_exits').onChildAdded.listen((event) async {
// //       if (event.snapshot.value == null) return;
      
// //       final exitData = event.snapshot.value as Map<dynamic, dynamic>;
// //       final rfidId = exitData['scannedCardId'];
// //       final exitTimeString = exitData['exit_time']?.toString();
      
// //       if (rfidId == null || exitTimeString == null) {
// //         debugPrint('Missing RFID ID or exit time in exit data');
// //         return;
// //       }
      
// //       // Skip processing for old data
// //       try {
// //         // Parse the timestamp
// //         final DateTime exitTime = DateTime.parse(
// //             exitTimeString.replaceAll(' ', 'T'));
        
// //         // Ignore events that happened before listener initialization
// //         if (exitTime.isBefore(initializationTime)) {
// //           debugPrint('Ignoring old exit data from: $exitTimeString');
// //           return;
// //         }
// //       } catch (e) {
// //         debugPrint('Error parsing exit time: $e');
// //         // Continue with processing if timestamp parsing fails
// //       }
      
// //       debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

// //       final activeJourney = await _firestore
// //           .collection('journey_history')
// //           .where('rfid', isEqualTo: rfidId)
// //           .where('status', isEqualTo: 'active')
// //           .get();

// //       if (activeJourney.docs.isNotEmpty) {
// //         await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
// //         debugPrint('Updated journey with exit data for RFID: $rfidId');
// //       } else {
// //         debugPrint('No active journey found for RFID: $rfidId');
// //       }
// //     }, onError: (error) {
// //       debugPrint('Error in bus_exits listener: $error');
// //     });

// //     debugPrint('Realtime database listeners setup complete at: $initializationTime');
// //   } catch (e) {
// //     debugPrint('Error setting up realtime listeners: $e');
// //   }
// // }


//   // void setupRealtimeDatabaseListener() {
//   //   try {
//   //     // Listen for new entries
//   //     _database.ref('bus_entries').onChildAdded.listen((event) async {
//   //       if (event.snapshot.value == null) return;
//   //       debugPrint('New entry detected: ${event.snapshot.key}');

//   //       final rfidId = event.snapshot.key!;
//   //       final entryData = event.snapshot.value as Map<dynamic, dynamic>;

//   //       final existingJourney = await _firestore
//   //           .collection('journey_history')
//   //           .where('rfid', isEqualTo: rfidId)
//   //           .where('entry_time', isEqualTo: entryData['entry_time'])
//   //           .get();

//   //       if (existingJourney.docs.isEmpty) {
//   //         await storeJourneyHistory(rfidId, entryData, null);
//   //         debugPrint('Stored new journey');
//   //       }
//   //     }, onError: (error) {
//   //       debugPrint('Error in bus_entries listener: $error');
//   //     });

//   //     // Listen for exits
//   //     _database.ref('bus_exits').onChildAdded.listen((event) async {
//   //       if (event.snapshot.value == null) return;
//   //       debugPrint('New exit detected: ${event.snapshot.key}');

//   //       final rfidId = event.snapshot.key!;
//   //       final exitData = event.snapshot.value as Map<dynamic, dynamic>;

//   //       final activeJourney = await _firestore
//   //           .collection('journey_history')
//   //           .where('rfid', isEqualTo: rfidId)
//   //           .where('status', isEqualTo: 'active')
//   //           .get();

//   //       if (activeJourney.docs.isNotEmpty) {
//   //         await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//   //         debugPrint('Updated journey with exit data');
//   //       }
//   //     }, onError: (error) {
//   //       debugPrint('Error in bus_exits listener: $error');
//   //     });

//   //     debugPrint('Realtime database listeners setup complete');
//   //   } catch (e) {
//   //     debugPrint('Error setting up realtime listeners: $e');
//   //   }
//   // }

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
// import 'package:flutter/material.dart';
// import '../models/journey.dart';
// import '../models/daily_reports.dart';
// import '../utils/date_utils.dart';

// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   // Modified to avoid composite index
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching journeys for date: $today');
//       return _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .snapshots()
//           .map((snapshot) {
//             debugPrint('Received ${snapshot.docs.length} journeys');
//             // Sort the journeys in memory instead of in the query
//             final journeys = snapshot.docs
//                 .map((doc) => Journey.fromMap(doc.data()))
//                 .toList()
//               ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
//             return journeys;
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

// void setupRealtimeDatabaseListener() {
//   try {
//     // Track the timestamp when the listener is initialized
//     final DateTime initializationTime = DateTime.now();
    
//     // Listen for new entries
//     _database.ref('bus_entries').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;
      
//       final entryData = event.snapshot.value as Map<dynamic, dynamic>;
//       final rfidId = entryData['scannedCardId'];
//       final entryTimeString = entryData['entry_time']?.toString();
      
//       if (rfidId == null || entryTimeString == null) {
//         debugPrint('Missing RFID ID or entry time in entry data');
//         return;
//       }
      
//       // Skip processing for old data
//       try {
//         // Parse the timestamp (assuming format like "2025-2-26 1:6:49")
//         final DateTime entryTime = DateTime.parse(
//             entryTimeString.replaceAll(' ', 'T'));
        
//         // Ignore events that happened before listener initialization
//         if (entryTime.isBefore(initializationTime)) {
//           debugPrint('Ignoring old entry data from: $entryTimeString');
//           return;
//         }
//       } catch (e) {
//         debugPrint('Error parsing entry time: $e');
//         // Continue with processing if timestamp parsing fails
//       }
      
//       debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

//       final existingJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('entry_time', isEqualTo: entryData['entry_time'])
//           .get();

//       if (existingJourney.docs.isEmpty) {
//         await storeJourneyHistory(rfidId, entryData, null);
//         debugPrint('Stored new journey for RFID: $rfidId');
//       } else {
//         debugPrint('Journey already exists for RFID: $rfidId');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_entries listener: $error');
//     });

//     // Listen for exits with similar timestamp validation
//     _database.ref('bus_exits').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;
      
//       final exitData = event.snapshot.value as Map<dynamic, dynamic>;
//       final rfidId = exitData['scannedCardId'];
//       final exitTimeString = exitData['exit_time']?.toString();
      
//       if (rfidId == null || exitTimeString == null) {
//         debugPrint('Missing RFID ID or exit time in exit data');
//         return;
//       }
      
//       // Skip processing for old data
//       try {
//         // Parse the timestamp
//         final DateTime exitTime = DateTime.parse(
//             exitTimeString.replaceAll(' ', 'T'));
        
//         // Ignore events that happened before listener initialization
//         if (exitTime.isBefore(initializationTime)) {
//           debugPrint('Ignoring old exit data from: $exitTimeString');
//           return;
//         }
//       } catch (e) {
//         debugPrint('Error parsing exit time: $e');
//         // Continue with processing if timestamp parsing fails
//       }
      
//       debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

//       final activeJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('status', isEqualTo: 'active')
//           .get();

//       if (activeJourney.docs.isNotEmpty) {
//         await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//         debugPrint('Updated journey with exit data for RFID: $rfidId');
//       } else {
//         debugPrint('No active journey found for RFID: $rfidId');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_exits listener: $error');
//     });

//     debugPrint('Realtime database listeners setup complete at: $initializationTime');
//   } catch (e) {
//     debugPrint('Error setting up realtime listeners: $e');
//   }
// }


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
// import 'package:flutter/material.dart';
// import '../models/journey.dart';
// import '../models/daily_reports.dart';
// import '../utils/date_utils.dart';

// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   // Get Today's Journeys Stream
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching journeys for date: $today');
//       return _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .snapshots()
//           .map((snapshot) {
//             debugPrint('Received ${snapshot.docs.length} journeys');
//             final journeys = snapshot.docs
//                 .map((doc) => Journey.fromMap(doc.data()))
//                 .toList()
//               ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
//             return journeys;
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

//   // Get Today's Report Stream
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

//   // Cleanup Phantom Journeys
//   Future<void> cleanupPhantomJourneys() async {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       final phantomJourneys = await _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .where('status', isEqualTo: 'active')
//           .get();

//       for (var doc in phantomJourneys.docs) {
//         final data = doc.data();
//         if (!_isValidEntryData(data)) {
//           await doc.reference.delete();
//           debugPrint('Deleted phantom journey: ${doc.id}');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error cleaning up phantom journeys: $e');
//     }
//   }

//   // Validate Entry Data
//   bool _isValidEntryData(Map<String, dynamic> data) {
//     return data['entry_time'] != null &&
//         data['start_latitude'] != null &&
//         data['start_longitude'] != null &&
//         data['rfid'] != null &&
//         data['entry_time'].toString().isNotEmpty &&
//         (data['start_latitude'] as num) != 0.0 &&
//         (data['start_longitude'] as num) != 0.0;
//   }

//   // Validate Exit Data
//   bool _isValidExitData(Map<dynamic, dynamic> exitData) {
//     final endLat = exitData['end_latitude'];
//     final endLong = exitData['end_longitude'];
    
//     if (endLat == null || endLong == null) return false;
//     if (endLat.abs() < 0.001 || endLong.abs() < 0.001) return false;
//     if (endLat == 0.0 || endLong == 0.0) return false;
    
//     if (exitData['exit_time'] == null || 
//         exitData['distance'] == null || 
//         exitData['fare'] == null) {
//       return false;
//     }
    
//     return true;
//   }

//   // Setup Realtime Database Listeners
//   void setupRealtimeDatabaseListener() {
//     try {
//       // Clean up phantom journeys on startup
//       cleanupPhantomJourneys();

//       // Listen for new entries
//       _database.ref('bus_entries').onChildAdded.listen((event) async {
//         if (event.snapshot.value == null) return;
//         debugPrint('New entry detected: ${event.snapshot.key}');

//         final rfidId = event.snapshot.key!;
//         final entryData = event.snapshot.value as Map<dynamic, dynamic>;

//         // Validate entry data
//         if (!_isValidEntryData(Map<String, dynamic>.from(entryData))) {
//           debugPrint('Invalid entry data received, ignoring...');
//           return;
//         }

//         try {
//           // Check for duplicate entry
//           final existingJourney = await _firestore
//               .collection('journey_history')
//               .where('rfid', isEqualTo: rfidId)
//               .where('entry_time', isEqualTo: entryData['entry_time'])
//               .get();

//           if (existingJourney.docs.isEmpty) {
//             // Check for existing active journey
//             final activeJourney = await _firestore
//                 .collection('journey_history')
//                 .where('rfid', isEqualTo: rfidId)
//                 .where('status', isEqualTo: 'active')
//                 .get();

//             if (activeJourney.docs.isNotEmpty) {
//               debugPrint('Warning: RFID $rfidId has an existing active journey');
//             }

//             await storeJourneyHistory(rfidId, entryData, null);
//             debugPrint('Successfully stored new journey for RFID: $rfidId');
//           } else {
//             debugPrint('Duplicate entry detected for RFID: $rfidId');
//           }
//         } catch (e) {
//           debugPrint('Error processing entry for RFID $rfidId: $e');
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

//         try {
//           final querySnapshot = await _firestore
//               .collection('journey_history')
//               .where('rfid', isEqualTo: rfidId)
//               .where('status', isEqualTo: 'active')
//               .orderBy('timestamp', descending: true)
//               .limit(1)
//               .get();

//           if (querySnapshot.docs.isNotEmpty) {
//             final activeJourneyDoc = querySnapshot.docs.first;
            
//             if (_isValidExitData(exitData)) {
//               await updateJourneyWithExit(activeJourneyDoc.id, exitData);
//               debugPrint('Successfully updated journey with exit data for RFID: $rfidId');
//             } else {
//               debugPrint('Invalid exit data received for RFID: $rfidId');
//             }
//           } else {
//             debugPrint('No active journey found for RFID: $rfidId');
//           }
//         } catch (e) {
//           debugPrint('Error processing exit for RFID $rfidId: $e');
//         }
//       }, onError: (error) {
//         debugPrint('Error in bus_exits listener: $error');
//       });

//       debugPrint('Realtime database listeners setup complete');
//     } catch (e) {
//       debugPrint('Error setting up realtime listeners: $e');
//     }
//   }

//   // Store Journey History
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

//       if (exitData != null && exitData['fare'] != null) {
//         await updateDailyReport(rfid, exitData['fare']);
//       }
//     } catch (e) {
//       debugPrint('Error storing journey: $e');
//       rethrow;
//     }
//   }

//   // Update Journey with Exit Data
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
//       if (journeyDoc.exists && exitData['fare'] != null) {
//         final journeyData = journeyDoc.data()!;
//         await updateDailyReport(journeyData['rfid'], exitData['fare']);
//       }
//     } catch (e) {
//       debugPrint('Error updating journey: $e');
//       rethrow;
//     }
//   }

//   // Update Daily Report
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
// }

















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import '../models/journey.dart';
// import '../models/daily_reports.dart';
// import '../utils/date_utils.dart';

// class DatabaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   // Modified to avoid composite index
//   Stream<List<Journey>> getTodaysJourneys() {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Fetching journeys for date: $today');
//       return _firestore
//           .collection('journey_history')
//           .where('date', isEqualTo: today)
//           .snapshots()
//           .map((snapshot) {
//             debugPrint('Received ${snapshot.docs.length} journeys');
//             // Sort the journeys in memory instead of in the query
//             final journeys = snapshot.docs
//                 .map((doc) => Journey.fromMap(doc.data()))
//                 .toList()
//               ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
//             return journeys;
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
//         // 'remaining_balance': exitData?['remaining_balance'],
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
//         // 'remaining_balance': exitData['remaining_balance'],
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