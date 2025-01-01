import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusRoutesSection extends StatelessWidget {
  const BusRoutesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> favoriteRoutes = ["Route 1", "Route 2", "Route 3"];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Favorite Routes",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...favoriteRoutes.map((route) => ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.green),
                title: Text(route, style: GoogleFonts.poppins()),
                onTap: () {
                  debugPrint("$route tapped.");
                },
              )),
        ],
      ),
    );
  }
}
