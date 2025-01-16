import 'dart:async';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NavigationInstruction {
  final String mainInstruction;  // e.g., "Turn right"
  final String secondaryInstruction; // e.g., "onto Ring Road"
  final String nextInstruction; // Preview of next turn
  final double distance;
  final double duration;
  final LatLng location;
  final double bearing;
  final NavigationManeuver maneuver;
  final bool isNextTurnPreview;

  NavigationInstruction({
    required this.mainInstruction,
    required this.secondaryInstruction,
    required this.nextInstruction,
    required this.distance,
    required this.duration,
    required this.location,
    required this.bearing,
    required this.maneuver,
    this.isNextTurnPreview = false,
  });

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.round()} m';
  }

  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 1) {
      return 'Less than a minute';
    } else if (minutes == 1) {
      return '1 minute';
    }
    return '$minutes minutes';
  }
}

enum NavigationManeuver {
  straight,
  turnRight,
  turnLeft,
  slightRight,
  slightLeft,
  sharpRight,
  sharpLeft,
  uTurn,
  roundabout,
  merge,
  exit,
  arrive
}

class NavigationService {
  static const String OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving/';
  static const double REROUTE_THRESHOLD = 50.0; // meters
  static const double ANNOUNCE_THRESHOLD = 200.0; // meters before turn

  final _navigationController = StreamController<NavigationInstruction>.broadcast();
  final _routeProgressController = StreamController<double>.broadcast();
  
  List<NavigationInstruction> _instructions = [];
  LatLng? _lastUserLocation;
  int _currentInstructionIndex = 0;
  bool _isNavigating = false;
  List<LatLng> _routePoints = [];
  
  Stream<NavigationInstruction> get navigationStream => _navigationController.stream;
  Stream<double> get routeProgressStream => _routeProgressController.stream;
  List<LatLng> get currentRoutePoints => _routePoints;

   Future<RouteData> getRouteData(LatLng start, LatLng end) async {
    try {
      return await _fetchRouteFromOSRM(start, end);
    } catch (e) {
      throw Exception('Failed to get route data: $e');
    }
  }

 Future<void> startNavigation(LatLng start, LatLng end) async {
    try {
      final route = await _fetchRouteFromOSRM(start, end);
      _routePoints = route.points;
      _instructions = route.instructions;
      _currentInstructionIndex = 0;
      _isNavigating = true;
      _emitCurrentInstruction();
    } catch (e) {
      throw Exception('Failed to start navigation: $e');
    }
  }

  
  Future<RouteData> _fetchRouteFromOSRM(LatLng start, LatLng end) async {
    try {
      final url = '$OSRM_BASE_URL'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?steps=true'
          '&annotations=distance,duration'
          '&overview=full'
          '&geometries=geojson';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch route: Status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return _parseRouteData(data);
    } catch (e) {
      throw Exception('Failed to fetch route: $e');
    }
  }

 

  RouteData _parseRouteData(Map<String, dynamic> data) {
    if (data['routes'] == null || data['routes'].isEmpty) {
      throw Exception('No route found');
    }

    final route = data['routes'][0];
    final legs = route['legs'][0];
    final steps = legs['steps'] as List;
    
    List<NavigationInstruction> instructions = [];
    List<LatLng> points = [];

    // Parse route geometry
    final geometry = route['geometry']['coordinates'] as List;
    points = geometry.map((coord) {
      return LatLng(coord[1].toDouble(), coord[0].toDouble());
    }).toList();

    // Parse instructions
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final maneuver = step['maneuver'];
      
      String nextInstruction = '';
      if (i < steps.length - 1) {
        nextInstruction = _formatInstruction(steps[i + 1]);
      }

      instructions.add(NavigationInstruction(
        mainInstruction: _getMainInstruction(step),
        secondaryInstruction: step['name'] ?? '',
        nextInstruction: nextInstruction,
        distance: step['distance'].toDouble(),
        duration: step['duration'].toDouble(),
        location: LatLng(
          maneuver['location'][1].toDouble(),
          maneuver['location'][0].toDouble(),
        ),
        bearing: maneuver['bearing_after'].toDouble(),
        maneuver: _parseManeuver(step),
      ));
    }

