class Journey {
  final String rfid;
  final String entryTime;
  final String? exitTime;
  final double startLatitude;
  final double startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double? distance;
  final double? fare;
  final double? remainingBalance;
  final String status;
  final DateTime timestamp;

  Journey({
    required this.rfid,
    required this.entryTime,
    this.exitTime,
    required this.startLatitude,
    required this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.distance,
    this.fare,
    this.remainingBalance,
    required this.status,
    required this.timestamp,
  });

  factory Journey.fromMap(Map<String, dynamic> map) {
    return Journey(
      rfid: map['rfid'] ?? '',
      entryTime: map['entry_time'] ?? '',
      exitTime: map['exit_time'],
      startLatitude: (map['start_latitude'] ?? 0.0).toDouble(),
      startLongitude: (map['start_longitude'] ?? 0.0).toDouble(),
      endLatitude: (map['end_latitude'] ?? 0.0).toDouble(),
      endLongitude: (map['end_longitude'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      fare: (map['fare'] ?? 0.0).toDouble(),
      remainingBalance: (map['remaining_balance'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'active',
      timestamp: (map['timestamp']).toDate(),
    );
  }
}