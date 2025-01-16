import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:major_project/views/welcome_screen.dart';
// import 'package:major_project/views/homescreen.dart';
import 'package:major_project/widgets/login_screen_widget.dart';
import 'package:major_project/utils/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
      body: const LoginScreenWidget(), // Widget to manage the Login UI
    );
  }
}













// import 'package:flutter/material.dart';
// // import 'package:major_project/views/otp_verification_screen.dart';
// import 'package:major_project/widgets/green_intro_widget.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:get/get.dart';
// import 'package:major_project/widgets/login_widget.dart';
// import 'package:fl_country_code_picker/fl_country_code_picker.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final countryPicker = const FlCountryCodePicker();

//   CountryCode countryCode = const CountryCode(name: "Nepal", code: "NP", dialCode: "+977");


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stack(
//               children: [
//                 greenIntroWidget(),
//                 Positioned(
//                   top: 60,
//                   left: 30,
//                   child: InkWell(
//                     onTap: () {
//                       Get.back();
//                     },
//                     child: Container(
//                       width: 45,
//                       height: 45,
//                       decoration: const BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white,
//                       ),
//                       child: const Icon(
//                         Icons.arrow_back,
//                         color: AppColors.greenColor,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 40),
//             loginWidget(
//               countryCode,
//               () async {
//                 final picked = await countryPicker.showPicker(context: context);
//                 if (picked != null) countryCode = picked;
//                 setState(() {});
//               },
//               // onSubmit,
              
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
