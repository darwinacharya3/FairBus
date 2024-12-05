import 'package:flutter/material.dart';
import 'package:major_project/controller/setup_profile_controller.dart';
import 'package:get/get.dart';

class ProfilePictureUploader extends StatelessWidget {
  final SetupProfileController controller;

  const ProfilePictureUploader({required this.controller,super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => CircleAvatar(
              radius: 50,
              backgroundImage: controller.profileImage.value != null
                  ? FileImage(controller.profileImage.value!)
                  : null,
              child: controller.profileImage.value == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            )),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: controller.pickImageFromGallery,
              child: const Text("Upload Photo"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: controller.captureImageWithCamera,
              child: const Text("Take Photo"),
            ),
          ],
        ),
      ],
    );
  }
}
