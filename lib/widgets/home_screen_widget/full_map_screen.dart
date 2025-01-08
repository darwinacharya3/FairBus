import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  // Define static stops with their coordinates
  final List<Map<String, dynamic>> busStops = [
    const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
    const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
    const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
    const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
  ];

  final PopupController _popupController = PopupController();
  final MapController _mapController = MapController();

  // Selected map layer
  String _selectedLayer = "Default";

  // Map layer options
  final Map<String, String> _mapLayerOptions = {
    "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
  };

  // Variables for real-time location tracking
  LatLng? _userLocation;
  final Location _location = Location();

  // Track zoom level manually
  double _currentZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    // Request location permissions
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // Get the initial location
    final userLocation = await _location.getLocation();
    setState(() {
      _userLocation = LatLng(userLocation.latitude!, userLocation.longitude!);
    });

    // Listen to location updates
    _location.onLocationChanged.listen((newLocation) {
      setState(() {
        _userLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
      });
      if (_userLocation != null) {
        // Use the tracked zoom level
        _mapController.move(_userLocation!, _currentZoom);
      }
    });
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
              initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240), // Default location
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                // Update the zoom level when the map position changes
                if (hasGesture) {
                  setState(() {
                    _currentZoom = position.zoom ?? _currentZoom;
                  });
                }
              },
            ),
            children: [
              // Tile Layer for the selected map style
              TileLayer(
                urlTemplate: _mapLayerOptions[_selectedLayer]!,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              // Markers Layer for Bus Stops
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  markers: busStops.map((stop) {
                    return Marker(
                      width: 80.0,
                      height: 80.0,
                      point: stop['location'],
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
                      final stop = busStops.firstWhere(
                        (s) => s['location'] == marker.point,
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stop['name'],
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
              // User Location Marker
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
          // Floating button to toggle map layers
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedLayer,
                onChanged: (value) {
                  setState(() {
                    _selectedLayer = value!;
                  });
                },
                items: _mapLayerOptions.keys.map((layer) {
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
          ),
        ],
      ),
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
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
//         // Move the map to the new location, preserving the current zoom level
//         _mapController.move(_userLocation!, _mapController.zoom);
//       }
//     });
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
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240), // Default location
//               initialZoom: 14,
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app',
//               ),
//               // Markers Layer for Bus Stops
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
//               // User Location Marker
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
//           // Floating button to toggle map layers
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
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
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
//         _mapController.move(_userLocation!, 14); // Move the map to the new location
//       }
//     });
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
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240), // Default location
//               initialZoom: 14,
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app',
//               ),
//               // Markers Layer for Bus Stops
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
//               // User Location Marker
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
//           // Floating button to toggle map layers
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
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
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

//   // Selected map layer
//   String _selectedLayer = "Default";

//   // Map layer options
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   // Variables for real-time location tracking
//   LatLng? _userLocation;
//   Location _location = Location();

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationTracking();
//   }

//   Future<void> _initializeLocationTracking() async {
//     // Request location permissions
//     bool _serviceEnabled = await _location.serviceEnabled();
//     if (!_serviceEnabled) {
//       _serviceEnabled = await _location.requestService();
//       if (!_serviceEnabled) return;
//     }

//     PermissionStatus _permissionGranted = await _location.hasPermission();
//     if (_permissionGranted == PermissionStatus.denied) {
//       _permissionGranted = await _location.requestPermission();
//       if (_permissionGranted != PermissionStatus.granted) return;
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
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: MapOptions(
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240), // Center on user location
//               initialZoom: 14, // Adjusted zoom for better view of stops
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app', // Replace with your app's package name
//               ),
//               // Markers Layer for Bus Stops
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
//               // User Location Marker
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
//           // Floating button to toggle map layers
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100, // Match outer screen's color
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
//                 dropdownColor: Colors.green.shade100, // Match the outer screen's background
//                 underline: Container(), // Remove default underline
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
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

//   // Selected map layer
//   String _selectedLayer = "Default";

//   // Map layer options
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   // Variables for real-time location tracking
//   LatLng? _userLocation;
//   Location _location = Location();

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationTracking();
//   }

//   Future<void> _initializeLocationTracking() async {
//     // Request location permissions
//     bool _serviceEnabled = await _location.serviceEnabled();
//     if (!_serviceEnabled) {
//       _serviceEnabled = await _location.requestService();
//       if (!_serviceEnabled) return;
//     }

//     PermissionStatus _permissionGranted = await _location.hasPermission();
//     if (_permissionGranted == PermissionStatus.denied) {
//       _permissionGranted = await _location.requestPermission();
//       if (_permissionGranted != PermissionStatus.granted) return;
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
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: MapOptions(
//               initialCenter: _userLocation ?? const LatLng(27.7172, 85.3240), // Center on user location
//               initialZoom: 14, // Adjusted zoom for better view of stops
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app', // Replace with your app's package name
//               ),
//               // Markers Layer for Bus Stops
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
//               // User Location Marker
//               if (_userLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: _userLocation!,
//                       builder: (ctx) => const Icon(
//                         Icons.person_pin_circle,
//                         color: Colors.blue,
//                         size: 40.0,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           // Floating button to toggle map layers
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100, // Match outer screen's color
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
//                 dropdownColor: Colors.green.shade100, // Match the outer screen's background
//                 underline: Container(), // Remove default underline
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatefulWidget {
//   const FullMapScreen({super.key});

//   @override
//   State<FullMapScreen> createState() => _FullMapScreenState();
// }

// class _FullMapScreenState extends State<FullMapScreen> {
//   // Define static stops with their coordinates
//    final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Gwarko", "location": LatLng(27.6677, 85.3333)}, // Gwarko
//     const {"name": "Koteshwor", "location": LatLng(27.6789, 85.3494)}, // Koteshwor
//     const {"name": "Tinkune", "location": LatLng(27.6862, 85.3480)}, // Tinkune
//     const {"name": "Airport", "location": LatLng(27.695, 85.3545)}, // Airport
//     const {"name": "Gaushala", "location": LatLng(27.7084, 85.3435)}, // Gaushala
//     const {"name": "Chabahil", "location": LatLng(27.7173, 85.3466)}, // Chabahil
//     const {"name": "Gopikrishna Hall", "location": LatLng(27.7211, 85.3459)}, // Gopikrishna Hall
//     const {"name": "Dhumbarai", "location": LatLng(27.7320, 85.3440)}, // Dhumbarai
//     const {"name": "Chakrapath", "location": LatLng(27.74, 85.3370)}, // Chakrapath
//     const {"name": "Basundhara", "location": LatLng(27.742, 85.3334)}, // Basundhara
//     const {"name": "Samakhusi", "location": LatLng(27.7352, 85.3181)}, // Samakhusi
//     const {"name": "Gangabu", "location": LatLng(27.7346, 85.3145)}, // Gangabu
//     const {"name": "Machhapokhari", "location": LatLng(27.7353, 85.3058)}, // Machhapokhari
//     const {"name": "Balaju", "location": LatLng(27.7273, 85.3047)}, // Balaju
//     const {"name": "Banasthali", "location": LatLng(27.7249, 85.2982)}, // Banasthali
//     const {"name": "Swoyambhu", "location": LatLng(27.7161, 85.2836)}, // Swoyambhu
//     const {"name": "Sitapaila", "location": LatLng(27.7077, 85.2825)}, // Sitapaila
//     const {"name": "Bafal", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

//   final PopupController _popupController = PopupController();

//   // Selected map layer
//   String _selectedLayer = "Default";

//   // Map layer options
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     // "Traffic": "https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: const MapOptions(
//               initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//               initialZoom: 14, // Adjusted zoom for better view of stops
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app', // Replace with your app's package name
//               ),
//               // Markers Layer with Popups
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
//                       // Find the bus stop data for the tapped marker
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
//             ],
//           ),
//           // Floating button to toggle map layers
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100, // Match outer screen's color
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
//                 dropdownColor: Colors.green.shade100, // Match the outer screen's background
//                 underline: Container(), // Remove default underline
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:latlong2/latlong.dart';

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
//     // ... Add other stops here ...
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

//   final PopupController _popupController = PopupController();

//   // Selected map layer
//   String _selectedLayer = "Default";

//   // Map layer options
//   final Map<String, String> _mapLayerOptions = {
//     "Default": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//     "Traffic": "https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
//     "Terrain": "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: const MapOptions(
//               initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//               initialZoom: 14, // Adjusted zoom for better view of stops
//             ),
//             children: [
//               // Tile Layer for the selected map style
//               TileLayer(
//                 urlTemplate: _mapLayerOptions[_selectedLayer]!,
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.app', // Replace with your app's package name
//               ),
//               // Markers Layer with Popups
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
//                       // Find the bus stop data for the tapped marker
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
//             ],
//           ),
//           // Floating button to toggle map layers
//           Positioned(
//             top: 20,
//             right: 20,
//             child: DropdownButton<String>(
//               value: _selectedLayer,
//               onChanged: (value) {
//                 setState(() {
//                   _selectedLayer = value!;
//                 });
//               },
//               items: _mapLayerOptions.keys.map((layer) {
//                 return DropdownMenuItem<String>(
//                   value: layer,
//                   child: Text(layer),
//                 );
//               }).toList(),
//               dropdownColor: Colors.white,
//               style: const TextStyle(color: Colors.black),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatelessWidget {
//   FullMapScreen({super.key});

//    Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Gwarko", "location": LatLng(27.6677, 85.3333)}, // Gwarko
//     const {"name": "Koteshwor", "location": LatLng(27.6789, 85.3494)}, // Koteshwor
//     const {"name": "Tinkune", "location": LatLng(27.6862, 85.3480)}, // Tinkune
//     const {"name": "Airport", "location": LatLng(27.695, 85.3545)}, // Airport
//     const {"name": "Gaushala", "location": LatLng(27.7084, 85.3435)}, // Gaushala
//     const {"name": "Chabahil", "location": LatLng(27.7173, 85.3466)}, // Chabahil
//     const {"name": "Gopikrishna Hall", "location": LatLng(27.7211, 85.3459)}, // Gopikrishna Hall
//     const {"name": "Dhumbarai", "location": LatLng(27.7320, 85.3440)}, // Dhumbarai
//     const {"name": "Chakrapath", "location": LatLng(27.74, 85.3370)}, // Chakrapath
//     const {"name": "Basundhara", "location": LatLng(27.742, 85.3334)}, // Basundhara
//     const {"name": "Samakhusi", "location": LatLng(27.7352, 85.3181)}, // Samakhusi
//     const {"name": "Gangabu", "location": LatLng(27.7346, 85.3145)}, // Gangabu
//     const {"name": "Machhapokhari", "location": LatLng(27.7353, 85.3058)}, // Machhapokhari
//     const {"name": "Balaju", "location": LatLng(27.7273, 85.3047)}, // Balaju
//     const {"name": "Banasthali", "location": LatLng(27.7249, 85.2982)}, // Banasthali
//     const {"name": "Swoyambhu", "location": LatLng(27.7161, 85.2836)}, // Swoyambhu
//     const {"name": "Sitapaila", "location": LatLng(27.7077, 85.2825)}, // Sitapaila
//     const {"name": "Bafal", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

//   // Popup controller for handling popups
//   final PopupController _popupController = PopupController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: FlutterMap(
//         options: const MapOptions(
//           initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//           initialZoom: 14, // Adjusted zoom for better view of stops
//         ),
//         children: [
//           // Base Map Layer
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//             userAgentPackageName: 'com.example.app', // Replace with your app's package name
//           ),
//           // Markers Layer with Popups
//           PopupMarkerLayer(
//             options: PopupMarkerLayerOptions(
//               markers: busStops.map((stop) {
//                 return Marker(
//                   width: 80.0,
//                   height: 80.0,
//                   point: stop['location'],
//                   child: const Icon(
//                     Icons.location_on,
//                     color: Colors.red,
//                     size: 30.0,
//                   ),
//                 );
//               }).toList(),
//               popupController: _popupController,
//               markerTapBehavior: MarkerTapBehavior.togglePopup(),
//               popupDisplayOptions: PopupDisplayOptions(
//                 builder: (context, marker) {
//                   // Find the bus stop data for the tapped marker
//                   final stop = busStops.firstWhere(
//                     (s) => s['location'] == marker.point,
//                   );
//                   return Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             stop['name'],
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16.0,
//                             ),
//                           ),
//                           const SizedBox(height: 8.0),
//                           const Text('Additional details about this stop'),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatelessWidget {
//   FullMapScreen({super.key});

//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Gwarko", "location": LatLng(27.6677, 85.3333)}, // Gwarko
//     const {"name": "Koteshwor", "location": LatLng(27.6789, 85.3494)}, // Koteshwor
//     const {"name": "Tinkune", "location": LatLng(27.6862, 85.3480)}, // Tinkune
//     const {"name": "Airport", "location": LatLng(27.695, 85.3545)}, // Airport
//     const {"name": "Gaushala", "location": LatLng(27.7084, 85.3435)}, // Gaushala
//     const {"name": "Chabahil", "location": LatLng(27.7173, 85.3466)}, // Chabahil
//     const {"name": "Gopikrishna Hall", "location": LatLng(27.7211, 85.3459)}, // Gopikrishna Hall
//     const {"name": "Dhumbarai", "location": LatLng(27.7320, 85.3440)}, // Dhumbarai
//     const {"name": "Chakrapath", "location": LatLng(27.74, 85.3370)}, // Chakrapath
//     const {"name": "Basundhara", "location": LatLng(27.742, 85.3334)}, // Basundhara
//     const {"name": "Samakhusi", "location": LatLng(27.7352, 85.3181)}, // Samakhusi
//     const {"name": "Gangabu", "location": LatLng(27.7346, 85.3145)}, // Gangabu
//     const {"name": "Machhapokhari", "location": LatLng(27.7353, 85.3058)}, // Machhapokhari
//     const {"name": "Balaju", "location": LatLng(27.7273, 85.3047)}, // Balaju
//     const {"name": "Banasthali", "location": LatLng(27.7249, 85.2982)}, // Banasthali
//     const {"name": "Swoyambhu", "location": LatLng(27.7161, 85.2836)}, // Swoyambhu
//     const {"name": "Sitapaila", "location": LatLng(27.7077, 85.2825)}, // Sitapaila
//     const {"name": "Bafal", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

//   // Popup controller for handling popups
//   final PopupController _popupController = PopupController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: FlutterMap(
//         options: const MapOptions(
//           initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//           initialZoom: 14, // Adjusted zoom for better view of stops
//            // Enable interactivity
//         ),
//         children: [
//           // Base Map Layer
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//             userAgentPackageName: 'com.example.app', // Replace with your app's package name
//           ),
//           // Markers Layer with Popups
//           PopupMarkerLayerWidget(
//             options: PopupMarkerLayerOptions(
//               markers: busStops.map((stop) {
//                 return Marker(
//                   width: 80.0,
//                   height: 80.0,
//                   point: stop['location'],
//                   builder: (ctx) => const Icon(
//                     Icons.location_on,
//                     color: Colors.red,
//                     size: 30.0,
//                   ),
//                 );
//               }).toList(),
//               popupController: _popupController,
//               popupBuilder: (context, marker) {
//                 // Find the bus stop data for the tapped marker
//                 final stop = busStops.firstWhere(
//                   (s) => s['location'] == marker.point,
//                 );
//                 return Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           stop['name'],
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16.0,
//                           ),
//                         ),
//                         const SizedBox(height: 8.0),
//                         const Text('Additional details about this stop'),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatelessWidget {
//   FullMapScreen({super.key});

//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Gwarko", "location": LatLng(27.6677, 85.3333)}, // Gwarko
//     const {"name": "Koteshwor", "location": LatLng(27.6789, 85.3494)}, // Koteshwor
//     const {"name": "Tinkune", "location": LatLng(27.6862, 85.3480)}, // Tinkune
//     const {"name": "Airport", "location": LatLng(27.695, 85.3545)}, // Airport
//     const {"name": "Gaushala", "location": LatLng(27.7084, 85.3435)}, // Gaushala
//     const {"name": "Chabahil", "location": LatLng(27.7173, 85.3466)}, // Chabahil
//     const {"name": "Gopikrishna Hall", "location": LatLng(27.7211, 85.3459)}, // Gopikrishna Hall
//     const {"name": "Dhumbarai", "location": LatLng(27.7320, 85.3440)}, // Dhumbarai
//     const {"name": "Chakrapath", "location": LatLng(27.74, 85.3370)}, // Chakrapath
//     const {"name": "Basundhara", "location": LatLng(27.742, 85.3334)}, // Basundhara
//     const {"name": "Samakhusi", "location": LatLng(27.7352, 85.3181)}, // Samakhusi
//     const {"name": "Gangabu", "location": LatLng(27.7346, 85.3145)}, // Gangabu
//     const {"name": "Machhapokhari", "location": LatLng(27.7353, 85.3058)}, // Machhapokhari
//     const {"name": "Balaju", "location": LatLng(27.7273, 85.3047)}, // Balaju
//     const {"name": "Banasthali", "location": LatLng(27.7249, 85.2982)}, // Banasthali
//     const {"name": "Swoyambhu", "location": LatLng(27.7161, 85.2836)}, // Swoyambhu
//     const {"name": "Sitapaila", "location": LatLng(27.7077, 85.2825)}, // Sitapaila
//     const {"name": "Bafal", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // 
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: FlutterMap(
//         options: const MapOptions(
//           initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//           initialZoom: 14, // Adjusted zoom for better view of stops
//         ),
//         children: [
//           // Base Map Layer
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//             userAgentPackageName: 'com.example.app', // Replace with your app's package name
//           ),
//           // Markers Layer for Stops
//           MarkerLayer(
//             markers: busStops.map((stop) {
//               return Marker(
//                 width: 80.0,
//                 height: 80.0,
//                 point: stop['location'],
//                 child: Tooltip(
//                   message: stop['name'], // Display stop name
//                   child: const Icon(
//                     Icons.location_on,
//                     color: Colors.red,
//                     size: 30.0,
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
          
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatelessWidget {
//    FullMapScreen({super.key});

//   // Define static stops with their coordinates
//   final List<Map<String, dynamic>> busStops = [
//     const {"name": "Stop 1", "location": LatLng(27.6843, 85.3012)},//balkhu
//     const {"name": "Stop 1", "location": LatLng(27.6660, 85.3100)}, //ekantakuna
//     const {"name": "Stop 1", "location": LatLng(27.6591, 85.3253)},//satdobato
//     const {"name": "Stop 1", "location": LatLng(27.6677, 85.3333)},//gwarko
//     const {"name": "Stop 1", "location": LatLng(27.6789, 85.3494)}, //koteshwor
//     const {"name": "Stop 1", "location": LatLng(27.6862, 85.3480)},//tinkune
//     const {"name": "Stop 1", "location": LatLng(27.695, 85.3545)},//airport
//     const {"name": "Stop 1", "location": LatLng(27.7084, 85.3435)},//gaushala
//     const {"name": "Stop 1", "location": LatLng(27.7173, 85.3466)},//chabahil
//     const {"name": "Stop 1", "location": LatLng(27.7211, 85.3459)},//Gopikrishna hall
//     const {"name": "Stop 1", "location": LatLng(27.7320, 85.3440)},//dhumbarai
//     const {"name": "Stop 1", "location": LatLng(27.74, 85.3370)}, //chakrapath
//     const {"name": "Stop 1", "location": LatLng(27.742, 85.3334)},// basundhara
//     const {"name": "Stop 1", "location": LatLng(27.7352, 85.3181)},//samakhusi
//     const {"name": "Stop 1", "location": LatLng(27.7346, 85.3145)},//gangabu
//     const {"name": "Stop 1", "location": LatLng(27.7353, 85.3058)},//machhapokhari
//     const {"name": "Stop 1", "location": LatLng(27.7273, 85.3047)}, //balaju
//     const {"name": "Stop 1", "location": LatLng(27.7249, 85.2982)},//banasthali
//     const {"name": "Stop 1", "location": LatLng(27.7161, 85.2836)}, // swoyambhu
//     const {"name": "Stop 1", "location": LatLng(27.7077, 85.2825)},//sitapaila
//     const {"name": "Stop 1", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Stop 2", "location": LatLng(27.6933, 85.2816)}, // kalanki
    
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: FlutterMap(
//         options: const MapOptions(
//           initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//           initialZoom: 14, // Adjusted zoom for better view of stops
//         ),
//         children: [
//           // Base Map Layer
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//             userAgentPackageName: 'com.example.app', // Replace with your app's package name
//           ),
//           // Markers Layer for Stops
//           MarkerLayer(
//             markers: busStops.map((stop) {
//               return Marker(
//                 width: 80.0,
//                 height: 80.0,
//                 point: stop['location'],
//                 child: Tooltip(
//                   message: stop['name'], // Display stop name
//                   child: const Icon(
//                     Icons.location_on,
//                     color: Colors.red,
//                     size: 30.0,
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class FullMapScreen extends StatelessWidget {
//   const FullMapScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Route Map'),
//         centerTitle: true,
//         backgroundColor: Colors.green, // Customize the AppBar color
//       ),
//       body: FlutterMap(
//         options: const MapOptions(
//           initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//           initialZoom: 13, // Default zoom level
           
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//             userAgentPackageName: 'com.example.app', // Replace with your app's package name
//           ),
//         ],
//       ),
//     );
//   }
// }
