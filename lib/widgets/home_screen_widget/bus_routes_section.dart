import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'full_map_screen_widget/full_map_screen.dart'; // Import the full map screen

class BusRoutesSection extends StatelessWidget {
  const BusRoutesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableHeight = constraints.maxHeight * 0.7; // Adjust height to 70% of the parent
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Add consistent padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Adjust height dynamically
            children: [
              // Title Text
              const Text(
                "Bus Routes",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Navigate to the full map screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FullMapScreen()),
                  );
                },
                child: Stack(
                  children: [
                    // Map Preview Container
                    Container(
                      height: availableHeight, // Use dynamically calculated height
                      width: double.infinity, // Make it stretch across the screen
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent.withOpacity(0.7), Colors.lightBlue.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
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
                      ),
                    ),
                    // Semi-transparent Overlay for Interaction
                    Positioned.fill(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4), // Semi-transparent overlay
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Explore Full Map",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'full_map_screen.dart'; // Import the full map screen

// class BusRoutesSection extends StatelessWidget {
//   const BusRoutesSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double availableHeight = constraints.maxHeight * 0.70; // Limit height to 70% of the parent
//         return Padding(
//           padding: const EdgeInsets.all(16.0), // Add padding around the section
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min, // Adjust height dynamically
//             children: [
//               const Text(
//                 "Bus Routes",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to the full map screen
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => FullMapScreen()),
//                   );
//                 },
//                 child: Stack(
//                   children: [
//                     Container(
//                       height: availableHeight, // Use dynamically calculated height
//                       width: double.infinity, // Make it stretch across the screen
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 8,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: FlutterMap(
//                           options: const MapOptions(
//                             initialCenter: LatLng(27.7172, 85.3240), // Center on Kathmandu
//                             initialZoom: 13, // Default zoom level
                             
//                           ),
//                           children: [
//                             TileLayer(
//                               urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                               subdomains: const ['a', 'b', 'c'], // Subdomains for OSM
//                               userAgentPackageName: 'com.example.app', // Replace with your app's package name
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     // Add an overlay to indicate interaction
//                     Positioned.fill(
//                       child: Container(
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Text(
//                           "View Full Map",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }









