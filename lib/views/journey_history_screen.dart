import 'package:flutter/material.dart';
import 'package:major_project/models/journey.dart';
import 'package:major_project/models/daily_reports.dart';
import 'package:major_project/services/database_service.dart';
import 'package:major_project/widgets/amount_card.dart';
import 'package:major_project/widgets/journey_card.dart';

class JourneyHistoryScreen extends StatefulWidget {
  const JourneyHistoryScreen({super.key});

  @override
  State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
}

class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Stream controllers to manage data
  Stream<List<Journey>>? _journeysStream;
  Stream<DailyReport>? _reportStream;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 JourneyHistoryScreen - initState called');
    
    // This is crucial - setting up the realtime database listener
    debugPrint('🔄 JourneyHistoryScreen - calling setupRealtimeDatabaseListener');
    _databaseService.setupRealtimeDatabaseListener();
    
    debugPrint('🔄 JourneyHistoryScreen - calling _loadData');
    _loadData(); // Initial data load
  }

  // Load fresh data streams
  void _loadData() {
    debugPrint('🔄 JourneyHistoryScreen - _loadData started');
    setState(() {
      // Create new stream instances to force fresh data fetching
      _journeysStream = _databaseService.getTodaysJourneys();
      _reportStream = _databaseService.getTodaysReport();
    });
    debugPrint('✅ JourneyHistoryScreen - Fresh data streams loaded');
  }

  // Method to handle manual refresh
  Future<void> _refreshData() async {
    debugPrint('🔄 JourneyHistoryScreen - Starting manual refresh...');
    setState(() {
      _isRefreshing = true;
    });
    
    // Force Firebase cache refresh by recreating the listener
    debugPrint('🔄 JourneyHistoryScreen - Recreating realtime database listener');
    _databaseService.setupRealtimeDatabaseListener();
    
    // Reload data with fresh streams
    debugPrint('🔄 JourneyHistoryScreen - Reloading data streams');
    _loadData();
    
    // Add a small delay to ensure Firebase has time to respond
    debugPrint('🔄 JourneyHistoryScreen - Waiting for Firebase response');
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _isRefreshing = false;
    });
    
    debugPrint('✅ JourneyHistoryScreen - Manual refresh completed');
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 JourneyHistoryScreen - build method called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey History'),
        backgroundColor: Colors.green[600],
        actions: [
          // Refresh button in the app bar
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Amount Card
            StreamBuilder<DailyReport>(
              stream: _reportStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('❌ JourneyHistoryScreen - Report Error: ${snapshot.error}');
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  debugPrint('⚠️ JourneyHistoryScreen - No report data yet');
                  return const Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                debugPrint('✅ JourneyHistoryScreen - Report data received: ${snapshot.data?.totalJourneys} journeys, ${snapshot.data?.totalAmount} amount');
                return AmountCard(report: snapshot.data!);
              },
            ),

            // Journey History List
            Expanded(
              child: _isRefreshing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Refreshing data...'),
                        ],
                      ),
                    )
                  : StreamBuilder<List<Journey>>(
                      stream: _journeysStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint('❌ JourneyHistoryScreen - Journeys Error: ${snapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 8),
                                Text('Error: ${snapshot.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _refreshData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          debugPrint('⚠️ JourneyHistoryScreen - No journeys data yet');
                          return const Center(child: CircularProgressIndicator());
                        }

                        final journeys = snapshot.data!;
                        debugPrint('✅ JourneyHistoryScreen - Journeys data received: ${journeys.length} journeys');
                        
                        if (journeys.isEmpty) {
                          debugPrint('⚠️ JourneyHistoryScreen - No journeys for today');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No journeys today'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _refreshData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        debugPrint('🔄 JourneyHistoryScreen - Building ListView with ${journeys.length} journeys');
                        return ListView.builder(
                          itemCount: journeys.length,
                          itemBuilder: (context, index) {
                            return JourneyCard(journey: journeys[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRefreshing ? null : _refreshData,
        backgroundColor: Colors.green[600],
        child: _isRefreshing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh data',
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources if needed
    debugPrint('🔄 JourneyHistoryScreen - dispose called');
    super.dispose();
  }
}












// import 'package:flutter/material.dart';
// import 'package:major_project/models/journey.dart';
// import 'package:major_project/models/daily_reports.dart';
// import 'package:major_project/services/database_service.dart';
// import 'package:major_project/widgets/amount_card.dart';
// import 'package:major_project/widgets/journey_card.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final DatabaseService _databaseService = DatabaseService();
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
//   // Stream controllers to manage data
//   Stream<List<Journey>>? _journeysStream;
//   Stream<DailyReport>? _reportStream;
//   bool _isRefreshing = false;

//   @override
//   void initState() {
//     super.initState();
//     _databaseService.setupRealtimeDatabaseListener();
//     _loadData(); // Initial data load
//   }

//   // Load fresh data streams
//   void _loadData() {
//     setState(() {
//       // Create new stream instances to force fresh data fetching
//       _journeysStream = _databaseService.getTodaysJourneys();
//       _reportStream = _databaseService.getTodaysReport();
//     });
//     debugPrint('Fresh data streams loaded');
//   }

//   // Method to handle manual refresh
//   Future<void> _refreshData() async {
//     debugPrint('Starting manual refresh...');
//     setState(() {
//       _isRefreshing = true;
//     });
    
//     // Force Firebase cache refresh by recreating the listener
//     _databaseService.setupRealtimeDatabaseListener();
    
//     // Reload data with fresh streams
//     _loadData();
    
//     // Add a small delay to ensure Firebase has time to respond
//     await Future.delayed(const Duration(milliseconds: 1000));
    
//     setState(() {
//       _isRefreshing = false;
//     });
    
//     debugPrint('Manual refresh completed');
//     return Future.value();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey History'),
//         backgroundColor: Colors.green[600],
//         actions: [
//           // Refresh button in the app bar
//           IconButton(
//             icon: _isRefreshing 
//                 ? const SizedBox(
//                     width: 20, 
//                     height: 20, 
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Icon(Icons.refresh),
//             onPressed: _isRefreshing ? null : _refreshData,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: Column(
//           children: [
//             // Amount Card
//             StreamBuilder<DailyReport>(
//               stream: _reportStream,
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   debugPrint('Report Error: ${snapshot.error}');
//                   return Card(
//                     margin: const EdgeInsets.all(16),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                           const SizedBox(height: 8),
//                           Text('Error: ${snapshot.error}'),
//                         ],
//                       ),
//                     ),
//                   );
//                 }

//                 if (!snapshot.hasData) {
//                   return const Card(
//                     margin: EdgeInsets.all(16),
//                     child: Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Center(child: CircularProgressIndicator()),
//                     ),
//                   );
//                 }

//                 return AmountCard(report: snapshot.data!);
//               },
//             ),

//             // Journey History List
//             Expanded(
//               child: _isRefreshing
//                   ? const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(height: 16),
//                           Text('Refreshing data...'),
//                         ],
//                       ),
//                     )
//                   : StreamBuilder<List<Journey>>(
//                       stream: _journeysStream,
//                       builder: (context, snapshot) {
//                         if (snapshot.hasError) {
//                           debugPrint('Journeys Error: ${snapshot.error}');
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                                 const SizedBox(height: 8),
//                                 Text('Error: ${snapshot.error}'),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton.icon(
//                                   onPressed: _refreshData,
//                                   icon: const Icon(Icons.refresh),
//                                   label: const Text('Try Again'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green[600],
//                                     foregroundColor: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final journeys = snapshot.data!;
                        
//                         if (journeys.isEmpty) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
//                                 const SizedBox(height: 8),
//                                 const Text('No journeys today'),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton.icon(
//                                   onPressed: _refreshData,
//                                   icon: const Icon(Icons.refresh),
//                                   label: const Text('Refresh'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green[600],
//                                     foregroundColor: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           itemCount: journeys.length,
//                           itemBuilder: (context, index) {
//                             return JourneyCard(journey: journeys[index]);
//                           },
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _isRefreshing ? null : _refreshData,
//         backgroundColor: Colors.green[600],
//         child: _isRefreshing
//             ? const CircularProgressIndicator(color: Colors.white)
//             : const Icon(Icons.refresh, color: Colors.white),
//         tooltip: 'Refresh data',
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Clean up resources if needed
//     super.dispose();
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:major_project/models/journey.dart';
// import 'package:major_project/models/daily_reports.dart';
// import 'package:major_project/services/database_service.dart';
// import 'package:major_project/widgets/amount_card.dart';
// import 'package:major_project/widgets/journey_card.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final DatabaseService _databaseService = DatabaseService();
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
//   // Stream controllers to force refresh
//   List<Journey> _currentJourneys = [];
//   DailyReport? _currentReport;
//   bool _isRefreshing = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupListeners();
//   }

//   void _setupListeners() {
//     // Set up the realtime database listener
//     _databaseService.setupRealtimeDatabaseListener();
    
//     // Listen for new journey data and trigger refresh when detected
//     _databaseService.getTodaysJourneys().listen((journeys) {
//       // Only trigger a refresh if the journey count has changed
//       if (_currentJourneys.length != journeys.length) {
//         setState(() {
//           _currentJourneys = journeys;
//         });
//         debugPrint('Auto-refreshed due to journey count change: ${journeys.length}');
//       }
//     });

//     // Listen for report changes
//     _databaseService.getTodaysReport().listen((report) {
//       // Refresh if total journeys count changed
//       if (_currentReport == null || _currentReport!.totalJourneys != report.totalJourneys) {
//         setState(() {
//           _currentReport = report;
//         });
//         debugPrint('Auto-refreshed due to report change: ${report.totalJourneys} journeys');
//       }
//     });
//   }

//   // Method to handle manual refresh
//   Future<void> _refreshData() async {
//     setState(() {
//       _isRefreshing = true;
//     });
    
//     // Simulate a short delay to show the refresh indicator
//     await Future.delayed(const Duration(milliseconds: 500));
    
//     setState(() {
//       _isRefreshing = false;
//     });
    
//     debugPrint('Manual refresh completed');
//     return Future.value();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey History'),
//         backgroundColor: Colors.green[600],
//         actions: [
//           // Refresh button in the app bar
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _refreshIndicatorKey.currentState?.show();
//             },
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: Column(
//           children: [
//             // Amount Card
//             StreamBuilder<DailyReport>(
//               stream: _databaseService.getTodaysReport(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   debugPrint('Report Error: ${snapshot.error}');
//                   return Card(
//                     margin: const EdgeInsets.all(16),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                           const SizedBox(height: 8),
//                           Text('Error: ${snapshot.error}'),
//                         ],
//                       ),
//                     ),
//                   );
//                 }

//                 if (!snapshot.hasData) {
//                   return const Card(
//                     margin: EdgeInsets.all(16),
//                     child: Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Center(child: CircularProgressIndicator()),
//                     ),
//                   );
//                 }

//                 return AmountCard(report: snapshot.data!);
//               },
//             ),

//             // Journey History List
//             Expanded(
//               child: StreamBuilder<List<Journey>>(
//                 stream: _databaseService.getTodaysJourneys(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     debugPrint('Journeys Error: ${snapshot.error}');
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                           const SizedBox(height: 8),
//                           Text('Error: ${snapshot.error}'),
//                         ],
//                       ),
//                     );
//                   }

//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   final journeys = snapshot.data!;
                  
//                   if (journeys.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
//                           const SizedBox(height: 8),
//                           const Text('No journeys today'),
//                           const SizedBox(height: 16),
//                           // Additional refresh button in the empty state
//                           ElevatedButton.icon(
//                             onPressed: () => _refreshIndicatorKey.currentState?.show(),
//                             icon: const Icon(Icons.refresh),
//                             label: const Text('Refresh'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green[600],
//                               foregroundColor: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return _isRefreshing
//                       ? const Center(child: CircularProgressIndicator())
//                       : ListView.builder(
//                           itemCount: journeys.length,
//                           itemBuilder: (context, index) {
//                             return JourneyCard(journey: journeys[index]);
//                           },
//                         );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       // Floating refresh button at the bottom right corner
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _refreshIndicatorKey.currentState?.show(),
//         backgroundColor: Colors.green[600],
//         child: const Icon(Icons.refresh, color: Colors.white),
//         tooltip: 'Refresh data',
//       ),
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:major_project/models/journey.dart';
// import 'package:major_project/models/daily_reports.dart';
// import 'package:major_project/services/database_service.dart';
// import 'package:major_project/widgets/amount_card.dart';
// import 'package:major_project/widgets/journey_card.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final DatabaseService _databaseService = DatabaseService();

//   @override
//   void initState() {
//     super.initState();
//     _databaseService.setupRealtimeDatabaseListener();
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
//           // Amount Card
//           StreamBuilder<DailyReport>(
//             stream: _databaseService.getTodaysReport(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 debugPrint('Report Error: ${snapshot.error}');
//                 return Card(
//                   margin: const EdgeInsets.all(16),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                         const SizedBox(height: 8),
//                         Text('Error: ${snapshot.error}'),
//                       ],
//                     ),
//                   ),
//                 );
//               }

//               if (!snapshot.hasData) {
//                 return const Card(
//                   margin: EdgeInsets.all(16),
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   ),
//                 );
//               }

//               return AmountCard(report: snapshot.data!);
//             },
//           ),

//           // Journey History List
//           Expanded(
//             child: StreamBuilder<List<Journey>>(
//               stream: _databaseService.getTodaysJourneys(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   debugPrint('Journeys Error: ${snapshot.error}');
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                         const SizedBox(height: 8),
//                         Text('Error: ${snapshot.error}'),
//                       ],
//                     ),
//                   );
//                 }

//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final journeys = snapshot.data!;
                
//                 if (journeys.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
//                         SizedBox(height: 8),
//                         Text('No journeys today'),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: journeys.length,
//                   itemBuilder: (context, index) {
//                     return JourneyCard(journey: journeys[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'package:major_project/models/journey.dart';
// import 'package:major_project/models/daily_reports.dart';
// import 'package:major_project/services/database_service.dart';
// import 'package:major_project/widgets/amount_card.dart';
// import 'package:major_project/widgets/journey_card.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final DatabaseService _databaseService = DatabaseService();

//   @override
//   void initState() {
//     super.initState();
//     _databaseService.setupRealtimeDatabaseListener();
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
//           // Amount Card
//           StreamBuilder<DailyReport>(
//             stream: _databaseService.getTodaysReport(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 debugPrint('Report Error: ${snapshot.error}');
//                 return Card(
//                   margin: const EdgeInsets.all(16),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                         const SizedBox(height: 8),
//                         Text('Error: ${snapshot.error}'),
//                       ],
//                     ),
//                   ),
//                 );
//               }

//               if (!snapshot.hasData) {
//                 return const Card(
//                   margin: EdgeInsets.all(16),
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   ),
//                 );
//               }

//               return AmountCard(report: snapshot.data!);
//             },
//           ),

//           // Journey History List
//           Expanded(
//             child: StreamBuilder<List<Journey>>(
//               stream: _databaseService.getTodaysJourneys(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   debugPrint('Journeys Error: ${snapshot.error}');
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                         const SizedBox(height: 8),
//                         Text('Error: ${snapshot.error}'),
//                       ],
//                     ),
//                   );
//                 }

//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final journeys = snapshot.data!;
                
//                 if (journeys.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
//                         SizedBox(height: 8),
//                         Text('No journeys today'),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: journeys.length,
//                   itemBuilder: (context, index) {
//                     return JourneyCard(journey: journeys[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








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

//    Stream<QuerySnapshot> _getFilteredStream() {
//     var query = _firestore.collection('journey_history')
//         .orderBy('timestamp', descending: true);
    
//     if (_searchQuery.isNotEmpty) {
//       // Create a range for RFID search
//       String searchEnd = '$_searchQuery\uf8ff';
//       query = query.where('rfid', isGreaterThanOrEqualTo: _searchQuery)
//                   .where('rfid', isLessThan: searchEnd);
//     }
    
//     return query.limit(50).snapshots(); // Limit results for better performance
//   }

//   Widget _buildJourneyCard(Map<String, dynamic> journey) {
//   final bool isCompleted = journey['status'] == 'completed';
//   final String entryTime = journey['entry_time'] ?? 'N/A';
//   final String exitTime = journey['exit_time'] ?? 'N/A';
  
//   return Card(
//     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: ExpansionTile(
//       leading: Icon(
//         isCompleted ? Icons.done_all : Icons.directions_bus,
//         color: isCompleted ? Colors.green : Colors.blue,
//       ),
//       title: Text(
//         'RFID: ${journey['rfid']}',
//         overflow: TextOverflow.ellipsis,
//       ),
//       subtitle: Wrap(
//         spacing: 8,
//         children: [
//           Text(
//             isCompleted ? 'Completed' : 'Active Journey',
//             style: TextStyle(
//               color: isCompleted ? Colors.green : Colors.blue,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             'Entry: $entryTime',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       children: [
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (isCompleted) ...[
//                   _buildInfoRow('Exit Time', exitTime),
//                   _buildInfoRow('Distance', '${journey['distance']} km'),
//                   _buildInfoRow('Fare', 'Rs ${journey['fare']}'),
//                   _buildInfoRow('Balance', 'Rs ${journey['remaining_balance']}'),
//                 ],
//                 if (journey['start_latitude'] != null) ...[
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Route Details',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   SizedBox(
//                     width: MediaQuery.of(context).size.width - 64, // Account for padding
//                     child: Text(
//                       'Start: ${journey['start_latitude']}, ${journey['start_longitude']}',
//                       style: TextStyle(color: Colors.grey[600]),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (isCompleted)
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width - 64,
//                       child: Text(
//                         'End: ${journey['end_latitude']}, ${journey['end_longitude']}',
//                         style: TextStyle(color: Colors.grey[600]),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildInfoRow(String label, String value) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(value),
//       ],
//     ),
//   );
// }
// }















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
//   final bool isCompleted = journey['status'] == 'completed';
//   final String entryTime = journey['entry_time'] ?? 'N/A';
//   final String exitTime = journey['exit_time'] ?? 'N/A';
  
//   return Card(
//     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: ExpansionTile(
//       leading: Icon(
//         isCompleted ? Icons.done_all : Icons.directions_bus,
//         color: isCompleted ? Colors.green : Colors.blue,
//       ),
//       title: Text(
//         'RFID: ${journey['rfid']}',
//         overflow: TextOverflow.ellipsis,
//       ),
//       subtitle: Wrap(
//         spacing: 8,
//         children: [
//           Text(
//             isCompleted ? 'Completed' : 'Active Journey',
//             style: TextStyle(
//               color: isCompleted ? Colors.green : Colors.blue,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             'Entry: $entryTime',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       children: [
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (isCompleted) ...[
//                   _buildInfoRow('Exit Time', exitTime),
//                   _buildInfoRow('Distance', '${journey['distance']} km'),
//                   _buildInfoRow('Fare', 'Rs ${journey['fare']}'),
//                   _buildInfoRow('Balance', 'Rs ${journey['remaining_balance']}'),
//                 ],
//                 if (journey['start_latitude'] != null) ...[
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Route Details',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     width: MediaQuery.of(context).size.width - 64, // Account for padding
//                     child: Text(
//                       'Start: ${journey['start_latitude']}, ${journey['start_longitude']}',
//                       style: TextStyle(color: Colors.grey[600]),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (isCompleted)
//                     Container(
//                       width: MediaQuery.of(context).size.width - 64,
//                       child: Text(
//                         'End: ${journey['end_latitude']}, ${journey['end_longitude']}',
//                         style: TextStyle(color: Colors.grey[600]),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildInfoRow(String label, String value) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(value),
//       ],
//     ),
//   );
// }
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
//       // print('Error storing journey: $e');
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


















// import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:async';
// import 'package:major_project/widgets/journey_widget/journey_model.dart';
// import 'package:major_project/widgets/journey_widget/statistics_service.dart';
// import 'package:major_project/widgets/journey_widget/custom_widgets.dart';

// class JourneyHistoryScreen extends StatefulWidget {
//   const JourneyHistoryScreen({super.key});

//   @override
//   State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
// }

// class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final StatisticsService _statisticsService = StatisticsService(FirebaseFirestore.instance);
//   String _searchQuery = '';
//   DateTime? _startDate;
//   DateTime? _endDate;
//   Map<String, dynamic>? _dailyStatistics;
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadDailyStatistics();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//  Future<String> _getUserNameByRFID(String rfid) async {
//     try {
//       final QuerySnapshot userDoc = await _firestore
//           .collection('users')
//           .where('rfid', isEqualTo: rfid)
//           .limit(1)
//           .get();

//       if (userDoc.docs.isNotEmpty) {
//         final userData = userDoc.docs.first.data() as Map<String, dynamic>;
//         return userData['username'] ?? 'Unknown User';
//       }
//       return 'Unknown User';
//     } catch (e) {
//       return 'Unknown User';
//     }
//   }

//   Future<void> _loadDailyStatistics() async {
//     final stats = await _statisticsService.getDailyStatistics(DateTime.now());
//     setState(() {
//       _dailyStatistics = stats;
//     });
//   }

//   void _onSearchChanged(String value) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         _searchQuery = value;
//       });
//     });
//   }

//    Stream<QuerySnapshot> _getFilteredStream() {
//     Query query = _firestore.collection('journey_history');
    
//     if (_startDate != null && _endDate != null) {
//       query = query.where('timestamp', 
//         isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
//         isLessThanOrEqualTo: Timestamp.fromDate(_endDate!.add(const Duration(days: 1))),
//       );
//     }

//     if (_searchQuery.isNotEmpty) {
//       String searchEnd = _searchQuery + '\uf8ff';
//       query = query.where('rfid', isGreaterThanOrEqualTo: _searchQuery)
//                   .where('rfid', isLessThan: searchEnd);
//     }
    
//     return query.orderBy('timestamp', descending: true)
//                 .limit(50)
//                 .snapshots();
//   }

//   Future<void> _generateMonthlyReport() async {
//     try {
//       final now = DateTime.now();
//       final report = await _statisticsService.getMonthlyReport(now);
      
//       if (!mounted) return;

//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Monthly Report - ${_getMonthName(now.month)}'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildReportItem('Total Collection', 'Rs ${report['totalMonthlyFare']?.toStringAsFixed(2)}'),
//                 _buildReportItem('Total Distance', '${report['totalMonthlyDistance']?.toStringAsFixed(2)} km'),
//                 _buildReportItem('Total Journeys', '${report['totalJourneys']}'),
//                 _buildReportItem('Average Daily Collection', 'Rs ${report['averageDailyFare']?.toStringAsFixed(2)}'),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             ),
//             TextButton(
//               onPressed: () {
//                 // TODO: Implement export functionality
//                 Navigator.pop(context);
//               },
//               child: const Text('Export'),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error generating report: $e')),
//       );
//     }
//   }

//   String _getMonthName(int month) {
//     const months = [
//       'January', 'February', 'March', 'April', 'May', 'June',
//       'July', 'August', 'September', 'October', 'November', 'December'
//     ];
//     return months[month - 1];
//   }

//   Widget _buildReportItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text(value),
//         ],
//       ),
//     );
//   }

//    Widget _buildJourneyCard(Journey journey) {
//     final bool isCompleted = journey.status == 'completed';
    
//     return FutureBuilder<String>(
//       future: _getUserNameByRFID(journey.rfid),
//       builder: (context, snapshot) {
//         final userName = snapshot.data ?? 'Loading...';
        
//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: ExpansionTile(
//             leading: Icon(
//               isCompleted ? Icons.done_all : Icons.directions_bus,
//               color: isCompleted ? Colors.green : Colors.blue,
//             ),
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(userName),
//                 Text(
//                   'RFID: ${journey.rfid}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//             subtitle: Text(
//               isCompleted ? 'Completed' : 'Active Journey',
//               style: TextStyle(
//                 color: isCompleted ? Colors.green : Colors.blue,
//               ),
//             ),
//             children: [
//               // ... rest of the expansion tile content remains the same
//                Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildInfoRow('Entry Time', journey.entryTime),
//                 if (isCompleted) ...[
//                   _buildInfoRow('Exit Time', journey.exitTime ?? 'N/A'),
//                   _buildInfoRow('Distance', '${journey.distance?.toStringAsFixed(2)} km'),
//                   _buildInfoRow('Fare', 'Rs ${journey.fare?.toStringAsFixed(2)}'),
//                   _buildInfoRow('Balance', 'Rs ${journey.remainingBalance?.toStringAsFixed(2)}'),
//                 ],
//                 const SizedBox(height: 8),
//                 Text(
//                   'Route Details',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 Text('Start: ${journey.startLatitude}, ${journey.startLongitude}'),
//                 if (isCompleted)
//                   Text('End: ${journey.endLatitude}, ${journey.endLongitude}'),
//               ],
//             ),
//           ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Widget _buildJourneyCard(Journey journey) {
//   //   final bool isCompleted = journey.status == 'completed';
    
    
//   //   return Card(
//   //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//   //     child: ExpansionTile(
//   //       leading: Icon(
//   //         isCompleted ? Icons.done_all : Icons.directions_bus,
//   //         color: isCompleted ? Colors.green : Colors.blue,
//   //       ),
//   //       title: Text('RFID: ${journey.rfid}'),
//   //       subtitle: Text(
//   //         isCompleted ? 'Completed' : 'Active Journey',
//   //         style: TextStyle(
//   //           color: isCompleted ? Colors.green : Colors.blue,
//   //         ),
//   //       ),
//   //       children: [
//   //         Padding(
//   //           padding: const EdgeInsets.all(16.0),
//   //           child: Column(
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               _buildInfoRow('Entry Time', journey.entryTime),
//   //               if (isCompleted) ...[
//   //                 _buildInfoRow('Exit Time', journey.exitTime ?? 'N/A'),
//   //                 _buildInfoRow('Distance', '${journey.distance?.toStringAsFixed(2)} km'),
//   //                 _buildInfoRow('Fare', 'Rs ${journey.fare?.toStringAsFixed(2)}'),
//   //                 _buildInfoRow('Balance', 'Rs ${journey.remainingBalance?.toStringAsFixed(2)}'),
//   //               ],
//   //               const SizedBox(height: 8),
//   //               Text(
//   //                 'Route Details',
//   //                 style: TextStyle(
//   //                   fontWeight: FontWeight.bold,
//   //                   color: Colors.grey[600],
//   //                 ),
//   //               ),
//   //               Text('Start: ${journey.startLatitude}, ${journey.startLongitude}'),
//   //               if (isCompleted)
//   //                 Text('End: ${journey.endLatitude}, ${journey.endLongitude}'),
//   //             ],
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey History'),
//         backgroundColor: Colors.green[600],
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.assessment),
//             onPressed: _generateMonthlyReport,
//             tooltip: 'Generate Monthly Report',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_dailyStatistics != null)
//             StatisticsCard(statistics: _dailyStatistics!),
          
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search by RFID',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//               onChanged: _onSearchChanged,
//             ),
//           ),

//           CustomDateRangePicker(
//             startDate: _startDate,
//             endDate: _endDate,
//             onDateSelected: (DateTimeRange range) {
//               setState(() {
//                 _startDate = range.start;
//                 _endDate = range.end;
//               });
//             },
//           ),

//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _getFilteredStream(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final journeys = snapshot.data!.docs
//                     .map((doc) => Journey.fromMap(doc.data() as Map<String, dynamic>))
//                     .toList();

//                 if (journeys.isEmpty) {
//                   return const Center(
//                     child: Text('No journeys found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: journeys.length,
//                   itemBuilder: (context, index) {
//                     return _buildJourneyCard(journeys[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }












