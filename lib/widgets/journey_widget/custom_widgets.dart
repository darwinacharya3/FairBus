import 'package:flutter/material.dart';

class StatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const StatisticsCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.payments,
                  label: 'Total Collection',
                  value: 'Rs ${statistics['totalFare']?.toStringAsFixed(2)}',
                ),
                _buildStatItem(
                  icon: Icons.directions_bus,
                  label: 'Total Journeys',
                  value: '${statistics['totalJourneys']}',
                ),
                _buildStatItem(
                  icon: Icons.route,
                  label: 'Distance',
                  value: '${statistics['totalDistance']?.toStringAsFixed(2)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[600], size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class CustomDateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTimeRange) onDateSelected;

  const CustomDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            currentDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.green[600]!,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                startDate != null && endDate != null
                    ? '${_formatDate(startDate!)} - ${_formatDate(endDate!)}'
                    : 'Select Date Range',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}