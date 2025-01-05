import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullMapScreen extends StatelessWidget {
  const FullMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route Map'),
        centerTitle: true,
        backgroundColor: Colors.green, // Customize the AppBar color
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
          initialZoom: 13, // Default zoom level
           
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
            userAgentPackageName: 'com.example.app', // Replace with your app's package name
          ),
        ],
      ),
    );
  }
}
