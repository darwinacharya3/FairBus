import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/navigation_instruction.dart';

class MapService {
  static const Map<String, String> mapLayerOptions = {
    "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
  };

  Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
    final url = "http://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['routes'].isEmpty) {
        throw Exception("No route found");
      }

      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
      return coordinates
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();
    } else {
      throw Exception("Failed to fetch route");
    }
  }

  MapBounds calculateRouteBounds(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return MapBounds(center: const LatLng(27.7172, 85.3240), zoom: 14.0);

    double minLat = routePoints.map((p) => p.latitude).reduce(math.min);
    double maxLat = routePoints.map((p) => p.latitude).reduce(math.max);
    double minLng = routePoints.map((p) => p.longitude).reduce(math.min);
    double maxLng = routePoints.map((p) => p.longitude).reduce(math.max);

    double padding = 0.01;
    LatLng sw = LatLng(minLat - padding, minLng - padding);
    LatLng ne = LatLng(maxLat + padding, maxLng + padding);
    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    
    return MapBounds(
      center: center,
      zoom: _calculateZoomLevel(sw, ne),
    );
  }

  double _calculateZoomLevel(LatLng sw, LatLng ne) {
    double latDiff = (ne.latitude - sw.latitude).abs();
    double lngDiff = (ne.longitude - sw.longitude).abs();
    double maxDiff = math.max(latDiff, lngDiff);
    
    if (maxDiff > 0.5) return 10;
    if (maxDiff > 0.2) return 11;
    if (maxDiff > 0.1) return 12;
    if (maxDiff > 0.05) return 13;
    return 14;
  }
}

class MapBounds {
  final LatLng center;
  final double zoom;

  MapBounds({required this.center, required this.zoom});
}

extension NavigationMapService on MapService {
  Future<List<NavigationInstruction>> getNavigationInstructions(
    LatLng start,
    LatLng end,
  ) async {
    final url = "http://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}"
        "?steps=true&annotations=true&geometries=geojson&overview=full";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch route instructions");
    }

    final data = jsonDecode(response.body);
    if (data['routes'].isEmpty) {
      throw Exception("No route found");
    }

    final List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];
    List<NavigationInstruction> instructions = [];
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final maneuver = step['maneuver'];
      final location = LatLng(
        maneuver['location'][1].toDouble(),
        maneuver['location'][0].toDouble(),
      );

      // Get the next maneuver point for better instruction timing
      LatLng? nextLocation;
      if (i < steps.length - 1) {
        nextLocation = LatLng(
          steps[i + 1]['maneuver']['location'][1].toDouble(),
          steps[i + 1]['maneuver']['location'][0].toDouble(),
        );
      }

      String instruction = _generateInstruction(step, maneuver);
      
      instructions.add(NavigationInstruction(
        turnType: _parseTurnType(maneuver['type'], maneuver['modifier']),
        instruction: instruction,
        distance: step['distance'].toDouble(),
        duration: step['duration'].toDouble(),
        location: location,
        bearing: maneuver['bearing_after'].toDouble(),
      ));
    }

    return instructions;
  }

  String _generateInstruction(dynamic step, dynamic maneuver) {
    String baseInstruction = step['name'] != ""
        ? "Continue onto ${step['name']}"
        : "Continue straight";

    switch (maneuver['type']) {
      case 'turn':
        return "Turn ${maneuver['modifier']} onto ${step['name']}";
      case 'roundabout':
        return "Enter roundabout and take exit ${maneuver['exit']}";
      case 'arrive':
        return "Arrive at destination";
      default:
        return baseInstruction;
    }
  }

  TurnType _parseTurnType(String type, String? modifier) {
    if (type == 'arrive') return TurnType.finish;
    if (type == 'roundabout') return TurnType.roundabout;

    switch (modifier) {
      case 'straight':
        return TurnType.straight;
      case 'slight right':
        return TurnType.slightRight;
      case 'right':
        return TurnType.right;
      case 'sharp right':
        return TurnType.sharpRight;
      case 'slight left':
        return TurnType.slightLeft;
      case 'left':
        return TurnType.left;
      case 'sharp left':
        return TurnType.sharpLeft;
      case 'uturn':
        return TurnType.uTurn;
      default:
        return TurnType.straight;
    }
  }
}
