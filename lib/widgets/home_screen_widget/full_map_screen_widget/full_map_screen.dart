import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/location_service.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/map_service.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/bus_stop.dart';


class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final PopupController _popupController = PopupController();
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  
  String _selectedLayer = "Default";
  LatLng? _userLocation;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  List<LatLng> _routeCoordinates = [];
  double _currentZoom = 14.0;

  bool _isLoadingRoute = false;
  String _routeError = '';

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    if (await _locationService.checkAndRequestPermissions()) {
      final location = await _locationService.getCurrentLocation();
      setState(() => _userLocation = location);

      _locationService.getLocationStream().listen((location) {
        setState(() => _userLocation = location);
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both start and end points.")),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = '';
      _routeCoordinates = [];
    });

    try {
      final startLocation = await _locationService.getCoordinatesFromLocation(_startController.text);
      if (startLocation == null) {
        throw Exception("Could not find start location");
      }

      final endLocation = await _locationService.getCoordinatesFromLocation(_endController.text);
      if (endLocation == null) {
        throw Exception("Could not find end location");
      }

      final routePoints = await _mapService.fetchRoute(startLocation, endLocation);
      final bounds = _mapService.calculateRouteBounds(routePoints);

      setState(() {
        _routeCoordinates = routePoints;
        _mapController.move(bounds.center, bounds.zoom);
      });
    } catch (e) {
      setState(() => _routeError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route Map'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240),
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _currentZoom = position.zoom ?? _currentZoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapService.mapLayerOptions[_selectedLayer]!,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              if (_routeCoordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeCoordinates,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  markers: BusStopData.stops.map((stop) {
                    return Marker(
                      width: 80.0,
                      height: 80.0,
                      point: stop.location,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30.0,
                      ),
                    );
                  }).toList(),
                  popupController: _popupController,
                  markerTapBehavior: MarkerTapBehavior.togglePopup(),
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) {
                      final stop = BusStopData.stops.firstWhere(
                        (s) => s.location == marker.point,
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text('Additional details about this stop'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _userLocation!,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          _buildLayerSelector(),
          _buildRouteInputs(),
        ],
      ),
    );
  }

  Widget _buildLayerSelector() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: _selectedLayer,
          onChanged: (value) => setState(() => _selectedLayer = value!),
          items: MapService.mapLayerOptions.keys.map((layer) {
            return DropdownMenuItem<String>(
              value: layer,
              child: Text(
                layer,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          dropdownColor: Colors.green.shade100,
          underline: Container(),
        ),
      ),
    );
  }

  Widget _buildRouteInputs() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _startController,
                decoration: const InputDecoration(
                  labelText: "Start Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: "End Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: _isLoadingRoute ? null : _fetchRoute,
                child: _isLoadingRoute
                    ? const CircularProgressIndicator()
                    : const Text("Find Route"),
              ),
              if (_routeError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _routeError,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}













// import 'dart:convert';
// import 'dart:math' as math; // Added for min/max functions
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart';
// import 'package:geocoding/geocoding.dart' as geocoding; // Changed import

// class FullMapScreen extends StatefulWidget {
//   const FullMapScreen({super.key});

//   @override
//   State<FullMapScreen> createState() => _FullMapScreenState();
// }

// class _FullMapScreenState extends State<FullMapScreen> {
//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)},
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)},
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)},
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)},
//     const {"name": "Balaju", "location": LatLng(27.7358, 85.3051)},
//   ];

//   final PopupController _popupController = PopupController();
//   final MapController _mapController = MapController();

//   String _selectedLayer = "Default";
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   LatLng? _userLocation;
//   final Location _location = Location();
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _endController = TextEditingController();
//   List<LatLng> _routeCoordinates = [];
//   double _currentZoom = 14.0;

//   bool _isLoadingRoute = false;
//   String _routeError = '';

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationTracking();
//   }

//   Future<void> _initializeLocationTracking() async {
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) return;
//     }

//     PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) return;
//     }

//     final userLocation = await _location.getLocation();
//     setState(() {
//       _userLocation = LatLng(userLocation.latitude!, userLocation.longitude!);
//     });

//     _location.onLocationChanged.listen((newLocation) {
//       setState(() {
//         _userLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
//       });
//     });
//   }

