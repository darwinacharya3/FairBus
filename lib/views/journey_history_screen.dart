import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:major_project/widgets/journey_widget/journey_model.dart';
import 'package:major_project/widgets/journey_widget/statistics_service.dart';
import 'package:major_project/widgets/journey_widget/custom_widgets.dart';

class JourneyHistoryScreen extends StatefulWidget {
  const JourneyHistoryScreen({super.key});

  @override
  State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
}

class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StatisticsService _statisticsService = StatisticsService(FirebaseFirestore.instance);
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _dailyStatistics;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadDailyStatistics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDailyStatistics() async {
    final stats = await _statisticsService.getDailyStatistics(DateTime.now());
    setState(() {
      _dailyStatistics = stats;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

   Stream<QuerySnapshot> _getFilteredStream() {
    Query query = _firestore.collection('journey_history');
    
    if (_startDate != null && _endDate != null) {
      query = query.where('timestamp', 
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
        isLessThanOrEqualTo: Timestamp.fromDate(_endDate!.add(const Duration(days: 1))),
      );
    }

    if (_searchQuery.isNotEmpty) {
      String searchEnd = _searchQuery + '\uf8ff';
      query = query.where('rfid', isGreaterThanOrEqualTo: _searchQuery)
                  .where('rfid', isLessThan: searchEnd);
    }
    
    return query.orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots();
  }

  Future<void> _generateMonthlyReport() async {
    try {
      final now = DateTime.now();
      final report = await _statisticsService.getMonthlyReport(now);
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Monthly Report - ${_getMonthName(now.month)}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReportItem('Total Collection', 'Rs ${report['totalMonthlyFare']?.toStringAsFixed(2)}'),
                _buildReportItem('Total Distance', '${report['totalMonthlyDistance']?.toStringAsFixed(2)} km'),
                _buildReportItem('Total Journeys', '${report['totalJourneys']}'),
                _buildReportItem('Average Daily Collection', 'Rs ${report['averageDailyFare']?.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement export functionality
                Navigator.pop(context);
              },
              child: const Text('Export'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(Journey journey) {
    final bool isCompleted = journey.status == 'completed';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          isCompleted ? Icons.done_all : Icons.directions_bus,
          color: isCompleted ? Colors.green : Colors.blue,
        ),
        title: Text('RFID: ${journey.rfid}'),
        subtitle: Text(
          isCompleted ? 'Completed' : 'Active Journey',
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.blue,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Entry Time', journey.entryTime),
                if (isCompleted) ...[
                  _buildInfoRow('Exit Time', journey.exitTime ?? 'N/A'),
                  _buildInfoRow('Distance', '${journey.distance?.toStringAsFixed(2)} km'),
                  _buildInfoRow('Fare', 'Rs ${journey.fare?.toStringAsFixed(2)}'),
                  _buildInfoRow('Balance', 'Rs ${journey.remainingBalance?.toStringAsFixed(2)}'),
                ],
                const SizedBox(height: 8),
                Text(
                  'Route Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                Text('Start: ${journey.startLatitude}, ${journey.startLongitude}'),
                if (isCompleted)
                  Text('End: ${journey.endLatitude}, ${journey.endLongitude}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey History'),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _generateMonthlyReport,
            tooltip: 'Generate Monthly Report',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_dailyStatistics != null)
            StatisticsCard(statistics: _dailyStatistics!),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by RFID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          CustomDateRangePicker(
            startDate: _startDate,
            endDate: _endDate,
            onDateSelected: (DateTimeRange range) {
              setState(() {
                _startDate = range.start;
                _endDate = range.end;
              });
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final journeys = snapshot.data!.docs
                    .map((doc) => Journey.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                if (journeys.isEmpty) {
                  return const Center(
                    child: Text('No journeys found'),
                  );
                }

                return ListView.builder(
                  itemCount: journeys.length,
                  itemBuilder: (context, index) {
                    return _buildJourneyCard(journeys[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String _searchQuery = '';
  

//   @override
//   void initState() {
//     super.initState();
//     _setupRealtimeDatabaseListener();
//   }

//   void _setupRealtimeDatabaseListener() {
//     // Listen for new entries
//     _database.ref('bus_entries').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;

//       final rfidId = event.snapshot.key!;
//       final entryData = event.snapshot.value as Map<dynamic, dynamic>;

//       // Check if journey already exists in Firestore
//       final existingJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('entry_time', isEqualTo: entryData['entry_time'])
//           .get();

//       if (existingJourney.docs.isEmpty) {
//         await _storeJourneyHistory(rfidId, entryData, null);
//       }
//     });

//     // Listen for exits and update existing journeys
//     _database.ref('bus_exits').onChildAdded.listen((event) async {
//       if (event.snapshot.value == null) return;

//       final rfidId = event.snapshot.key!;
//       final exitData = event.snapshot.value as Map<dynamic, dynamic>;

//       // Find the active journey for this RFID
//       final activeJourney = await _firestore
//           .collection('journey_history')
//           .where('rfid', isEqualTo: rfidId)
//           .where('status', isEqualTo: 'active')
//           .get();

//       if (activeJourney.docs.isNotEmpty) {
//         final journeyDoc = activeJourney.docs.first;
//         await _updateJourneyWithExit(journeyDoc.id, exitData);
//       }
//     });
//   }

//   Future<void> _storeJourneyHistory(
//     String rfidId,
//     Map<dynamic, dynamic> entryData,
//     Map<dynamic, dynamic>? exitData,
//   ) async {
//     try {
//       await _firestore.collection('journey_history').add({
//         'rfid': rfidId,
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
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       debugPrint('Error storing journey: $e');
//     }
//   }

//   Future<void> _updateJourneyWithExit(
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
//     } catch (e) {
//       debugPrint('Error updating journey: $e');
//     }
//   }
  

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey History'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Column(
//         children: [
//           // Search and Filter Section
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: 'Search by RFID',
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         _searchQuery = value;
//                       });
//                     },
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.filter_list),
//                   onPressed: () {
//                     // Show filter options
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // Journey History List
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _getFilteredStream(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final journeys = snapshot.data!.docs;
                
//                 if (journeys.isEmpty) {
//                   return const Center(
//                     child: Text('No journeys found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: journeys.length,
//                   itemBuilder: (context, index) {
//                     final journey = journeys[index].data() as Map<String, dynamic>;
//                     return _buildJourneyCard(journey);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Stream<QuerySnapshot> _getFilteredStream() {
//   //   var query = _firestore.collection('journey_history')
//   //       .orderBy('timestamp', descending: true);
    
//   //   if (_searchQuery.isNotEmpty) {
//   //     query = query.where('rfid', isEqualTo: _searchQuery);
//   //   }
    
//   //   return query.snapshots();
//   // }

//    Stream<QuerySnapshot> _getFilteredStream() {
//     var query = _firestore.collection('journey_history')
//         .orderBy('timestamp', descending: true);
    
//     if (_searchQuery.isNotEmpty) {
//       // Create a range for RFID search
//       String searchEnd = _searchQuery + '\uf8ff';
//       query = query.where('rfid', isGreaterThanOrEqualTo: _searchQuery)
//                   .where('rfid', isLessThan: searchEnd);
//     }
    
//     return query.limit(50).snapshots(); // Limit results for better performance
//   }

 
//   Widget _buildJourneyCard(Map<String, dynamic> journey) {
//     final bool isCompleted = journey['status'] == 'completed';
//     final String entryTime = journey['entry_time'] ?? 'N/A';
//     final String exitTime = journey['exit_time'] ?? 'N/A';
    
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: ExpansionTile(
//         leading: Icon(
//           isCompleted ? Icons.done_all : Icons.directions_bus,
//           color: isCompleted ? Colors.green : Colors.blue,
//         ),
//         title: Text('RFID: ${journey['rfid']}'),
//         subtitle: Text(
//           isCompleted ? 'Completed' : 'Active Journey',
//           style: TextStyle(
//             color: isCompleted ? Colors.green : Colors.blue,
//           ),
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildInfoRow('Entry Time', entryTime),
//                 if (isCompleted) ...[
//                   _buildInfoRow('Exit Time', exitTime),
//                   _buildInfoRow('Distance', '${journey['distance']} km'),
//                   _buildInfoRow('Fare', 'Rs ${journey['fare']}'),
//                   _buildInfoRow('Balance', 'Rs ${journey['remaining_balance']}'),
//                 ],
//                 if (journey['start_latitude'] != null) ...[
//                   const SizedBox(height: 8),
//                   Text(
//                     'Route Details',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   Text('Start: ${journey['start_latitude']}, ${journey['start_longitude']}'),
//                   if (isCompleted)
//                     Text('End: ${journey['end_latitude']}, ${journey['end_longitude']}'),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(value),
//         ],
//       ),
//     );
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';


// class JourneyHistoryScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   JourneyHistoryScreen({super.key});

//   // Store journey in Firestore when detected in Realtime Database
//   Future<void> _storeJourneyHistory(String rfidId, Map<dynamic, dynamic> entryData, Map<dynamic, dynamic>? exitData) async {
//     try {
//       await _firestore.collection('journey_history').add({
//         'rfid': rfidId,
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
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('Error storing journey: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey History'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Column(
//         children: [
//           // Listen to Realtime DB and store to Firestore
//           StreamBuilder(
//             stream: _database.ref('bus_entries').onValue,
//             builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//               if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
//                 final Map<dynamic, dynamic> entries = 
//                   snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                
//                 entries.forEach((rfidId, entryData) async {
//                   // Get exit data if exists
//                   DataSnapshot exitSnapshot = 
//                     await _database.ref('bus_exits/$rfidId').get();
                  
//                   // Store in Firestore
//                   _storeJourneyHistory(
//                     rfidId, 
//                     entryData, 
//                     exitSnapshot.value as Map<dynamic, dynamic>?
//                   );
//                 });
//               }
//               return const SizedBox.shrink(); // Hidden listener
//             },
//           ),

//           // Search and Filter Section
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: 'Search by RFID',
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       // Implement RFID search
//                     },
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.filter_list),
//                   onPressed: () {
//                     // Show filter options
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // Journey History List
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('journey_history')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final journeys = snapshot.data!.docs;

//                 return ListView.builder(
//                   itemCount: journeys.length,
//                   itemBuilder: (context, index) {
//                     final journey = journeys[index].data() as Map<String, dynamic>;
//                     return _buildJourneyCard(journey);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildJourneyCard(Map<String, dynamic> journey) {
//     final bool isCompleted = journey['status'] == 'completed';
//     final String entryTime = journey['entry_time'] ?? 'N/A';
//     final String exitTime = journey['exit_time'] ?? 'N/A';
    
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: ExpansionTile(
//         leading: Icon(
//           isCompleted ? Icons.done_all : Icons.directions_bus,
//           color: isCompleted ? Colors.green : Colors.blue,
//         ),
//         title: Text('RFID: ${journey['rfid']}'),
//         subtitle: Text(
//           isCompleted ? 'Completed' : 'Active Journey',
//           style: TextStyle(
//             color: isCompleted ? Colors.green : Colors.blue,
//           ),
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildInfoRow('Entry Time', entryTime),
//                 if (isCompleted) ...[
//                   _buildInfoRow('Exit Time', exitTime),
//                   _buildInfoRow('Distance', '${journey['distance']} km'),
//                   _buildInfoRow('Fare', 'Rs ${journey['fare']}'),
//                   _buildInfoRow('Balance', 'Rs ${journey['remaining_balance']}'),
//                 ],
//                 if (journey['start_latitude'] != 0) ...[
//                   const SizedBox(height: 8),
//                   Text(
//                     'Route Details',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   Text('Start: ${journey['start_latitude']}, ${journey['start_longitude']}'),
//                   if (isCompleted)
//                     Text('End: ${journey['end_latitude']}, ${journey['end_longitude']}'),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(value),
//         ],
//       ),
//     );
//   }
// }