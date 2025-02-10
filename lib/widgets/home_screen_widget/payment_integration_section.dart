// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
// import 'package:esewa_flutter_sdk/esewa_config.dart';
// import 'package:esewa_flutter_sdk/esewa_payment.dart';
// import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:major_project/controller/card_request_controller.dart';
import 'package:major_project/controller/balance_controller.dart';

class PaymentIntegrationSection extends StatelessWidget {
  
  
  const PaymentIntegrationSection({super.key});
  


  void _handleEsewaPayment(BuildContext context) async {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test, // Use Environment.live for production
          clientId: "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R",
          secretId: "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==",
        ),
        esewaPayment: EsewaPayment(
          productId: "FB${DateTime.now().millisecondsSinceEpoch}",
          productName: "FairBus Balance",
          productPrice: "100", // You can make this dynamic if needed
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint("Payment Success: $data");
          _verifyTransaction(context, data);
        },
        onPaymentFailure: (error) {
          debugPrint("Payment Failure: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed. Please try again.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        onPaymentCancellation: (cancellationData) {
          debugPrint("Payment Cancelled: $cancellationData");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment was cancelled.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred. Please try again later.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verifyTransaction(
      BuildContext context, EsewaPaymentSuccessResult result) async {
    
    // For now, using a mock verification
    await Future.delayed(const Duration(seconds: 2));
    final BalanceController balanceController = Get.find<BalanceController>();
    await balanceController.updateBalance(100.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Balance added successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
    
  }

   Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

   String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'requested':
        return 'Requested';
      default:
        return 'None';
    }
  }



  @override
  Widget build(BuildContext context) {
    final CardRequestController cardController = Get.put(CardRequestController());
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

           Obx(() => ElevatedButton.icon(
                onPressed: cardController.cardStatus.value == 'active'
                    ? null
                    : () => cardController.requestCard(),
                icon: const Icon(Icons.nfc, size: 20),
                label: Text(
                  _getButtonText(cardController.cardStatus.value),
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _handleEsewaPayment(context),
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

               Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(cardController.cardStatus.value)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(cardController.cardStatus.value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(cardController.cardStatus.value),
                      ),
                    ),
                  ),),
            ],
          ),
        ],
      ),
    );
  }
  String _getButtonText(String status) {
    switch (status) {
      case 'none':
        return 'Request RFID Card';
      case 'requested':
        return 'Card Request Pending';
      case 'active':
        return 'Card Active';
      default:
        return 'Request RFID Card';
    }
  }
}




























// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PaymentIntegrationSection extends StatelessWidget {
//   const PaymentIntegrationSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             "Manage Your Payments",
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.green,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: () {
//               debugPrint("Link RFID Card clicked.");
//             },
//             icon: const Icon(Icons.nfc, size: 20),
//             label: Text(
//               "Link RFID Card",
//               style: GoogleFonts.poppins(fontSize: 16),
//             ),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton.icon(
//             onPressed: () {
//               debugPrint("Add Balance via eSewa clicked.");
//             },
//             icon: const Icon(Icons.account_balance_wallet, size: 20),
//             label: Text(
//               "Add Balance",
//               style: GoogleFonts.poppins(fontSize: 16),
//             ),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               backgroundColor: Colors.green,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Card Status: ",
//                 style: GoogleFonts.poppins(fontSize: 16),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   "Linked",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