//   LatLng? _findBusStopLocation(String stopName) {
//     try {
//       final stop = busStops.firstWhere(
//         (stop) => stop['name'].toLowerCase() == stopName.toLowerCase().trim(),
//       );
//       return stop['location'] as LatLng;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<LatLng?> _getCoordinatesFromLocation(String locationName) async {
//     try {
//       // First check if it's a predefined bus stop
//       LatLng? busStopLocation = _findBusStopLocation(locationName);
//       if (busStopLocation != null) {
//         return busStopLocation;
//       }

//       // If not a bus stop, try geocoding
//       List<geocoding.Location> locations = await geocoding.locationFromAddress(
//           locationName + ", Kathmandu, Nepal");
//       if (locations.isNotEmpty) {
//         return LatLng(locations.first.latitude, locations.first.longitude);
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> _fetchRoute() async {
//     if (_startController.text.isEmpty || _endController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter both start and end points.")),
//       );
//       return;
//     }

//     setState(() {
//       _isLoadingRoute = true;
//       _routeError = '';
//       _routeCoordinates = [];
//     });

//     try {
//       final startLocation = await _getCoordinatesFromLocation(_startController.text);
//       if (startLocation == null) {
//         throw Exception("Could not find start location");
//       }

//       final endLocation = await _getCoordinatesFromLocation(_endController.text);
//       if (endLocation == null) {
//         throw Exception("Could not find end location");
//       }

//       final url = "http://router.project-osrm.org/route/v1/driving/"
//           "${startLocation.longitude},${startLocation.latitude};"
//           "${endLocation.longitude},${endLocation.latitude}"
//           "?overview=full&geometries=geojson";

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
        
//         if (data['routes'].isEmpty) {
//           throw Exception("No route found");
//         }

//         final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
//         final List<LatLng> routePoints = coordinates
//             .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
//             .toList();

//         setState(() {
//           _routeCoordinates = routePoints;
          
//           // Calculate bounds for the route
//           if (routePoints.isNotEmpty) {
//             double minLat = routePoints
//                 .map((p) => p.latitude)
//                 .reduce((a, b) => math.min(a, b));
//             double maxLat = routePoints
//                 .map((p) => p.latitude)
//                 .reduce((a, b) => math.max(a, b));
//             double minLng = routePoints
//                 .map((p) => p.longitude)
//                 .reduce((a, b) => math.min(a, b));
//             double maxLng = routePoints
//                 .map((p) => p.longitude)
//                 .reduce((a, b) => math.max(a, b));

//             // Create a padding around the bounds
//             double padding = 0.01; // Approximately 1km
//             LatLng sw = LatLng(minLat - padding, minLng - padding);
//             LatLng ne = LatLng(maxLat + padding, maxLng + padding);
            
//             // Center the map on the route
//             LatLng center = LatLng(
//               (minLat + maxLat) / 2,
//               (minLng + maxLng) / 2,
//             );
            
//             // Calculate appropriate zoom level
//             double zoom = _calculateZoomLevel(sw, ne);
//             _mapController.move(center, zoom);
//           }
//         });
//       } else {
//         throw Exception("Failed to fetch route");
//       }
//     } catch (e) {
//       setState(() {
//         _routeError = e.toString();
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     } finally {
//       setState(() {
//         _isLoadingRoute = false;
//       });
//     }
//   }

//   // Helper method to calculate appropriate zoom level
//   double _calculateZoomLevel(LatLng sw, LatLng ne) {
//     double latDiff = (ne.latitude - sw.latitude).abs();
//     double lngDiff = (ne.longitude - sw.longitude).abs();
//     double maxDiff = math.max(latDiff, lngDiff);
    
//     // This is a simple approximation. Adjust these values based on your needs
//     if (maxDiff > 0.5) return 10;      // Very large distance
//     if (maxDiff > 0.2) return 11;      // Large distance
//     if (maxDiff > 0.1) return 12;      // Medium distance
//     if (maxDiff > 0.05) return 13;     // Shorter distance
//     return 14;                         // Default zoom
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green,
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240),
//               initialZoom: _currentZoom,
//               onPositionChanged: (position, hasGesture) {
//                 if (hasGesture) {
//                   setState(() {
//                     _currentZoom = position.zoom ?? _currentZoom;
//                   });
//                 }
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app',
//               ),
//               if (_routeCoordinates.isNotEmpty)
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: _routeCoordinates,
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//               PopupMarkerLayer(
//                 options: PopupMarkerLayerOptions(
//                   markers: busStops.map((stop) {
//                     return Marker(
//                       width: 80.0,
//                       height: 80.0,
//                       point: stop['location'],
//                       child: const Icon(
//                         Icons.location_on,
//                         color: Colors.red,
//                         size: 30.0,
//                       ),
//                     );
//                   }).toList(),
//                   popupController: _popupController,
//                   markerTapBehavior: MarkerTapBehavior.togglePopup(),
//                   popupDisplayOptions: PopupDisplayOptions(
//                     builder: (context, marker) {
//                       final stop = busStops.firstWhere(
//                         (s) => s['location'] == marker.point,
//                       );
//                       return Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 stop['name'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16.0,
//                                 ),
//                               ),
//                               const SizedBox(height: 8.0),
//                               const Text('Additional details about this stop'),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               if (_userLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       width: 40.0,
//                       height: 40.0,
//                       point: _userLocation!,
//                       child: const Icon(
//                         Icons.person_pin_circle,
//                         color: Colors.blue,
//                         size: 40.0,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButton<String>(
//                 value: _selectedLayer,
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedLayer = value!;
//                   });
//                 },
//                 items: _mapLayerOptions.keys.map((layer) {
//                   return DropdownMenuItem<String>(
//                     value: layer,
//                     child: Text(
//                       layer,
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                   );
//                 }).toList(),
//                 dropdownColor: Colors.green.shade100,
//                 underline: Container(),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: _startController,
//                       decoration: const InputDecoration(
//                         labelText: "Start Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     TextField(
//                       controller: _endController,
//                       decoration: const InputDecoration(
//                         labelText: "End Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     ElevatedButton(
//                       onPressed: _isLoadingRoute ? null : _fetchRoute,
//                       child: _isLoadingRoute
//                           ? const CircularProgressIndicator()
//                           : const Text("Find Route"),
//                     ),
//                     if (_routeError.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           _routeError,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart';
// import 'package:geocoding/geocoding.dart';

