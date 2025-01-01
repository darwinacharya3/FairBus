import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentIntegrationSection extends StatelessWidget {
  const PaymentIntegrationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              debugPrint("Link RFID Card clicked.");
            },
            child: Text("Link RFID Card", style: GoogleFonts.poppins()),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              debugPrint("Add Balance via eSewa clicked.");
            },
            child: Text("Add Balance", style: GoogleFonts.poppins()),
          ),
          const SizedBox(height: 8),
          Text(
            "Card Status: Linked",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
