// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_directions/flutter_map_directions.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';

// class DirectionsScreen extends StatefulWidget {
//   final LatLng? initialLocation;

//   const DirectionsScreen({super.key, this.initialLocation});

//   @override
//   State<DirectionsScreen> createState() => _DirectionsScreenState();
// }

// class _DirectionsScreenState extends State<DirectionsScreen> {
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _endController = TextEditingController();

//   LatLng? _startLocation;
//   LatLng? _endLocation;

//   final DirectionsLayer _directionsLayer = DirectionsLayer();

//   Future<void> _getCurrentLocation() async {
//     final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _startLocation = LatLng(position.latitude, position.longitude);
//       _startController.text = "Your Location";
//     });
//   }

//   Future<void> _calculateRoute() async {
//     if (_startLocation == null || _endLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select both start and end locations")),
//       );
//       return;
//     }

//     await _directionsLayer.calculateRoute(
//       start: _startLocation!,
//       end: _endLocation!,
//     );
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Directions"),
//         backgroundColor: Colors.green,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _startController,
//                     decoration: const InputDecoration(
//                       labelText: "Start",
//                       hintText: "Enter start location",
//                     ),
//                     onTap: _getCurrentLocation,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.my_location),
//                   onPressed: _getCurrentLocation,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _endController,
//               decoration: const InputDecoration(
//                 labelText: "Destination",
//                 hintText: "Enter destination",
//               ),
//               onSubmitted: (value) async {
//                 // TODO: Geocode address to LatLng
//                 // For now, set a placeholder location
//                 setState(() {
//                   _endLocation = LatLng(27.7172, 85.3240);
//                 });
//               },
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _calculateRoute,
//             child: const Text("Get Directions"),
//           ),
//           Expanded(
//             child: FlutterMap(
//               options: MapOptions(
//                 initialCenter: widget.initialLocation ?? const LatLng(27.7172, 85.3240),
//                 initialZoom: 14.0,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   subdomains: const ['a', 'b', 'c'],
//                 ),
//                 _directionsLayer,
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