// class FullMapScreen extends StatefulWidget {
//   const FullMapScreen({super.key});

//   @override
//   State<FullMapScreen> createState() => _FullMapScreenState();
// }

// class _FullMapScreenState extends State<FullMapScreen> {
//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)},
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)},
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)},
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)},
//     const {"name": "Balaju", "location": LatLng(27.7358, 85.3051)}, // Added Balaju
//   ];

//   final PopupController _popupController = PopupController();
//   final MapController _mapController = MapController();

//   String _selectedLayer = "Default";
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   LatLng? _userLocation;
//   final Location _location = Location();
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _endController = TextEditingController();
//   List<LatLng> _routeCoordinates = [];
//   double _currentZoom = 14.0;

//   // New variables for route visualization
//   bool _isLoadingRoute = false;
//   String _routeError = '';
//   LatLngBounds? _routeBounds;

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationTracking();
//   }

//   Future<void> _initializeLocationTracking() async {
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) return;
//     }

//     PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) return;
//     }

//     final userLocation = await _location.getLocation();
//     setState(() {
//       _userLocation = LatLng(userLocation.latitude!, userLocation.longitude!);
//     });

//     _location.onLocationChanged.listen((newLocation) {
//       setState(() {
//         _userLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
//       });
//     });
//   }

//   // Helper method to find bus stop coordinates
//   LatLng? _findBusStopLocation(String stopName) {
//     try {
//       final stop = busStops.firstWhere(
//         (stop) => stop['name'].toLowerCase() == stopName.toLowerCase().trim(),
//       );
//       return stop['location'] as LatLng;
//     } catch (e) {
//       return null;
//     }
//   }

//   // Helper method to get coordinates from location name
//   Future<LatLng?> _getCoordinatesFromLocation(String locationName) async {
//     try {
//       // First check if it's a predefined bus stop
//       LatLng? busStopLocation = _findBusStopLocation(locationName);
//       if (busStopLocation != null) {
//         return busStopLocation;
//       }

