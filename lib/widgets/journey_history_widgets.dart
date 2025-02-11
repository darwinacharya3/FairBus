// journey_history_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class JourneyStatistics extends StatelessWidget {
  final List<Map<String, dynamic>> journeys;

  const JourneyStatistics({
    super.key,
    required this.journeys,
  });

  @override
  Widget build(BuildContext context) {
    final totalJourneys = journeys.length;
    final completedJourneys = journeys.where((j) => j['status'] == 'completed').length;
    final activeJourneys = totalJourneys - completedJourneys;
    final totalFare = journeys
        .where((j) => j['status'] == 'completed')
        .fold(0.0, (sum, j) => sum + (j['fare'] ?? 0.0));
    final avgFare = completedJourneys > 0 ? totalFare / completedJourneys : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journey Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Journeys',
                totalJourneys.toString(),
                Icons.analytics,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                context,
                'Completed',
                completedJourneys.toString(),
                Icons.done_all,
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                context,
                'Avg Fare',
                'Rs ${avgFare.toStringAsFixed(2)}',
                Icons.payments,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildJourneyStatusPieChart(
                    completedJourneys: completedJourneys,
                    activeJourneys: activeJourneys,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildFareBarChart(journeys),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStatusPieChart({
    required int completedJourneys,
    required int activeJourneys,
  }) {
    return Column(
      children: [
        const Text('Journey Status'),
        const SizedBox(height: 8),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: completedJourneys.toDouble(),
                  title: 'Completed',
                  color: Colors.green,
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                PieChartSectionData(
                  value: activeJourneys.toDouble(),
                  title: 'Active',
                  color: Colors.blue,
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFareBarChart(List<Map<String, dynamic>> journeys) {
    // Get completed journeys with fares
    final completedJourneys = journeys
        .where((j) => j['status'] == 'completed' && j['fare'] != null)
        .toList();

    // Sort by fare
    completedJourneys.sort((a, b) => (b['fare'] as num).compareTo(a['fare'] as num));

    // Take top 5 fares
    final topJourneys = completedJourneys.take(5).toList();

    return Column(
      children: [
        const Text('Top 5 Fares'),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topJourneys.isEmpty ? 100 : 
                (topJourneys.first['fare'] as num).toDouble() * 1.2,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                topJourneys.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (topJourneys[index]['fare'] as num).toDouble(),
                      color: Colors.orange,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (keep all remaining widget code the same) ...

class JourneyList extends StatelessWidget {
  final List<Map<String, dynamic>> journeys;
  final Function(Map<String, dynamic>) onJourneyTap;

  const JourneyList({
    super.key,
    required this.journeys,
    required this.onJourneyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: journeys.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final journey = journeys[index];
        return _buildJourneyCard(context, journey);
      },
    );
  }

  Widget _buildJourneyCard(BuildContext context, Map<String, dynamic> journey) {
    final bool isCompleted = journey['status'] == 'completed';
    final String entryTime = journey['entry_time'] ?? 'N/A';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => onJourneyTap(journey),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.done_all : Icons.directions_bus,
                    color: isCompleted ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RFID: ${journey['rfid']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Entry: $entryTime',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Text(
                      'Rs ${journey['fare']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (journey['distance'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Distance: ${journey['distance']} km',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class JourneyDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> journey;

  const JourneyDetailsSheet({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journey Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          _buildDetailRow('RFID', journey['rfid']),
          _buildDetailRow('Status', journey['status']),
          _buildDetailRow('Entry Time', journey['entry_time']),
          if (journey['exit_time'] != null)
            _buildDetailRow('Exit Time', journey['exit_time']),
          if (journey['distance'] != null)
            _buildDetailRow('Distance', '${journey['distance']} km'),
          if (journey['fare'] != null)
            _buildDetailRow('Fare', 'Rs ${journey['fare']}'),
          if (journey['remaining_balance'] != null)
            _buildDetailRow('Balance', 'Rs ${journey['remaining_balance']}'),
          const SizedBox(height: 16),
          Text(
            'Route Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Start Location', 
            '${journey['start_latitude']}, ${journey['start_longitude']}'),
          if (journey['end_latitude'] != null)
            _buildDetailRow('End Location',
              '${journey['end_latitude']}, ${journey['end_longitude']}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
              onPressed: () {
                // Implement map view
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}