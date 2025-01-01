// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: Get.width,
//         height: Get.height,
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage("assets/mask.png"),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: const Center(
//           child: Text(
//             "Home Screen",
//             style: TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:get/get.dart';
import 'package:major_project/widgets/home_screen_widget/app_bar_widget.dart';
import 'package:major_project/widgets/home_screen_widget/user_profile_section.dart';
import 'package:major_project/widgets/home_screen_widget/payment_integration_section.dart';
import 'package:major_project/widgets/home_screen_widget/bus_routes_section.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBarWidget(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserProfileSection(),
            PaymentIntegrationSection(),
            BusRoutesSection(),
          ],
        ),
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/widgets/home_screen_widget.dart';  // Importing widget file for AppBar structure

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       appBar: HomeScreenWidget(),  // Custom AppBar from the widget file
//       body: Center(
//         child: Text('Welcome to the Bus Fare Collection App!'),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: Get.width,
//         height: Get.height,
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage("assets/mask.png"),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: const Center(
//           child: Text(
//             "Home Screen",
//             style: TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
