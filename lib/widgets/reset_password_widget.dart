// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class ResetPasswordWidget extends StatefulWidget {
//   const ResetPasswordWidget({Key? key}) : super(key: key);

//   @override
//   State<ResetPasswordWidget> createState() => _ResetPasswordWidgetState();
// }

// class _ResetPasswordWidgetState extends State<ResetPasswordWidget> {
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//   final AuthController _authController = Get.put(AuthController());

//   void _resetPassword() {
//     String newPassword = _passwordController.text.trim();
//     String confirmPassword = _confirmPasswordController.text.trim();

//     if (newPassword.isEmpty || confirmPassword.isEmpty) {
//       Get.snackbar("Error", "All fields are required!");
//       return;
//     }

//     if (newPassword.length != 6 || confirmPassword.length != 6) {
//       Get.snackbar("Error", "Password must be exactly 6 digits!");
//       return;
//     }

//     if (newPassword != confirmPassword) {
//       Get.snackbar("Error", "Passwords do not match!");
//       return;
//     }

//     // Perform password reset
//     final arguments = Get.arguments as Map<String, dynamic>;
//     _authController.verifyOtpAndResetPassword(
//       email: arguments['email'],
//       newPassword: newPassword,
//     );
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
//                 "Reset Password",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "New Password",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 _buildTextField(
//                   controller: _passwordController,
//                   hintText: "Enter 6-digit password",
//                   icon: Icons.lock,
//                   obscureText: true,
//                   maxLength: 6,
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 20),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Confirm Password",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 _buildTextField(
//                   controller: _confirmPasswordController,
//                   hintText: "Confirm 6-digit password",
//                   icon: Icons.lock,
//                   obscureText: true,
//                   maxLength: 6,
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _resetPassword,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 50,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     "Reset Password",
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     bool obscureText = false,
//     int? maxLength,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       maxLength: maxLength,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         counterText: "", // Hides the max length counter
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: AppColors.greenColor),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }











