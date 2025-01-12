import 'package:latlong2/latlong.dart';

enum TurnType {
  straight,
  slightRight,
  right,
  sharpRight,
  slightLeft,
  left,
  sharpLeft,
  uTurn,
  roundabout,
  finish
}

class NavigationInstruction {
  final TurnType turnType;
  final String instruction;
  final double distance; // in meters
  final double duration; // in seconds
  final LatLng location;
  final double bearing;

  const NavigationInstruction({
    required this.turnType,
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
    required this.bearing,
  });

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.round()} m';
  }

  String get formattedDuration {
    int minutes = (duration / 60).floor();
    if (minutes < 1) return 'Less than a minute';
    return '$minutes min';
  }
}
