import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SetupProfileController extends GetxController {
  var profileImage = Rx<File?>(null);
  var frontCitizenshipImage = Rx<File?>(null);
  var backCitizenshipImage = Rx<File?>(null);
  TextEditingController citizenshipNumberController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  void pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) profileImage.value = File(pickedFile.path);
  }

  void captureImageWithCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) profileImage.value = File(pickedFile.path);
  }

  void pickFrontCitizenshipImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) frontCitizenshipImage.value = File(pickedFile.path);
  }

  void pickBackCitizenshipImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) backCitizenshipImage.value = File(pickedFile.path);
  }

  void submitProfile() {
    if (citizenshipNumberController.text.isEmpty ||
        profileImage.value == null ||
        frontCitizenshipImage.value == null ||
        backCitizenshipImage.value == null) {
      Get.snackbar("Error", "All fields are required!");
      return;
    }

    // Upload data to Firebase and backend here
    Get.snackbar("Success", "Profile setup complete!");
  }
}
