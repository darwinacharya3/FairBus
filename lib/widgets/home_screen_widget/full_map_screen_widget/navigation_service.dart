import 'dart:async';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/navigation_instruction.dart';

class NavigationService {
  static const double REROUTE_THRESHOLD = 50.0; // meters
  final _navigationController = StreamController<NavigationInstruction>.broadcast();
  Timer? _locationCheckTimer;
  List<NavigationInstruction> _currentInstructions = [];
  int _currentInstructionIndex = 0;
  
  Stream<NavigationInstruction> get navigationStream => _navigationController.stream;

  void startNavigation(List<NavigationInstruction> instructions) {
    _currentInstructions = instructions;
    _currentInstructionIndex = 0;
    _emitCurrentInstruction();
  }

  void updateUserLocation(LatLng userLocation) {
    if (_currentInstructions.isEmpty) return;
    
    // Check if user is off route
    double distanceFromRoute = _calculateDistanceFromRoute(userLocation);
    if (distanceFromRoute > REROUTE_THRESHOLD) {
      _navigationController.add(
        NavigationInstruction(
          turnType: TurnType.straight,
          instruction: "Rerouting...",
          distance: 0,
          duration: 0,
          location: userLocation,
          bearing: 0,
        ),
      );
      // Trigger reroute calculation
      return;
    }

    // Check if user has reached next instruction point
    var nextInstruction = _currentInstructions[_currentInstructionIndex];
    double distanceToNext = _calculateDistance(
      userLocation,
      nextInstruction.location,
    );

    if (distanceToNext < 20) { // Within 20 meters of instruction point
      _moveToNextInstruction();
    }
  }

  void _moveToNextInstruction() {
    if (_currentInstructionIndex < _currentInstructions.length - 1) {
      _currentInstructionIndex++;
      _emitCurrentInstruction();
    }
  }

  void _emitCurrentInstruction() {
    if (_currentInstructionIndex < _currentInstructions.length) {
      _navigationController.add(_currentInstructions[_currentInstructionIndex]);
    }
  }

  double _calculateDistanceFromRoute(LatLng point) {
    // Simplified version - in reality, you'd calculate distance to nearest route segment
    if (_currentInstructions.isEmpty) return double.infinity;
    
    return _calculateDistance(point, _currentInstructions[_currentInstructionIndex].location);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 -
        math.cos((point2.latitude - point1.latitude) * p) / 2 +
        math.cos(point1.latitude * p) *
            math.cos(point2.latitude * p) *
            (1 - math.cos((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void dispose() {
    _locationCheckTimer?.cancel();
    _navigationController.close();
  }
}