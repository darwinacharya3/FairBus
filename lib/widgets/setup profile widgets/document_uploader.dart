import 'package:flutter/material.dart';
import 'package:major_project/controller/setup_profile_controller.dart';
import 'package:get/get.dart';

class DocumentUploader extends StatelessWidget {
  final SetupProfileController controller;
  final String label;
  final bool isFront;

  const DocumentUploader({required this.controller, required this.label, required this.isFront, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Obx(() {
          var image = isFront
              ? controller.frontCitizenshipImage.value
              : controller.backCitizenshipImage.value;
          return image != null
              ? Image.file(image, height: 100)
              : ElevatedButton(
                  onPressed: () => isFront
                      ? controller.pickFrontCitizenshipImage()
                      : controller.pickBackCitizenshipImage(),
                  child: const Text("Upload Photo"),
                );
        }),
      ],
    );
  }
}



































// import 'package:flutter/material.dart';
// import 'package:major_project/controller/setup_profile_controller.dart';
// import 'package:get/get.dart';

// class DocumentUploader extends StatelessWidget {
//   final SetupProfileController controller;
//   final String label;
//   final bool isFront;

//   const DocumentUploader({required this.controller, required this.label, required this.isFront,super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 10),
//         Obx(() {
//           var image = isFront
//               ? controller.frontCitizenshipImage.value
//               : controller.backCitizenshipImage.value;
//           return image != null
//               ? Image.file(image, height: 100)
//               : ElevatedButton(
//                   onPressed: () => isFront
//                       ? controller.pickFrontCitizenshipImage()
//                       : controller.pickBackCitizenshipImage(),
//                   child: const Text("Upload Photo"),
//                 );
//         }),
//       ],
//     );
//   }
// }
