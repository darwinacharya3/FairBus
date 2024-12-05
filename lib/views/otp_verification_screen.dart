// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:major_project/widgets/otp_verification_widget.dart';
// import 'package:major_project/utils/app_colors.dart';

// class OtpVerificationScreen extends StatelessWidget {
//   const OtpVerificationScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.greenColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Get.back();
//           },
//         ),
//       ),
//       body: const OtpVerificationWidget(),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/views/setup_profile_screen.dart';
// import 'package:major_project/widgets/green_intro_widget.dart';
// import 'package:major_project/widgets/otp_verification_widget.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   const OtpVerificationScreen({super.key});

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   final AuthController authController = Get.put(AuthController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: SizedBox(
//           width: Get.width,
//           height: Get.height,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Stack(
//                 children: [
//                   greenIntroWidget(),
//                   Positioned(
//                     top: 60,
//                     left: 30,
//                     child: InkWell(
//                       onTap: () {
//                         Get.back();
//                       },
//                       child: Container(
//                         width: 45,
//                         height: 45,
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                         ),
//                         child: const Icon(
//                           Icons.arrow_back,
//                           color: AppColors.greenColor,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               otpVerificationWidget(
//                 onOtpVerified: () async {
//                   String enteredOtp = ""; // Replace with the entered OTP from the user
//                   bool isOtpValid = await authController.verifyOtp(enteredOtp);

//                   if (isOtpValid) {
//                     Get.to(() => SetupProfileScreen(
//                           mobileNumber: authController.phoneNumber,
//                         ));
//                   }
//                 },
//                 resendOtp: () {
//                   authController.phoneAuth(authController.phoneNumber);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





