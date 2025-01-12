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
    if (routePoints.isEmpty) return MapBounds(center: LatLng(27.7172, 85.3240), zoom: 14.0);

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

    final steps = data['routes'][0]['legs'][0]['steps'] as List;
    return steps.map((step) {
      final location = LatLng(
        step['maneuver']['location'][1],
        step['maneuver']['location'][0],
      );

      return NavigationInstruction(
        turnType: _parseTurnType(step['maneuver']['type']),
        instruction: step['maneuver']['instruction'] ?? 'Continue straight',
        distance: step['distance'].toDouble(),
        duration: step['duration'].toDouble(),
        location: location,
        bearing: step['maneuver']['bearing_after'].toDouble(),
      );
    }).toList();
  }

  TurnType _parseTurnType(String type) {
    switch (type) {
      case 'turn':
        return TurnType.right;
      case 'new name':
        return TurnType.straight;
      case 'depart':
        return TurnType.straight;
      case 'arrive':
        return TurnType.finish;
      case 'roundabout':
        return TurnType.roundabout;
      case 'merge':
        return TurnType.slightRight;
      case 'on ramp':
        return TurnType.slightRight;
      case 'off ramp':
        return TurnType.slightRight;
      case 'fork':
        return TurnType.slightRight;
      case 'end of road':
        return TurnType.right;
      case 'use lane':
        return TurnType.straight;
      case 'continue':
        return TurnType.straight;
      default:
        return TurnType.straight;
    }
  }
}
