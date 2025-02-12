import 'package:flutter/material.dart';
import '../models/journey.dart';

class JourneyCard extends StatelessWidget {
  final Journey journey;

  const JourneyCard({Key? key, required this.journey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = journey.status == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          isCompleted ? Icons.done_all : Icons.directions_bus,
          color: isCompleted ? Colors.green : Colors.blue,
        ),
        title: Text(
          'RFID: ${journey.rfid}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: 8,
          children: [
            Text(
              isCompleted ? 'Completed' : 'Active Journey',
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.blue,
                fontSize: 12,
              ),
            ),
            Text(
              'Entry: ${journey.entryTime}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          _buildJourneyDetails(context),
        ],
      ),
    );
  }

  Widget _buildJourneyDetails(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (journey.status == 'completed') ...[
              _buildInfoRow('Exit Time', journey.exitTime ?? 'N/A'),
              _buildInfoRow('Distance', '${journey.distance?.toStringAsFixed(2) ?? "N/A"} km'),
              _buildInfoRow('Fare', 'Rs ${journey.fare?.toStringAsFixed(2) ?? "N/A"}'),
              _buildInfoRow('Balance', 'Rs ${journey.remainingBalance?.toStringAsFixed(2) ?? "N/A"}'),
            ],
            if (journey.startLatitude != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Route Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: MediaQuery.of(context).size.width - 64,
                child: Text(
                  'Start: ${journey.startLatitude}, ${journey.startLongitude}',
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (journey.status == 'completed')
                SizedBox(
                  width: MediaQuery.of(context).size.width - 64,
                  child: Text(
                    'End: ${journey.endLatitude}, ${journey.endLongitude}',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}