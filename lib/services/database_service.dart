import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/daily_reports.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Track processed events to avoid duplicates
  final Set<String> _processedEntryKeys = {};
  final Set<String> _processedExitKeys = {};

  // Get today's journeys for display in the UI
  Stream<List<Journey>> getTodaysJourneys() {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('🔄 DatabaseService - Fetching journeys for date: $today');
      return _firestore
          .collection('journey_history')
          .where('date', isEqualTo: today)
          .snapshots()
          .map((snapshot) {
            debugPrint('✅ DatabaseService - Received ${snapshot.docs.length} journeys from Firestore');
            // Sort the journeys in memory instead of in the query
            final journeys = snapshot.docs
                .map((doc) => Journey.fromMap(doc.data()))
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return journeys;
          })
          .handleError((error) {
            debugPrint('❌ DatabaseService - ERROR in getTodaysJourneys: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('❌ DatabaseService - EXCEPTION in getTodaysJourneys: $e');
      rethrow;
    }
  }

  // Get daily report for the analytics display
  Stream<DailyReport> getTodaysReport() {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('🔄 DatabaseService - Fetching report for date: $today');
      return _firestore
          .collection('analytics_and_report')
          .doc(today)
          .snapshots()
          .map((doc) {
            debugPrint('✅ DatabaseService - Received report data: ${doc.data()}');
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
            debugPrint('❌ DatabaseService - ERROR in getTodaysReport: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('❌ DatabaseService - EXCEPTION in getTodaysReport: $e');
      rethrow;
    }
  }

  // Update daily report with new journey information
  Future<void> updateDailyReport(String rfid, double fare) async {
    final today = CustomDateUtils.getTodayFormattedDate();
    try {
      debugPrint('🔄 DatabaseService - Updating report for date: $today with fare: $fare, rfid: $rfid');
      final reportRef = _firestore.collection('analytics_and_report').doc(today);
      
      await _firestore.runTransaction((transaction) async {
        final reportDoc = await transaction.get(reportRef);
        
        if (reportDoc.exists) {
          final currentReport = DailyReport.fromMap(reportDoc.data()!);
          final updatedReport = currentReport.copyWith(
            totalAmount: currentReport.totalAmount + fare,
            totalJourneys: currentReport.totalJourneys + 1,
            rfidsScanned: 
              currentReport.rfidsScanned.contains(rfid) 
                ? currentReport.rfidsScanned 
                : [...currentReport.rfidsScanned, rfid],
          );
          transaction.update(reportRef, updatedReport.toMap());
          debugPrint('✅ DatabaseService - Updated existing report');
        } else {
          final newReport = DailyReport(
            date: today,
            totalAmount: fare,
            totalJourneys: 1,
            rfidsScanned: [rfid],
            timestamp: DateTime.now(),
          );
          transaction.set(reportRef, newReport.toMap());
          debugPrint('✅ DatabaseService - Created new report');
        }
      });
    } catch (e) {
      debugPrint('❌ DatabaseService - ERROR updating daily report: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Helper method to safely convert values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Parse timestamp from date-time string
  DateTime _parseDateTime(String dateTimeStr) {
    try {
      // Handle the format "2025-3-1 16:14:37"
      final parts = dateTimeStr.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        
        if (dateParts.length >= 3 && timeParts.length >= 3) {
          final year = int.tryParse(dateParts[0]) ?? 0;
          final month = int.tryParse(dateParts[1]) ?? 0;
          final day = int.tryParse(dateParts[2]) ?? 0;
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = int.tryParse(timeParts[2]) ?? 0;
          
          return DateTime(year, month, day, hour, minute, second);
        }
      }
      return DateTime.now(); // Fallback
    } catch (e) {
      debugPrint('❌ Error parsing timestamp: $e');
      return DateTime.now(); // Fallback
    }
  }

  // Store a new journey in Firestore
  Future<String> storeJourneyHistory(String rfidId, Map<dynamic, dynamic> entryData) async {
    try {
      debugPrint('🔄 DatabaseService - Starting to store journey for RFID: $rfidId');
      
      final today = CustomDateUtils.getTodayFormattedDate();
      final String entryTime = entryData['entry_time']?.toString() ?? '';
      
      // Use the safe conversion method for coordinates
      final double startLat = _toDouble(entryData['start_latitude']);
      final double startLong = _toDouble(entryData['start_longitude']);
      
      // Create a unique ID for this journey
      final String journeyId = '${rfidId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final journeyData = {
        'id': journeyId,
        'rfid': rfidId,
        'date': today,
        'entry_time': entryTime,
        'start_latitude': startLat,
        'start_longitude': startLong,
        'status': 'active',
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      debugPrint('🔄 DatabaseService - About to write journey to Firestore: $journeyData');
      
      // Store the journey in Firestore
      await _firestore.collection('journey_history').doc(journeyId).set(journeyData);
      debugPrint('✅ DatabaseService - Successfully stored new journey: $journeyId for RFID: $rfidId');
      
      return journeyId;
    } catch (e) {
      debugPrint('❌ DatabaseService - ERROR storing journey: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Update a journey with exit data
  Future<void> updateJourneyWithExit(String journeyId, Map<dynamic, dynamic> exitData) async {
    try {
      debugPrint('🔄 DatabaseService - Updating journey with exit data: $journeyId');
      debugPrint('🔄 DatabaseService - Exit data: $exitData');
      
      final String exitTime = exitData['exit_time']?.toString() ?? '';
      
      // Use the safe conversion method for coordinates and numeric values
      final double endLat = _toDouble(exitData['end_latitude']);
      final double endLong = _toDouble(exitData['end_longitude']);
      final double distance = _toDouble(exitData['distance']);
      final double fare = _toDouble(exitData['fare']);
      
      debugPrint('🔄 DatabaseService - Converted values: lat=$endLat, long=$endLong, distance=$distance, fare=$fare');
      
      final updateData = {
        'exit_time': exitTime,
        'end_latitude': endLat,
        'end_longitude': endLong,
        'distance': distance,
        'fare': fare,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('journey_history').doc(journeyId).update(updateData);
      debugPrint('✅ DatabaseService - Updated journey $journeyId with exit data');
      
      // Update daily report with the fare
      final journeyDoc = await _firestore.collection('journey_history').doc(journeyId).get();
      if (journeyDoc.exists) {
        final rfid = journeyDoc.data()?['rfid'] ?? '';
        await updateDailyReport(rfid, fare);
      } else {
        debugPrint('⚠️ DatabaseService - Journey document not found after update');
      }
    } catch (e) {
      debugPrint('❌ DatabaseService - ERROR updating journey with exit: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Process a complete journey pair (entry and exit)
  Future<void> processJourneyPair(String rfidId, Map<dynamic, dynamic> entryData, Map<dynamic, dynamic> exitData) async {
    try {
      debugPrint('🔄 DatabaseService - Processing journey pair for RFID: $rfidId');
      
      // Check if this journey already exists in Firestore based on rfid and entry_time
      final entryTimeString = entryData['entry_time']?.toString() ?? '';
      
      final existingJourney = await _firestore
          .collection('journey_history')
          .where('rfid', isEqualTo: rfidId)
          .where('entry_time', isEqualTo: entryTimeString)
          .get();
          
      if (existingJourney.docs.isNotEmpty) {
        // Journey exists, check its status
        final journeyDoc = existingJourney.docs.first;
        final journeyId = journeyDoc.id;
        final status = journeyDoc.data()['status'];
        
        debugPrint('📝 Found existing journey: $journeyId with status: $status');
        
        // Only update if the journey is still active
        if (status == 'active') {
          debugPrint('🔄 Updating existing active journey with exit data');
          await updateJourneyWithExit(journeyId, exitData);
        } else {
          debugPrint('⚠️ Journey already completed, skipping update');
        }
      } else {
        // Journey doesn't exist yet, create it and mark as completed
        debugPrint('🔄 Creating new completed journey from pair');
        
        // First create the journey
        final journeyId = await storeJourneyHistory(rfidId, entryData);
        
        // Then mark it as completed
        await updateJourneyWithExit(journeyId, exitData);
        
        debugPrint('✅ Created and completed journey: $journeyId');
      }
    } catch (e) {
      debugPrint('❌ DatabaseService - ERROR processing journey pair: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Set up the realtime database listeners
  void setupRealtimeDatabaseListener() {
    try {
      debugPrint('🔄 DatabaseService - Setting up realtime database listeners...');
      
      // Clear processed keys when setting up new listeners
      _processedEntryKeys.clear();
      _processedExitKeys.clear();
      
      // Get today's date components for comparison
      final now = DateTime.now();
      final todayYear = now.year;
      final todayMonth = now.month;
      final todayDay = now.day;
      
      debugPrint('🔄 DatabaseService - Setting up listeners for today: $todayYear-$todayMonth-$todayDay');
      
      // Set up listeners for bus entries
      _database.ref('bus_entries').onChildAdded.listen((event) async {
        final eventKey = event.snapshot.key;
        debugPrint('⚡ DatabaseService - Received new bus_entries event: $eventKey');
        
        // Skip if we've already processed this event
        if (eventKey != null && _processedEntryKeys.contains(eventKey)) {
          debugPrint('⚠️ DatabaseService - Already processed entry event: $eventKey, skipping');
          return;
        }
        
        if (event.snapshot.value == null) {
          debugPrint('⚠️ DatabaseService - Event value is null, ignoring');
          return;
        }
        
        if (eventKey != null) {
          _processedEntryKeys.add(eventKey); // Mark this event as processed
        }
        
        try {
          final entryData = event.snapshot.value as Map<dynamic, dynamic>;
          debugPrint('⚡ DatabaseService - Entry data: $entryData');
          final rfidId = entryData['scannedCardId'];
          final entryTimeString = entryData['entry_time']?.toString();
          
          if (rfidId == null || entryTimeString == null) {
            debugPrint('⚠️ DatabaseService - Missing RFID ID or entry time in entry data');
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
                
                debugPrint('🔄 DatabaseService - Parsed date: $year-$month-$day, Today: $todayYear-$todayMonth-$todayDay');
                
                // Check if this entry is from today
                if (year != todayYear || month != todayMonth || day != todayDay) {
                  debugPrint('⚠️ DatabaseService - Ignoring entry from different date: $entryTimeString (not today)');
                  return;
                }
              }
            }
          } catch (e) {
            debugPrint('❌ DatabaseService - Error parsing entry date: $e');
            // Continue processing if date parsing fails
          }
          
          debugPrint('🔄 DatabaseService - Processing new entry for RFID: $rfidId at $entryTimeString');

          // Check for existing journey with this exact entry time
          final existingJourney = await _firestore
              .collection('journey_history')
              .where('rfid', isEqualTo: rfidId)
              .where('entry_time', isEqualTo: entryTimeString)
              .get();
              
          if (existingJourney.docs.isEmpty) {
            // This is a new entry, create a new journey
            await storeJourneyHistory(rfidId, entryData);
            debugPrint('✅ DatabaseService - Created new journey for RFID: $rfidId');
            
            // For debugging: check how many active journeys this RFID now has
            final activeCheck = await _firestore
                .collection('journey_history')
                .where('rfid', isEqualTo: rfidId)
                .where('status', isEqualTo: 'active')
                .get();
            debugPrint('📊 DatabaseService - RFID $rfidId now has ${activeCheck.docs.length} active journeys');
          } else {
            debugPrint('⚠️ DatabaseService - Journey already exists with this entry time, skipping creation');
          }
        } catch (e) {
          debugPrint('❌ DatabaseService - ERROR processing entry: $e');
          debugPrint('❌ Stack trace: ${StackTrace.current}');
        }
      }, onError: (error) {
        debugPrint('❌ DatabaseService - ERROR in bus_entries listener: $error');
      });

      // Set up listeners for bus exits
      _database.ref('bus_exits').onChildAdded.listen((event) async {
        final eventKey = event.snapshot.key;
        debugPrint('⚡ DatabaseService - Received new bus_exits event: $eventKey');
        
        // Skip if we've already processed this event
        if (eventKey != null && _processedExitKeys.contains(eventKey)) {
          debugPrint('⚠️ DatabaseService - Already processed exit event: $eventKey, skipping');
          return;
        }
        
        if (event.snapshot.value == null) {
          debugPrint('⚠️ DatabaseService - Exit event value is null, ignoring');
          return;
        }
        
        if (eventKey != null) {
          _processedExitKeys.add(eventKey); // Mark this event as processed
        }
        
        try {
          final exitData = event.snapshot.value as Map<dynamic, dynamic>;
          debugPrint('⚡ DatabaseService - Exit data: $exitData');
          final rfidId = exitData['scannedCardId'];
          final exitTimeString = exitData['exit_time']?.toString();
          
          if (rfidId == null || exitTimeString == null) {
            debugPrint('⚠️ DatabaseService - Missing RFID ID or exit time in exit data');
            return;
          }
          
          // Parse the exit time to check if it's from today
          try {
            final exitTimeParts = exitTimeString.split(' ');
            if (exitTimeParts.length >= 2) {
              final exitDateParts = exitTimeParts[0].split('-');
              if (exitDateParts.length >= 3) {
                final exitYear = int.tryParse(exitDateParts[0]) ?? 0;
                final exitMonth = int.tryParse(exitDateParts[1]) ?? 0;
                final exitDay = int.tryParse(exitDateParts[2]) ?? 0;
                
                if (exitYear != todayYear || exitMonth != todayMonth || exitDay != todayDay) {
                  debugPrint('⚠️ DatabaseService - Ignoring exit from different date: $exitTimeString (not today)');
                  return;
                }
              }
            }
          } catch (e) {
            debugPrint('❌ DatabaseService - Error parsing exit date: $e');
          }
          
          debugPrint('🔄 DatabaseService - Processing new exit for RFID: $rfidId at $exitTimeString');
          final exitTime = _parseDateTime(exitTimeString);
          
          // Get the corresponding entry from bus_entries
          final entrySnapshot = await _database.ref('bus_entries')
              .orderByChild('scannedCardId')
              .equalTo(rfidId)
              .once();
              
          if (entrySnapshot.snapshot.value != null) {
            final entriesData = entrySnapshot.snapshot.value as Map<dynamic, dynamic>;
            String? latestEntryTime;
            
            // Find the latest entry time for this RFID
            entriesData.forEach((key, value) {
              if (value is Map && value.containsKey('entry_time')) {
                final thisEntryTime = value['entry_time'].toString();
                if (latestEntryTime == null || thisEntryTime.compareTo(latestEntryTime!) > 0) {
                  latestEntryTime = thisEntryTime;
                }
              }
            });
            
            if (latestEntryTime != null) {
              final entryTime = _parseDateTime(latestEntryTime!);
              
              debugPrint('🔄 DatabaseService - Comparing times: Entry=$latestEntryTime, Exit=$exitTimeString');
              
              // Only process the exit if it's AFTER the entry
              if (exitTime.isAfter(entryTime)) {
                debugPrint('✅ DatabaseService - Valid exit: after entry time');
                
                // Find active journey for this RFID
                final activeJourneysQuery = await _firestore
                    .collection('journey_history')
                    .where('rfid', isEqualTo: rfidId)
                    .where('status', isEqualTo: 'active')
                    .get();

                debugPrint('📊 DatabaseService - Found ${activeJourneysQuery.docs.length} active journeys for RFID: $rfidId');
                
                if (activeJourneysQuery.docs.isEmpty) {
                  debugPrint('⚠️ DatabaseService - No active journey found for RFID: $rfidId. Cannot process exit.');
                  return;
                }

                // If there's more than one active journey for this RFID,
                // use the oldest one first (FIFO - first in, first out)
                if (activeJourneysQuery.docs.length > 1) {
                  debugPrint('⚠️ DatabaseService - Multiple active journeys found for RFID: $rfidId. Using oldest one.');
                  
                  var sortedJourneys = activeJourneysQuery.docs.toList()
                    ..sort((a, b) {
                      String aTime = a.data()['entry_time'] ?? '';
                      String bTime = b.data()['entry_time'] ?? '';
                      return aTime.compareTo(bTime); // Oldest first
                    });
                  
                  await updateJourneyWithExit(sortedJourneys.first.id, exitData);
                  debugPrint('✅ DatabaseService - Updated oldest active journey with exit data for RFID: $rfidId');
                } else {
                  // Normal case - just one active journey for this RFID
                  await updateJourneyWithExit(activeJourneysQuery.docs.first.id, exitData);
                  debugPrint('✅ DatabaseService - Updated active journey with exit data for RFID: $rfidId');
                }
              } else {
                debugPrint('⚠️ DatabaseService - Invalid exit: timestamp is BEFORE entry time. Ignoring.');
              }
            } else {
              debugPrint('⚠️ DatabaseService - Could not find entry time for RFID: $rfidId');
            }
          } else {
            debugPrint('⚠️ DatabaseService - No matching entry found for exit with RFID: $rfidId');
          }
        } catch (e) {
          debugPrint('❌ DatabaseService - ERROR processing exit: $e');
          debugPrint('❌ Stack trace: ${StackTrace.current}');
        }
      }, onError: (error) {
        debugPrint('❌ DatabaseService - ERROR in bus_exits listener: $error');
      });

      debugPrint('✅ DatabaseService - Realtime database listeners setup complete');
    } catch (e) {
      debugPrint('❌ DatabaseService - ERROR setting up realtime listeners: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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
//  Stream<List<Journey>> getTodaysJourneys() {
//   final today = CustomDateUtils.getTodayFormattedDate();
//   try {
//     debugPrint('Fetching journeys for date: $today');
//     return _firestore
//         .collection('journey_history')
//         .where('date', isEqualTo: today)
//         .snapshots()
//         .map((snapshot) {
//           debugPrint('Received ${snapshot.docs.length} journeys');
//           // Sort the journeys in memory instead of in the query
//           final journeys = <Journey>[];
          
//           for (var doc in snapshot.docs) {
//             try {
//               journeys.add(Journey.fromMap(doc.data(), documentId: doc.id));
//             } catch (e) {
//               debugPrint('Error parsing journey document ${doc.id}: $e');
//               debugPrint('Document data: ${doc.data()}');
//               // Skip this document and continue with others
//             }
//           }
          
//           journeys.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//           return journeys;
//         })
//         .handleError((error) {
//           debugPrint('Error in getTodaysJourneys: $error');
//           throw error;
//         });
//   } catch (e) {
//     debugPrint('Exception in getTodaysJourneys: $e');
//     rethrow;
//   }
// }

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
//           final updatedRfids = [...currentReport.rfidsScanned];
//           if (!updatedRfids.contains(rfid)) {
//             updatedRfids.add(rfid);
//           }
          
//           final updatedReport = currentReport.copyWith(
//             totalAmount: currentReport.totalAmount + fare,
//             totalJourneys: currentReport.totalJourneys + 1,
//             rfidsScanned: updatedRfids,
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

//   // New function to ensure daily report exists
//   Future<void> ensureDailyReportExists() async {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     final reportRef = _firestore.collection('analytics_and_report').doc(today);
    
//     final doc = await reportRef.get();
//     if (!doc.exists) {
//       debugPrint('Creating initial daily report for $today');
//       final initialReport = DailyReport(
//         date: today,
//         totalAmount: 0,
//         totalJourneys: 0,
//         rfidsScanned: [],
//         timestamp: DateTime.now(),
//       );
//       await reportRef.set(initialReport.toMap());
//     }
//   }

//   // New function to regenerate the report from existing journey data
//   Future<void> regenerateDailyReport() async {
//     final today = CustomDateUtils.getTodayFormattedDate();
//     try {
//       debugPrint('Regenerating report from journey data for $today');
      
//       // Get all of today's journeys
//       final journeysSnapshot = await _firestore
//         .collection('journey_history')
//         .where('date', isEqualTo: today)
//         .get();
        
//       // Calculate totals
//       double totalAmount = 0;
//       int totalJourneys = 0;
//       Set<String> uniqueRfids = {};
      
//       for (var doc in journeysSnapshot.docs) {
//         Journey journey = Journey.fromMap(doc.data());
        
//         // Only count completed journeys with valid fares in the total amount
//         if (journey.status == 'completed' && journey.fare != null) {
//           totalAmount += journey.fare!;
//         }
        
//         // Count all journeys
//         totalJourneys++;
        
//         // Add RFID to unique set
//         if (journey.rfid != null && journey.rfid!.isNotEmpty) {
//           uniqueRfids.add(journey.rfid!);
//         }
//       }
      
//       // Create or update the report
//       final reportRef = _firestore.collection('analytics_and_report').doc(today);
//       final newReport = DailyReport(
//         date: today,
//         totalAmount: totalAmount,
//         totalJourneys: totalJourneys,
//         rfidsScanned: uniqueRfids.toList(),
//         timestamp: DateTime.now(),
//       );
      
//       await reportRef.set(newReport.toMap());
//       debugPrint('Successfully regenerated report: ${totalJourneys} journeys, ${uniqueRfids.length} RFIDs, Rs${totalAmount}');
      
//     } catch (e) {
//       debugPrint('Error regenerating report: $e');
//       rethrow;
//     }
//   }

//   // Function to store new journey history
//   Future<void> storeJourneyHistory(String rfid, Map<dynamic, dynamic> entryData, Map<dynamic, dynamic>? exitData) async {
//     try {
//       final today = CustomDateUtils.getTodayFormattedDate();
//       final entryTime = entryData['entry_time']?.toString();
//       final startLat = entryData['latitude']?.toString();
//       final startLng = entryData['longitude']?.toString();
      
//       // Create journey document
//       final journey = Journey(
//         rfid: rfid,
//         entryTime: entryTime,
//         exitTime: exitData?['exit_time']?.toString(),
//         startLatitude: startLat,
//         startLongitude: startLng,
//         endLatitude: exitData?['latitude']?.toString(),
//         endLongitude: exitData?['longitude']?.toString(),
//         status: exitData != null ? 'completed' : 'active',
//         date: today,
//         timestamp: DateTime.now(),
//       );
      
//       // Store in Firestore
//       await _firestore.collection('journey_history').add(journey.toMap());
      
//       // Initialize report entry with zero fare (fare will be added on exit)
//       await updateDailyReport(rfid, 0);
      
//     } catch (e) {
//       debugPrint('Error storing journey history: $e');
//       rethrow;
//     }
//   }

//   // Function to update journey with exit data
//   Future<void> updateJourneyWithExit(String docId, Map<dynamic, dynamic> exitData) async {
//     try {
//       final journeyDoc = await _firestore.collection('journey_history').doc(docId).get();
//       if (!journeyDoc.exists) return;
      
//       final journey = Journey.fromMap(journeyDoc.data()!);
//       final endLat = exitData['latitude']?.toString();
//       final endLng = exitData['longitude']?.toString();
//       final exitTime = exitData['exit_time']?.toString();
      
//       // Calculate distance and fare
//       double distance = 0;
//       // Implementation of distance calculation would go here
//       // For example, using geolocator package or similar
      
//       // Mock distance calculation (replace with actual implementation)
//       distance = 5.0; // Example: 5 kilometers
      
//       // Calculate fare (example: Rs 10 per km)
//       double fare = distance * 10;
      
//       // Update journey
//       final updatedJourney = journey.copyWith(
//         exitTime: exitTime,
//         endLatitude: endLat,
//         endLongitude: endLng,
//         status: 'completed',
//         distance: distance,
//         fare: fare,
//       );
      
//       // Update document
//       await _firestore.collection('journey_history').doc(docId).update(updatedJourney.toMap());
      
//       // Update daily report with the calculated fare
//       await updateDailyReport(journey.rfid!, fare);
      
//     } catch (e) {
//       debugPrint('Error updating journey with exit: $e');
//       rethrow;
//     }
//   }

//   void setupRealtimeDatabaseListener() {
//     try {
//       // Get today's date components for comparison
//       final now = DateTime.now();
//       final todayYear = now.year;
//       final todayMonth = now.month;
//       final todayDay = now.day;
      
//       debugPrint('Setting up listeners for today: ${now.year}-${now.month}-${now.day}');
      
//       // Listen for new entries
//       _database.ref('bus_entries').onChildAdded.listen((event) async {
//         if (event.snapshot.value == null) return;
        
//         final entryData = event.snapshot.value as Map<dynamic, dynamic>;
//         final rfidId = entryData['scannedCardId'];
//         final entryTimeString = entryData['entry_time']?.toString();
        
//         if (rfidId == null || entryTimeString == null) {
//           debugPrint('Missing RFID ID or entry time in entry data');
//           return;
//         }
        
//         // Parse the entry time to check if it's from today
//         try {
//           // Handle the format "2025-3-1 16:13:13"
//           final parts = entryTimeString.split(' ');
//           if (parts.length >= 2) {
//             final dateParts = parts[0].split('-');
//             if (dateParts.length >= 3) {
//               final year = int.tryParse(dateParts[0]) ?? 0;
//               final month = int.tryParse(dateParts[1]) ?? 0;
//               final day = int.tryParse(dateParts[2]) ?? 0;
              
//               // Check if this entry is from today
//               if (year != todayYear || month != todayMonth || day != todayDay) {
//                 debugPrint('Ignoring entry from different date: $entryTimeString (not today)');
//                 return;
//               }
//             }
//           }
//         } catch (e) {
//           debugPrint('Error parsing entry date: $e');
//           // Continue processing if date parsing fails
//         }
        
//         debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

//         // Check if the journey already exists in Firestore
//         try {
//           final existingJourney = await _firestore
//               .collection('journey_history')
//               .where('rfid', isEqualTo: rfidId)
//               .where('entry_time', isEqualTo: entryTimeString)
//               .get();

//           if (existingJourney.docs.isEmpty) {
//             await storeJourneyHistory(rfidId, entryData, null);
//             debugPrint('Stored new journey for RFID: $rfidId');
//           } else {
//             debugPrint('Journey already exists for RFID: $rfidId');
//           }
//         } catch (e) {
//           debugPrint('Error checking or storing journey: $e');
//         }
//       }, onError: (error) {
//         debugPrint('Error in bus_entries listener: $error');
//       });

//       // Listen for exits with similar date validation
//       _database.ref('bus_exits').onChildAdded.listen((event) async {
//         if (event.snapshot.value == null) return;
        
//         final exitData = event.snapshot.value as Map<dynamic, dynamic>;
//         final rfidId = exitData['scannedCardId'];
//         final exitTimeString = exitData['exit_time']?.toString();
        
//         if (rfidId == null || exitTimeString == null) {
//           debugPrint('Missing RFID ID or exit time in exit data');
//           return;
//         }
        
//         // Parse the exit time to check if it's from today
//         try {
//           // Handle the format "2025-3-1 16:14:37"
//           final parts = exitTimeString.split(' ');
//           if (parts.length >= 2) {
//             final dateParts = parts[0].split('-');
//             if (dateParts.length >= 3) {
//               final year = int.tryParse(dateParts[0]) ?? 0;
//               final month = int.tryParse(dateParts[1]) ?? 0;
//               final day = int.tryParse(dateParts[2]) ?? 0;
              
//               // Check if this exit is from today
//               if (year != todayYear || month != todayMonth || day != todayDay) {
//                 debugPrint('Ignoring exit from different date: $exitTimeString (not today)');
//                 return;
//               }
//             }
//           }
//         } catch (e) {
//           debugPrint('Error parsing exit date: $e');
//           // Continue processing if date parsing fails
//         }
        
//         debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

//         try {
//           // Find active journey for this RFID
//           final activeJourney = await _firestore
//               .collection('journey_history')
//               .where('rfid', isEqualTo: rfidId)
//               .where('status', isEqualTo: 'active')
//               .get();

//           if (activeJourney.docs.isNotEmpty) {
//             await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//             debugPrint('Updated journey with exit data for RFID: $rfidId');
//           } else {
//             debugPrint('No active journey found for RFID: $rfidId');
//           }
//         } catch (e) {
//           debugPrint('Error finding or updating journey: $e');
//         }
//       }, onError: (error) {
//         debugPrint('Error in bus_exits listener: $error');
//       });

//       debugPrint('Realtime database listeners setup complete');
//     } catch (e) {
//       debugPrint('Error setting up realtime listeners: $e');
//     }
//   }

//   // Add this method to the DatabaseService class
// Future<void> repairJourneyData() async {
//   final today = CustomDateUtils.getTodayFormattedDate();
//   try {
//     debugPrint('Repairing journey data for date: $today');
    
//     // Get all of today's journeys
//     final journeysSnapshot = await _firestore
//       .collection('journey_history')
//       .where('date', isEqualTo: today)
//       .get();
      
//     int repaired = 0;
    
//     // Check each journey and repair if needed
//     for (var doc in journeysSnapshot.docs) {
//       try {
//         final data = doc.data();
//         bool needsRepair = false;
//         Map<String, dynamic> fixedData = Map<String, dynamic>.from(data);
        
//         // Ensure string fields are actually strings
//         ['rfid', 'entry_time', 'exit_time', 'start_latitude', 'start_longitude', 
//          'end_latitude', 'end_longitude', 'status', 'date'].forEach((field) {
//           if (data.containsKey(field) && data[field] != null && data[field] is! String) {
//             fixedData[field] = data[field].toString();
//             needsRepair = true;
//           }
//         });
        
//         // Ensure number fields are doubles
//         ['distance', 'fare', 'remaining_balance'].forEach((field) {
//           if (data.containsKey(field) && data[field] != null) {
//             if (data[field] is int) {
//               fixedData[field] = data[field].toDouble();
//               needsRepair = true;
//             } else if (data[field] is String) {
//               final parsedValue = double.tryParse(data[field]);
//               if (parsedValue != null) {
//                 fixedData[field] = parsedValue;
//                 needsRepair = true;
//               }
//             }
//           }
//         });
        
//         // Update document if repairs were needed
//         if (needsRepair) {
//           await _firestore.collection('journey_history').doc(doc.id).update(fixedData);
//           repaired++;
//         }
//       } catch (e) {
//         debugPrint('Error repairing journey ${doc.id}: $e');
//       }
//     }
    
//     debugPrint('Repaired $repaired journey documents');
    
//   } catch (e) {
//     debugPrint('Error in repairJourneyData: $e');
//     rethrow;
//   }
// }

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
//     // Get today's date components for comparison
//     final now = DateTime.now();
//     final todayYear = now.year;
//     final todayMonth = now.month;
//     final todayDay = now.day;
    
//     debugPrint('Setting up listeners for today: ${now.year}-${now.month}-${now.day}');
    
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
      
//       // Parse the entry time to check if it's from today
//       try {
//         // Handle the format "2025-3-1 16:13:13"
//         final parts = entryTimeString.split(' ');
//         if (parts.length >= 2) {
//           final dateParts = parts[0].split('-');
//           if (dateParts.length >= 3) {
//             final year = int.tryParse(dateParts[0]) ?? 0;
//             final month = int.tryParse(dateParts[1]) ?? 0;
//             final day = int.tryParse(dateParts[2]) ?? 0;
            
//             // Check if this entry is from today
//             if (year != todayYear || month != todayMonth || day != todayDay) {
//               debugPrint('Ignoring entry from different date: $entryTimeString (not today)');
//               return;
//             }
//           }
//         }
//       } catch (e) {
//         debugPrint('Error parsing entry date: $e');
//         // Continue processing if date parsing fails
//       }
      
//       debugPrint('Processing new entry for RFID: $rfidId at $entryTimeString');

//       // Check if the journey already exists in Firestore
//       try {
//         final existingJourney = await _firestore
//             .collection('journey_history')
//             .where('rfid', isEqualTo: rfidId)
//             .where('entry_time', isEqualTo: entryTimeString)
//             .get();

//         if (existingJourney.docs.isEmpty) {
//           await storeJourneyHistory(rfidId, entryData, null);
//           debugPrint('Stored new journey for RFID: $rfidId');
//         } else {
//           debugPrint('Journey already exists for RFID: $rfidId');
//         }
//       } catch (e) {
//         debugPrint('Error checking or storing journey: $e');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_entries listener: $error');
//     });

//     // Listen for exits with similar date validation
//     _database.ref('bus_exits').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;
      
//       final exitData = event.snapshot.value as Map<dynamic, dynamic>;
//       final rfidId = exitData['scannedCardId'];
//       final exitTimeString = exitData['exit_time']?.toString();
      
//       if (rfidId == null || exitTimeString == null) {
//         debugPrint('Missing RFID ID or exit time in exit data');
//         return;
//       }
      
//       // Parse the exit time to check if it's from today
//       try {
//         // Handle the format "2025-3-1 16:14:37"
//         final parts = exitTimeString.split(' ');
//         if (parts.length >= 2) {
//           final dateParts = parts[0].split('-');
//           if (dateParts.length >= 3) {
//             final year = int.tryParse(dateParts[0]) ?? 0;
//             final month = int.tryParse(dateParts[1]) ?? 0;
//             final day = int.tryParse(dateParts[2]) ?? 0;
            
//             // Check if this exit is from today
//             if (year != todayYear || month != todayMonth || day != todayDay) {
//               debugPrint('Ignoring exit from different date: $exitTimeString (not today)');
//               return;
//             }
//           }
//         }
//       } catch (e) {
//         debugPrint('Error parsing exit date: $e');
//         // Continue processing if date parsing fails
//       }
      
//       debugPrint('Processing new exit for RFID: $rfidId at $exitTimeString');

//       try {
//         // Find active journey for this RFID
//         final activeJourney = await _firestore
//             .collection('journey_history')
//             .where('rfid', isEqualTo: rfidId)
//             .where('status', isEqualTo: 'active')
//             .get();

//         if (activeJourney.docs.isNotEmpty) {
//           await updateJourneyWithExit(activeJourney.docs.first.id, exitData);
//           debugPrint('Updated journey with exit data for RFID: $rfidId');
//         } else {
//           debugPrint('No active journey found for RFID: $rfidId');
//         }
//       } catch (e) {
//         debugPrint('Error finding or updating journey: $e');
//       }
//     }, onError: (error) {
//       debugPrint('Error in bus_exits listener: $error');
//     });

//     debugPrint('Realtime database listeners setup complete');
//   } catch (e) {
//     debugPrint('Error setting up realtime listeners: $e');
//   }
// }




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