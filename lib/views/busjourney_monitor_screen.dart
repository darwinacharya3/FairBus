import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

class BusJourneyMonitorScreen extends StatelessWidget {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  BusJourneyMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Journey Monitor'),
        backgroundColor: Colors.green[600],
      ),
      body: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Active Journeys',
                    StreamBuilder(
                      stream: _database.ref('bus_entries').onValue,
                      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (!snapshot.hasData) return const Text('...');
                        final Map<dynamic, dynamic>? entries = 
                          snapshot.data?.snapshot.value as Map?;
                        return Text(
                          '${entries?.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Icons.directions_bus,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    'Today\'s Revenue',
                    StreamBuilder(
                      stream: _database.ref('bus_exits').onValue,
                      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (!snapshot.hasData) return const Text('...');
                        final Map<dynamic, dynamic>? exits = 
                          snapshot.data?.snapshot.value as Map?;
                        double totalRevenue = 0;
                        exits?.forEach((key, value) {
                          if (value['exit_time'].toString().startsWith('2025-2-9')) {
                            totalRevenue += (value['fare'] ?? 0).toDouble();
                          }
                        });
                        return Text(
                          'Rs ${totalRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ),

          // Real-time Journey List
          Expanded(
            child: StreamBuilder(
              stream: _database.ref('bus_entries').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<dynamic, dynamic>? entries = 
                  snapshot.data?.snapshot.value as Map?;
                if (entries == null) {
                  return const Center(child: Text('No active journeys'));
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries.entries.elementAt(index);
                    return _buildJourneyCard(entry.key, entry.value);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh data
          _database.ref().get();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatsCard(String title, Widget value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green[600], size: 24),
          const SizedBox(height: 8),
          value,
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(String rfidId, Map<dynamic, dynamic> journeyData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder(
        stream: _database.ref('bus_exits/$rfidId').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          final exitData = snapshot.data?.snapshot.value as Map?;
          
          return ListTile(
            leading: Icon(
              exitData == null ? Icons.directions_bus : Icons.done_all,
              color: exitData == null ? Colors.blue : Colors.green,
            ),
            title: Text('RFID: $rfidId'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entry: ${journeyData['entry_time']}'),
                if (exitData != null) ...[
                  Text('Exit: ${exitData['exit_time']}'),
                  Text('Fare: Rs ${exitData['fare']}'),
                  Text('Distance: ${exitData['distance']} km'),
                ],
              ],
            ),
            trailing: exitData == null 
              ? const Text('In Progress', style: TextStyle(color: Colors.blue))
              : Text('Completed', style: TextStyle(color: Colors.green[600])),
          );
        },
      ),
    );
  }
}