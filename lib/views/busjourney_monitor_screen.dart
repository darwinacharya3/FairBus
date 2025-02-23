// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class BusJourneyMonitorScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
  
//   BusJourneyMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Live Journey Monitor'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder(
//         stream: _database.ref('bus_entries').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final Map<dynamic, dynamic>? entries = 
//             snapshot.data?.snapshot.value as Map?;
          
//           if (entries == null || entries.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.directions_bus_outlined, 
//                     size: 64, 
//                     color: Colors.grey
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'No Active Journeys',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final List<MapEntry<dynamic, dynamic>> sortedEntries = 
//             entries.entries.toList()
//               ..sort((a, b) {
//                 final timeA = a.value['entry_time'] as String;
//                 final timeB = b.value['entry_time'] as String;
//                 return timeB.compareTo(timeA);
//               });

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: sortedEntries.length,
//             itemBuilder: (context, index) {
//               final entry = sortedEntries[index];
//               return _buildJourneyCard(entry.key, entry.value);
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _database.ref().get();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: StreamBuilder(
//         stream: _database.ref('bus_exits/$rfidId').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           final exitData = snapshot.data?.snapshot.value as Map?;
          
//           return Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: exitData == null ? Colors.blue.shade200 : Colors.green.shade200,
//                 width: 1,
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header Row with Status
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: exitData == null 
//                             ? Colors.blue.shade50 
//                             : Colors.green.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           exitData == null ? Icons.directions_bus : Icons.done_all,
//                           color: exitData == null ? Colors.blue : Colors.green,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'RFID: $rfidId',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: exitData == null 
//                                   ? Colors.blue.shade50 
//                                   : Colors.green.shade50,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 exitData == null ? 'In Progress' : 'Completed',
//                                 style: TextStyle(
//                                   color: exitData == null 
//                                     ? Colors.blue.shade700 
//                                     : Colors.green.shade700,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   // Journey Details
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, size: 14),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Entry: ${journeyData['entry_time']}',
//                           style: const TextStyle(fontSize: 13),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (exitData != null) ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.logout, size: 14),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Exit: ${exitData['exit_time']}',
//                             style: const TextStyle(fontSize: 13),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.route, size: 14),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Distance: ${exitData['distance']} km',
//                             style: const TextStyle(fontSize: 13),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// // import 'package:get/get.dart';
// // import 'package:intl/intl.dart';

// class BusJourneyMonitorScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
  