    return RouteData(instructions: instructions, points: points);
  }

  String _getMainInstruction(Map<String, dynamic> step) {
    final type = step['maneuver']['type'];
    final modifier = step['maneuver']['modifier'];

    switch (type) {
      case 'turn':
        return 'Turn ${modifier ?? 'ahead'}';
      case 'new name':
        return 'Continue onto ${step['name'] ?? 'the street'}';
      case 'depart':
        return 'Start navigation';
      case 'arrive':
        return 'Arrive at destination';
      case 'roundabout':
        return 'Enter roundabout';
      case 'merge':
        return 'Merge ${modifier ?? 'ahead'}';
      case 'end of road':
        return 'Turn ${modifier ?? 'ahead'} at end of road';
      default:
        return 'Continue ${modifier ?? 'straight'}';
    }
  }

  String _formatInstruction(Map<String, dynamic> step) {
    final mainInstruction = _getMainInstruction(step);
    final name = step['name'] ?? '';
    return '$mainInstruction${name.isNotEmpty ? ' onto $name' : ''}';
  }

  NavigationManeuver _parseManeuver(Map<String, dynamic> step) {
    final type = step['maneuver']['type'];
    final modifier = step['maneuver']['modifier'];

    switch (type) {
      case 'turn':
        switch (modifier) {
          case 'right':
            return NavigationManeuver.turnRight;
          case 'left':
            return NavigationManeuver.turnLeft;
          case 'slight right':
            return NavigationManeuver.slightRight;
          case 'slight left':
            return NavigationManeuver.slightLeft;
          case 'sharp right':
            return NavigationManeuver.sharpRight;
          case 'sharp left':
            return NavigationManeuver.sharpLeft;
          default:
            return NavigationManeuver.straight;
        }
      case 'roundabout':
        return NavigationManeuver.roundabout;
      case 'merge':
        return NavigationManeuver.merge;
      case 'exit':
        return NavigationManeuver.exit;
      case 'arrive':
        return NavigationManeuver.arrive;
      default:
        return NavigationManeuver.straight;
    }
  }

  void updateUserLocation(LatLng newLocation) {
    if (!_isNavigating) return;

    final distanceToNextInstruction = _calculateDistance(
      newLocation,
      _instructions[_currentInstructionIndex].location,
    );

    // Check if off route
    final isOffRoute = _isOffRoute(newLocation);
    if (isOffRoute) {
      _handleRerouting(newLocation);
      return;
    }

    // Update progress
    _updateRouteProgress(newLocation);

    // Check if we should move to next instruction
    if (distanceToNextInstruction < 20) { // 20 meters threshold
      _moveToNextInstruction();
    } else if (distanceToNextInstruction < ANNOUNCE_THRESHOLD) {
      // Announce upcoming turn
      _announceUpcomingTurn(distanceToNextInstruction);
    }

    _lastUserLocation = newLocation;
  }

  void _updateRouteProgress(LatLng currentLocation) {
    // Calculate progress based on distance covered
    double totalDistance = 0;
    double coveredDistance = 0;
    
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final segmentDistance = _calculateDistance(_routePoints[i], _routePoints[i + 1]);
      totalDistance += segmentDistance;
      
      if (i < _currentInstructionIndex) {
        coveredDistance += segmentDistance;
      }
    }

    final progress = (coveredDistance / totalDistance) * 100;
    _routeProgressController.add(progress);
  }

  bool _isOffRoute(LatLng location) {
    // Find nearest point on route
    double minDistance = double.infinity;
    for (final point in _routePoints) {
      final distance = _calculateDistance(location, point);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance > REROUTE_THRESHOLD;
  }

  void _handleRerouting(LatLng currentLocation) {
    // Emit rerouting instruction
    final rerouteInstruction = NavigationInstruction(
      mainInstruction: 'Rerouting...',
      secondaryInstruction: 'Finding new route',
      nextInstruction: '',
      distance: 0,
      duration: 0,
      location: currentLocation,
      bearing: 0,
      maneuver: NavigationManeuver.straight,
    );
    _navigationController.add(rerouteInstruction);

    // Fetch new route
    if (_instructions.isNotEmpty) {
      final destination = _instructions.last.location;
      startNavigation(currentLocation, destination);
    }
  }

  void _moveToNextInstruction() {
    if (_currentInstructionIndex < _instructions.length - 1) {
      _currentInstructionIndex++;
      _emitCurrentInstruction();
    }
  }

  void _announceUpcomingTurn(double distance) {
    if (_currentInstructionIndex < _instructions.length - 1) {
      final nextInstruction = _instructions[_currentInstructionIndex];
      final previewInstruction = NavigationInstruction(
        mainInstruction: nextInstruction.mainInstruction,
        secondaryInstruction: 'In ${distance.round()} meters',
        nextInstruction: '',
        distance: distance,
        duration: nextInstruction.duration,
        location: nextInstruction.location,
        bearing: nextInstruction.bearing,
        maneuver: nextInstruction.maneuver,
        isNextTurnPreview: true,
      );
      _navigationController.add(previewInstruction);
    }
  }

  void _emitCurrentInstruction() {
    if (_currentInstructionIndex < _instructions.length) {
      _navigationController.add(_instructions[_currentInstructionIndex]);
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  void stopNavigation() {
    _isNavigating = false;
    _instructions.clear();
    _routePoints.clear();
    _currentInstructionIndex = 0;
  }

  void dispose() {
    _navigationController.close();
    _routeProgressController.close();
  }
}

class RouteData {
  final List<NavigationInstruction> instructions;
  final List<LatLng> points;

  RouteData({required this.instructions, required this.points});
}





















// import 'dart:async';
// import 'dart:math' as math;
// import 'package:latlong2/latlong.dart';
// import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/navigation_instruction.dart';

// class NavigationService {
//   static const double REROUTE_THRESHOLD = 50.0; // meters
//   final _navigationController = StreamController<NavigationInstruction>.broadcast();
//   Timer? _locationCheckTimer;
//   List<NavigationInstruction> _currentInstructions = [];
//   int _currentInstructionIndex = 0;
  
//   Stream<NavigationInstruction> get navigationStream => _navigationController.stream;

//   void startNavigation(List<NavigationInstruction> instructions) {
//     _currentInstructions = instructions;
//     _currentInstructionIndex = 0;
//     _emitCurrentInstruction();
//   }

//   void updateUserLocation(LatLng userLocation) {
//     if (_currentInstructions.isEmpty) return;
    
//     // Check if user is off route
//     double distanceFromRoute = _calculateDistanceFromRoute(userLocation);
//     if (distanceFromRoute > REROUTE_THRESHOLD) {
//       _navigationController.add(
//         NavigationInstruction(
//           turnType: TurnType.straight,
//           instruction: "Rerouting...",
//           distance: 0,
//           duration: 0,
//           location: userLocation,
//           bearing: 0,
//         ),
//       );
//       // Trigger reroute calculation
//       return;
//     }

//     // Check if user has reached next instruction point
//     var nextInstruction = _currentInstructions[_currentInstructionIndex];
//     double distanceToNext = _calculateDistance(
//       userLocation,
//       nextInstruction.location,
//     );

//     if (distanceToNext < 20) { // Within 20 meters of instruction point
//       _moveToNextInstruction();
//     }
//   }

//   void _moveToNextInstruction() {
//     if (_currentInstructionIndex < _currentInstructions.length - 1) {
//       _currentInstructionIndex++;
//       _emitCurrentInstruction();
//     }
//   }

//   void _emitCurrentInstruction() {
//     if (_currentInstructionIndex < _currentInstructions.length) {
//       _navigationController.add(_currentInstructions[_currentInstructionIndex]);
//     }
//   }

//   double _calculateDistanceFromRoute(LatLng point) {
//     // Simplified version - in reality, you'd calculate distance to nearest route segment
//     if (_currentInstructions.isEmpty) return double.infinity;
    
//     return _calculateDistance(point, _currentInstructions[_currentInstructionIndex].location);
//   }

//   double _calculateDistance(LatLng point1, LatLng point2) {
//     var p = 0.017453292519943295; // Math.PI / 180
//     var a = 0.5 -
//         math.cos((point2.latitude - point1.latitude) * p) / 2 +
//         math.cos(point1.latitude * p) *
//             math.cos(point2.latitude * p) *
//             (1 - math.cos((point2.longitude - point1.longitude) * p)) /
//             2;
//     return 12742 * math.asin(math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
//   }

//   void dispose() {
//     _locationCheckTimer?.cancel();
//     _navigationController.close();
//   }
// }