import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics & Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh functionality if needed
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('analytics_and_report')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          // Calculate totals and statistics
          double totalAmount = 0;
          int totalJourneys = 0;
          int totalRFIDs = 0;

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            totalAmount += (data['total_amount'] ?? 0).toDouble();
            totalJourneys += (data['total_journeys'] ?? 0) as int;
            if (data['rfids_scanned'] != null) {
              totalRFIDs += (data['rfids_scanned'] as List).length;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Statistics Card
                _buildCard(
                  'Today\'s Overview',
                  snapshot.data!.docs.first.data() as Map<String, dynamic>,
                ),
                const SizedBox(height: 16),

                // Overall Statistics Card
                _buildOverallStatsCard(
                  totalAmount: totalAmount,
                  totalJourneys: totalJourneys,
                  totalRFIDs: totalRFIDs,
                  numberOfDays: snapshot.data!.docs.length,
                ),
                const SizedBox(height: 16),

                // Recent Transactions List
                _buildRecentTransactionsList(snapshot.data!.docs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp;
    final date = DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24),
          _buildDetailRow('Date', formattedDate),
          _buildDetailRow(
              'Total Amount', 'Rs. ${data['total_amount']?.toStringAsFixed(2)}'),
          _buildDetailRow('Total Journeys', '${data['total_journeys']}'),
          _buildDetailRow('RFIDs Scanned',
              '${(data['rfids_scanned'] as List?)?.length ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard({
    required double totalAmount,
    required int totalJourneys,
    required int totalRFIDs,
    required int numberOfDays,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24),
          _buildDetailRow('Total Revenue', 'Rs. ${totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Average Daily Revenue',
              'Rs. ${(totalAmount / numberOfDays).toStringAsFixed(2)}'),
          _buildDetailRow('Total Journeys', '$totalJourneys'),
          _buildDetailRow('Total RFIDs Used', '$totalRFIDs'),
          _buildDetailRow('Days Analyzed', '$numberOfDays'),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24),
          ...docs.take(5).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp;
            final date = DateTime.fromMillisecondsSinceEpoch(
                timestamp.millisecondsSinceEpoch);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMM dd').format(date)),
                  Text('Rs. ${data['total_amount']?.toStringAsFixed(2)}'),
                  Text('${data['total_journeys']} journeys'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:intl/intl.dart';
// // import 'package:fl_chart/fl_chart.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});

//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String selectedPeriod = 'Weekly';
//   bool isLoading = false;
//   Map<String, dynamic> analyticsData = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchAnalyticsData();
//   }

//   Future<void> _fetchAnalyticsData() async {
//     setState(() => isLoading = true);
//     try {
//       final analyticsSnapshot = await _firestore.collection('analytics').get();
//       final reportsSnapshot = await _firestore.collection('reports').get();

//       // Combine analytics and reports data
//       Map<String, dynamic> combinedData = {};
      
//       for (var doc in analyticsSnapshot.docs) {
//         combinedData.addAll(doc.data());
//       }
      
//       for (var doc in reportsSnapshot.docs) {
//         combinedData.addAll(doc.data());
//       }

//       setState(() {
//         analyticsData = combinedData;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching analytics data: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to load analytics data',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[900],
//       );
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Analytics & Reports',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.green[600],
//         elevation: 2,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _fetchAnalyticsData,
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Period Selection
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: selectedPeriod,
//                         isExpanded: true,
//                         items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
//                             .map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(value),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           if (newValue != null) {
//                             setState(() => selectedPeriod = newValue);
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Revenue Overview Card
//                   _buildCard(
//                     'Revenue Overview',
//                     Column(
//                       children: [
//                         _buildMetricRow('Total Revenue', 'Rs. 125,000'),
//                         _buildMetricRow('Average Daily Revenue', 'Rs. 4,167'),
//                         _buildMetricRow('Revenue Growth', '+15%'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Journey Statistics Card
//                   _buildCard(
//                     'Journey Statistics',
//                     Column(
//                       children: [
//                         _buildMetricRow('Total Journeys', '1,234'),
//                         _buildMetricRow('Average Journey Length', '45 mins'),
//                         _buildMetricRow('Peak Hours', '8-10 AM, 5-7 PM'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // User Activity Card
//                   _buildCard(
//                     'User Activity',
//                     Column(
//                       children: [
//                         _buildMetricRow('Active Users', '890'),
//                         _buildMetricRow('New Users', '+45 this week'),
//                         _buildMetricRow('User Engagement', '78%'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // RFID Card Usage
//                   _buildCard(
//                     'RFID Card Usage',
//                     Column(
//                       children: [
//                         _buildMetricRow('Active Cards', '756'),
//                         _buildMetricRow('New Card Registrations', '23 this week'),
//                         _buildMetricRow('Card Usage Rate', '85%'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Download Report Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.download),
//                       label: const Text('Download Detailed Report'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green[600],
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       onPressed: () {
//                         Get.snackbar(
//                           'Download Started',
//                           'Your report is being generated',
//                           backgroundColor: Colors.green[100],
//                           colorText: Colors.green[900],
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildCard(String title, Widget content) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const Divider(height: 24),
//           content,
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }