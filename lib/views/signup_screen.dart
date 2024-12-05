import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:major_project/utils/app_colors.dart';
import 'package:major_project/widgets/signup_screen_widget.dart';
import 'package:major_project/views/welcome_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.greenColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.to(() => const WelcomeScreen());
          },
        ),
      ),
      body: const SignupScreenWidget(),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/widgets/signup_screen_widget.dart';
// import 'package:major_project/views/welcome_screen.dart';

// class SignupScreen extends StatelessWidget {
//   const SignupScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.greenColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Get.to(() => const WelcomeScreen());
//           },
//         ),
//       ),
//       body: const SignupScreenWidget(),
//     );
//   }
// }