//       // If not a bus stop, try geocoding
//       List<Location> locations = await locationFromAddress(locationName + ", Kathmandu, Nepal");
//       if (locations.isNotEmpty) {
//         return LatLng(locations.first.latitude, locations.first.longitude);
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> _fetchRoute() async {
//     if (_startController.text.isEmpty || _endController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter both start and end points.")),
//       );
//       return;
//     }

//     setState(() {
//       _isLoadingRoute = true;
//       _routeError = '';
//       _routeCoordinates = [];
//     });

//     try {
//       // Get coordinates for start location
//       final startLocation = await _getCoordinatesFromLocation(_startController.text);
//       if (startLocation == null) {
//         throw Exception("Could not find start location");
//       }

//       // Get coordinates for end location
//       final endLocation = await _getCoordinatesFromLocation(_endController.text);
//       if (endLocation == null) {
//         throw Exception("Could not find end location");
//       }

//       // Fetch route from OSRM
//       final url = "http://router.project-osrm.org/route/v1/driving/"
//           "${startLocation.longitude},${startLocation.latitude};"
//           "${endLocation.longitude},${endLocation.latitude}"
//           "?overview=full&geometries=geojson";

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
        
//         if (data['routes'].isEmpty) {
//           throw Exception("No route found");
//         }

//         final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
//         final List<LatLng> routePoints = coordinates
//             .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
//             .toList();

//         setState(() {
//           _routeCoordinates = routePoints;
          
//           // Calculate route bounds
//           if (routePoints.isNotEmpty) {
//             double minLat = routePoints.map((p) => p.latitude).reduce(min);
//             double maxLat = routePoints.map((p) => p.latitude).reduce(max);
//             double minLng = routePoints.map((p) => p.longitude).reduce(min);
//             double maxLng = routePoints.map((p) => p.longitude).reduce(max);
            
//             _routeBounds = LatLngBounds(
//               LatLng(minLat, minLng),
//               LatLng(maxLat, maxLng),
//             );
            
//             // Fit map to route bounds with padding
//             _mapController.fitBounds(
//               _routeBounds!,
//               options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
//             );
//           }
//         });
//       } else {
//         throw Exception("Failed to fetch route");
//       }
//     } catch (e) {
//       setState(() {
//         _routeError = e.toString();
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     } finally {
//       setState(() {
//         _isLoadingRoute = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green,
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240),
//               initialZoom: _currentZoom,
//               onPositionChanged: (position, hasGesture) {
//                 if (hasGesture) {
//                   setState(() {
//                     _currentZoom = position.zoom ?? _currentZoom;
//                   });
//                 }
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app',
//               ),
//               if (_routeCoordinates.isNotEmpty)
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: _routeCoordinates,
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//               PopupMarkerLayer(
//                 options: PopupMarkerLayerOptions(
//                   markers: busStops.map((stop) {
//                     return Marker(
//                       width: 80.0,
//                       height: 80.0,
//                       point: stop['location'],
//                       child: const Icon(
//                         Icons.location_on,
//                         color: Colors.red,
//                         size: 30.0,
//                       ),
//                     );
//                   }).toList(),
//                   popupController: _popupController,
//                   markerTapBehavior: MarkerTapBehavior.togglePopup(),
//                   popupDisplayOptions: PopupDisplayOptions(
//                     builder: (context, marker) {
//                       final stop = busStops.firstWhere(
//                         (s) => s['location'] == marker.point,
//                       );
//                       return Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 stop['name'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16.0,
//                                 ),
//                               ),
//                               const SizedBox(height: 8.0),
//                               const Text('Additional details about this stop'),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               if (_userLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       width: 40.0,
//                       height: 40.0,
//                       point: _userLocation!,
//                       child: const Icon(
//                         Icons.person_pin_circle,
//                         color: Colors.blue,
//                         size: 40.0,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButton<String>(
//                 value: _selectedLayer,
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedLayer = value!;
//                   });
//                 },
//                 items: _mapLayerOptions.keys.map((layer) {
//                   return DropdownMenuItem<String>(
//                     value: layer,
//                     child: Text(
//                       layer,
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                   );
//                 }).toList(),
//                 dropdownColor: Colors.green.shade100,
//                 underline: Container(),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: _startController,
//                       decoration: const InputDecoration(
//                         labelText: "Start Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     TextField(
//                       controller: _endController,
//                       decoration: const InputDecoration(
//                         labelText: "End Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     ElevatedButton(
//                       onPressed: _isLoadingRoute ? null : _fetchRoute,
//                       child: _isLoadingRoute
//                           ? const CircularProgressIndicator()
//                           : const Text("Find Route"),
//                     ),
//                     if (_routeError.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           _routeError,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart';

// class FullMapScreen extends StatefulWidget {
//   const FullMapScreen({super.key});

//   @override
//   State<FullMapScreen> createState() => _FullMapScreenState();
// }