//   BusJourneyMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Journey Monitor'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Column(
//         children: [
//           // Stats Cards
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildStatsCard(
//                     'Active Journeys',
//                     StreamBuilder(
//                       stream: _database.ref('bus_entries').onValue,
//                       builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                         if (!snapshot.hasData) return const Text('...');
//                         final Map<dynamic, dynamic>? entries = 
//                           snapshot.data?.snapshot.value as Map?;
//                         return Text(
//                           '${entries?.length ?? 0}',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         );
//                       },
//                     ),
//                     Icons.directions_bus,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatsCard(
//                     'Today\'s Revenue',
//                     StreamBuilder(
//                       stream: _database.ref('bus_exits').onValue,
//                       builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                         if (!snapshot.hasData) return const Text('...');
//                         final Map<dynamic, dynamic>? exits = 
//                           snapshot.data?.snapshot.value as Map?;
//                         double totalRevenue = 0;
//                         exits?.forEach((key, value) {
//                           if (value['exit_time'].toString().startsWith('2025-2-9')) {
//                             totalRevenue += (value['fare'] ?? 0).toDouble();
//                           }
//                         });
//                         return Text(
//                           'Rs ${totalRevenue.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         );
//                       },
//                     ),
//                     Icons.attach_money,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Real-time Journey List
//           Expanded(
//             child: StreamBuilder(
//               stream: _database.ref('bus_entries').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final Map<dynamic, dynamic>? entries = 
//                   snapshot.data?.snapshot.value as Map?;
//                 if (entries == null) {
//                   return const Center(child: Text('No active journeys'));
//                 }

//                 return ListView.builder(
//                   itemCount: entries.length,
//                   itemBuilder: (context, index) {
//                     final entry = entries.entries.elementAt(index);
//                     return _buildJourneyCard(entry.key, entry.value);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Refresh data
//           _database.ref().get();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildStatsCard(String title, Widget value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: Colors.green[600], size: 24),
//           const SizedBox(height: 8),
//           value,
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: StreamBuilder(
//         stream: _database.ref('bus_exits/$rfidId').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           final exitData = snapshot.data?.snapshot.value as Map?;
          
//           return ListTile(
//             leading: Icon(
//               exitData == null ? Icons.directions_bus : Icons.done_all,
//               color: exitData == null ? Colors.blue : Colors.green,
//             ),
//             title: Text('RFID: $rfidId'),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Entry: ${journeyData['entry_time']}'),
//                 if (exitData != null) ...[
//                   Text('Exit: ${exitData['exit_time']}'),
//                   Text('Fare: Rs ${exitData['fare']}'),
//                   Text('Distance: ${exitData['distance']} km'),
//                 ],
//               ],
//             ),
//             trailing: exitData == null 
//               ? const Text('In Progress', style: TextStyle(color: Colors.blue))
//               : Text('Completed', style: TextStyle(color: Colors.green[600])),
//           );
//         },
//       ),
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// // import 'package:get/get.dart';
// // import 'package:intl/intl.dart';

// class BusJourneyMonitorScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
  
//   BusJourneyMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Journey Monitor'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Column(
//         children: [
//           // Stats Cards
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildStatsCard(
//                     'Active Journeys',
//                     StreamBuilder(
//                       stream: _database.ref('bus_entries').onValue,
//                       builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                         if (!snapshot.hasData) return const Text('...');
//                         final Map<dynamic, dynamic>? entries = 
//                           snapshot.data?.snapshot.value as Map?;
//                         return Text(
//                           '${entries?.length ?? 0}',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         );
//                       },
//                     ),
//                     Icons.directions_bus,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatsCard(
//                     'Today\'s Revenue',
//                     StreamBuilder(
//                       stream: _database.ref('bus_exits').onValue,
//                       builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                         if (!snapshot.hasData) return const Text('...');
//                         final Map<dynamic, dynamic>? exits = 
//                           snapshot.data?.snapshot.value as Map?;
//                         double totalRevenue = 0;
//                         exits?.forEach((key, value) {
//                           if (value['exit_time'].toString().startsWith('2025-2-9')) {
//                             totalRevenue += (value['fare'] ?? 0).toDouble();
//                           }
//                         });
//                         return Text(
//                           'Rs ${totalRevenue.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         );
//                       },
//                     ),
//                     Icons.attach_money,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Real-time Journey List
//           Expanded(
//             child: StreamBuilder(
//               stream: _database.ref('bus_entries').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final Map<dynamic, dynamic>? entries = 
//                   snapshot.data?.snapshot.value as Map?;
//                 if (entries == null) {
//                   return const Center(child: Text('No active journeys'));
//                 }

//                 return ListView.builder(
//                   itemCount: entries.length,
//                   itemBuilder: (context, index) {
//                     final entry = entries.entries.elementAt(index);
//                     return _buildJourneyCard(entry.key, entry.value);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Refresh data
//           _database.ref().get();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildStatsCard(String title, Widget value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: Colors.green[600], size: 24),
//           const SizedBox(height: 8),
//           value,
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: StreamBuilder(
//         stream: _database.ref('bus_exits/$rfidId').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           final exitData = snapshot.data?.snapshot.value as Map?;
          
//           return ListTile(
//             leading: Icon(
//               exitData == null ? Icons.directions_bus : Icons.done_all,
//               color: exitData == null ? Colors.blue : Colors.green,
//             ),
//             title: Text('RFID: $rfidId'),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Entry: ${journeyData['entry_time']}'),
//                 if (exitData != null) ...[
//                   Text('Exit: ${exitData['exit_time']}'),
//                   Text('Fare: Rs ${exitData['fare']}'),
//                   Text('Distance: ${exitData['distance']} km'),
//                 ],
//               ],
//             ),
//             trailing: exitData == null 
//               ? const Text('In Progress', style: TextStyle(color: Colors.blue))
//               : Text('Completed', style: TextStyle(color: Colors.green[600])),
//           );
//         },
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class BusJourneyMonitorScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
  
//   BusJourneyMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Live Journey Monitor'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder(
//         stream: _database.ref('bus_entries').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final Map<dynamic, dynamic>? entries = 
//             snapshot.data?.snapshot.value as Map?;
          
//           if (entries == null || entries.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.directions_bus_outlined, 
//                     size: 64, 
//                     color: Colors.grey
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'No Active Journeys',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final List<MapEntry<dynamic, dynamic>> sortedEntries = 
//             entries.entries.toList()
//               ..sort((a, b) {
//                 final timeA = a.value['entry_time'] as String;
//                 final timeB = b.value['entry_time'] as String;
//                 return timeB.compareTo(timeA);
//               });

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: sortedEntries.length,
//             itemBuilder: (context, index) {
//               final entry = sortedEntries[index];
//               return _buildJourneyCard(entry.key, entry.value);
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _database.ref().get();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: StreamBuilder(
//         stream: _database.ref('bus_exits/$rfidId').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           final exitData = snapshot.data?.snapshot.value as Map?;
          
//           return Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: exitData == null ? Colors.blue.shade200 : Colors.green.shade200,
//                 width: 1,
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header Row with Status
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: exitData == null 
//                             ? Colors.blue.shade50 
//                             : Colors.green.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           exitData == null ? Icons.directions_bus : Icons.done_all,
//                           color: exitData == null ? Colors.blue : Colors.green,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'RFID: $rfidId',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: exitData == null 
//                                   ? Colors.blue.shade50 
//                                   : Colors.green.shade50,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 exitData == null ? 'In Progress' : 'Completed',
//                                 style: TextStyle(
//                                   color: exitData == null 
//                                     ? Colors.blue.shade700 
//                                     : Colors.green.shade700,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   // Journey Details
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, size: 14),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Entry: ${journeyData['entry_time']}',
//                           style: const TextStyle(fontSize: 13),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (exitData != null) ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.logout, size: 14),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Exit: ${exitData['exit_time']}',
//                             style: const TextStyle(fontSize: 13),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.route, size: 14),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Distance: ${exitData['distance']} km',
//                             style: const TextStyle(fontSize: 13),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class BusJourneyMonitorScreen extends StatelessWidget {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
  
//   BusJourneyMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Live Journey Monitor'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder(
//         stream: _database.ref('bus_entries').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final Map<dynamic, dynamic>? entries = 
//             snapshot.data?.snapshot.value as Map?;
          
//           if (entries == null || entries.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.directions_bus_outlined, 
//                     size: 64, 
//                     color: Colors.grey
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'No Active Journeys',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           // Sort entries by time (newest first)
//           final List<MapEntry<dynamic, dynamic>> sortedEntries = 
//             entries.entries.toList()
//               ..sort((a, b) {
//                 final timeA = a.value['entry_time'] as String;
//                 final timeB = b.value['entry_time'] as String;
//                 return timeB.compareTo(timeA);
//               });

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: sortedEntries.length,
//             itemBuilder: (context, index) {
//               final entry = sortedEntries[index];
//               return _buildJourneyCard(entry.key, entry.value);
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Refresh data
//           _database.ref().get();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: StreamBuilder(
//         stream: _database.ref('bus_exits/$rfidId').onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           final exitData = snapshot.data?.snapshot.value as Map?;
          
//           return Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: exitData == null ? Colors.blue.shade200 : Colors.green.shade200,
//                 width: 1,
//               ),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.all(16),
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: exitData == null 
//                     ? Colors.blue.shade50 
//                     : Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   exitData == null ? Icons.directions_bus : Icons.done_all,
//                   color: exitData == null ? Colors.blue : Colors.green,
//                   size: 32,
//                 ),
//               ),
//               title: Row(
//                 children: [
//                   Text(
//                     'RFID: $rfidId',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: exitData == null 
//                         ? Colors.blue.shade50 
//                         : Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Text(
//                       exitData == null ? 'In Progress' : 'Completed',
//                       style: TextStyle(
//                         color: exitData == null 
//                           ? Colors.blue.shade700 
//                           : Colors.green.shade700,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, size: 16),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Entry: ${journeyData['entry_time']}',
//                         style: const TextStyle(fontSize: 15),
//                       ),
//                     ],
//                   ),
//                   if (exitData != null) ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.logout, size: 16),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Exit: ${exitData['exit_time']}',
//                           style: const TextStyle(fontSize: 15),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.route, size: 16),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Distance: ${exitData['distance']} km',
//                           style: const TextStyle(fontSize: 15),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

















