import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:major_project/controller/setup_profile_controller.dart';
import 'package:major_project/widgets/setup profile widgets/profile_picture_uploader.dart';
import 'package:major_project/widgets/setup profile widgets/citizenship_number_field.dart';
import 'package:major_project/widgets/setup profile widgets/submit_button.dart';
import 'package:major_project/widgets/setup profile widgets/document_uploader.dart';


class SetupProfileScreen extends StatelessWidget {
  SetupProfileScreen({super.key});
  final SetupProfileController controller = Get.put(SetupProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup Your Profile"),
        backgroundColor: const Color(0xFFA8E6CF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfilePictureUploader(controller: controller),
            const SizedBox(height: 20),
            CitizenshipNumberField(controller: controller),
            const SizedBox(height: 20),
            DocumentUploader(
              controller: controller,
              label: "Upload Front Side",
              isFront: true,
            ),
            const SizedBox(height: 10),
            DocumentUploader(
              controller: controller,
              label: "Upload Back Side",
              isFront: false,
            ),
            const SizedBox(height: 30),
            SubmitButton(controller: controller),
            
          ],
        ),
      ),
    );
  }
}



















// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:major_project/controller/setup_profile_controller.dart';
// import 'package:major_project/widgets/setup profile widgets/profile_picture_uploader.dart';
// import 'package:major_project/widgets/setup profile widgets/citizenship_number_field.dart';
// import 'package:major_project/widgets/setup profile widgets/submit_button.dart';
// import 'package:major_project/widgets/setup profile widgets/document_uploader.dart';


// class SetupProfileScreen extends StatelessWidget {
//   SetupProfileScreen({super.key});
//   final SetupProfileController controller = Get.put(SetupProfileController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Setup Your Profile"),
//         backgroundColor: const Color(0xFFA8E6CF),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const  EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ProfilePictureUploader(controller: controller),
//             SizedBox(height: 20),
//             CitizenshipNumberField(controller: controller),
//             SizedBox(height: 20),
//             DocumentUploader(
//               controller: controller,
//               label: "Upload Front Side",
//               isFront: true,
//             ),
//             SizedBox(height: 10),
//             DocumentUploader(
//               controller: controller,
//               label: "Upload Back Side",
//               isFront: false,
//             ),
//             SizedBox(height: 30),
//             SubmitButton(controller: controller),
//           ],
//         ),
//       ),
//     );
//   }
// }