// class _FullMapScreenState extends State<FullMapScreen> {
//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

//   final PopupController _popupController = PopupController();
//   final MapController _mapController = MapController();

//   // Selected map layer
//   String _selectedLayer = "Default";

//   // Map layer options
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   // Variables for real-time location tracking
//   LatLng? _userLocation;
//   final Location _location = Location();

//   // Variables for route directions
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _endController = TextEditingController();
//   List<LatLng> _routeCoordinates = [];

//   // Track zoom level manually
//   double _currentZoom = 14.0;

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationTracking();
//   }

//   Future<void> _initializeLocationTracking() async {
//     // Request location permissions
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) return;
//     }

//     PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) return;
//     }

//     // Get the initial location
//     final userLocation = await _location.getLocation();
//     setState(() {
//       _userLocation = LatLng(userLocation.latitude!, userLocation.longitude!);
//     });

//     // Listen to location updates
//     _location.onLocationChanged.listen((newLocation) {
//       setState(() {
//         _userLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
//       });
//       if (_userLocation != null) {
//         // Use the tracked zoom level
//         _mapController.move(_userLocation!, _currentZoom);
//       }
//     });
//   }

//   Future<void> _fetchRoute() async {
//     if (_startController.text.isEmpty || _endController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter both start and end points.")),
//       );
//       return;
//     }

//     try {
//       final startStop = busStops.firstWhere(
//           (stop) => stop['name'].toLowerCase() == _startController.text.toLowerCase(),
//           // orElse: () => null
//           );
//       final endStop = busStops.firstWhere(
//           (stop) => stop['name'].toLowerCase() == _endController.text.toLowerCase(),
//           // orElse: () => null
//           );

//       if (startStop == null || endStop == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Invalid stop names.")),
//         );
//         return;
//       }

//       final start = startStop['location'];
//       final end = endStop['location'];

//       final url =
//           "http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson";

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

//         setState(() {
//           _routeCoordinates = coordinates
//               .map((coord) => LatLng(coord[1], coord[0]))
//               .toList();
//         });

//         // Move the map to focus on the route
//         _mapController.move(start, _currentZoom);
//       } else {
//         throw Exception("Failed to fetch route.");
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green,
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240),
//               initialZoom: _currentZoom,
//               onPositionChanged: (position, hasGesture) {
//                 if (hasGesture) {
//                   setState(() {
//                     _currentZoom = position.zoom ?? _currentZoom;
//                   });
//                 }
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app',
//               ),
//               if (_routeCoordinates.isNotEmpty)
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: _routeCoordinates,
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//               PopupMarkerLayer(
//                 options: PopupMarkerLayerOptions(
//                   markers: busStops.map((stop) {
//                     return Marker(
//                       width: 80.0,
//                       height: 80.0,
//                       point: stop['location'],
//                       child: const Icon(
//                         Icons.location_on,
//                         color: Colors.red,
//                         size: 30.0,
//                       ),
//                     );
//                   }).toList(),
//                   popupController: _popupController,
//                   markerTapBehavior: MarkerTapBehavior.togglePopup(),
//                   popupDisplayOptions: PopupDisplayOptions(
//                     builder: (context, marker) {
//                       final stop = busStops.firstWhere(
//                         (s) => s['location'] == marker.point,
//                       );
//                       return Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 stop['name'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16.0,
//                                 ),
//                               ),
//                               const SizedBox(height: 8.0),
//                               const Text('Additional details about this stop'),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               if (_userLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       width: 40.0,
//                       height: 40.0,
//                       point: _userLocation!,
//                       child: const Icon(
//                         Icons.person_pin_circle,
//                         color: Colors.blue,
//                         size: 40.0,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButton<String>(
//                 value: _selectedLayer,
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedLayer = value!;
//                   });
//                 },
//                 items: _mapLayerOptions.keys.map((layer) {
//                   return DropdownMenuItem<String>(
//                     value: layer,
//                     child: Text(
//                       layer,
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                   );
//                 }).toList(),
//                 dropdownColor: Colors.green.shade100,
//                 underline: Container(),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: _startController,
//                       decoration: const InputDecoration(
//                         labelText: "Start Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     TextField(
//                       controller: _endController,
//                       decoration: const InputDecoration(
//                         labelText: "End Location",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     ElevatedButton(
//                       onPressed: _fetchRoute,
//                       child: const Text("Find Route"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }










