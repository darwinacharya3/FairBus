// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:pinput/pinput.dart';

// class OtpVerificationWidget extends StatefulWidget {
//   const OtpVerificationWidget({Key? key}) : super(key: key);

//   @override
//   State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
// }

// class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
//   final TextEditingController _otpController = TextEditingController();

//   void _verifyOtp() {
//     String otp = _otpController.text.trim();

//     if (otp.isEmpty) {
//       Get.snackbar("Error", "OTP cannot be empty!");
//       return;
//     }

//     // Navigate to reset password screen after successful OTP verification
//     final arguments = Get.arguments as Map<String, dynamic>;
//     Get.toNamed('/resetPassword', arguments: {'email': arguments['email']});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Container(
//             width: Get.width,
//             height: Get.height * 0.3,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Verify OTP",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 "Enter the OTP sent to your email",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.blackColor,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Pinput(
//               controller: _otpController,
//               length: 6,
//               defaultPinTheme: PinTheme(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: AppColors.greenColor),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _verifyOtp,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.greenColor,
//               padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text(
//               "Verify",
//               style: TextStyle(fontSize: 18, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





