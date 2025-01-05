import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentIntegrationSection extends StatelessWidget {
  const PaymentIntegrationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Manage Your Payments",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint("Link RFID Card clicked.");
            },
            icon: const Icon(Icons.nfc, size: 20),
            label: Text(
              "Link RFID Card",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint("Add Balance via eSewa clicked.");
            },
            icon: const Icon(Icons.account_balance_wallet, size: 20),
            label: Text(
              "Add Balance",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Card Status: ",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Linked",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PaymentIntegrationSection extends StatelessWidget {
//   const PaymentIntegrationSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               debugPrint("Link RFID Card clicked.");
//             },
//             child: Text("Link RFID Card", style: GoogleFonts.poppins()),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: () {
//               debugPrint("Add Balance via eSewa clicked.");
//             },
//             child: Text("Add Balance", style: GoogleFonts.poppins()),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Card Status: Linked",
//             style: GoogleFonts.poppins(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }
