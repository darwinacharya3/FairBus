// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:major_project/widgets/forget_password_widget.dart';

// class ForgetPasswordScreen extends StatelessWidget {
//   const ForgetPasswordScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true, // Allows content to extend behind AppBar
//       appBar: AppBar(
//         title: const Text(
//           "Forget Password",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           ForgetPasswordWidget(), // Loads the decorated ForgetPasswordWidget
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:major_project/utils/app_colors.dart';
import 'package:major_project/widgets/forget_password_widget.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.greenColor,
        elevation: 0,
        title: const Text("Forget Password"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: const ForgetPasswordWidget(),
    );
  }
}
