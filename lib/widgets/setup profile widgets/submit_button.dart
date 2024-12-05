import 'package:flutter/material.dart';
import 'package:major_project/controller/setup_profile_controller.dart';

class SubmitButton extends StatelessWidget {
  final SetupProfileController controller;

  const SubmitButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF056608), // Updated parameter
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: controller.submitProfile,
      child: const Center(
        child: Text(
          "Submit Profile",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
