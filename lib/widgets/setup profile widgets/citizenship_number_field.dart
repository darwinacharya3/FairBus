import 'package:flutter/material.dart';
import 'package:major_project/controller/setup_profile_controller.dart';

class CitizenshipNumberField extends StatelessWidget {
  final SetupProfileController controller;

  const CitizenshipNumberField({required this.controller,super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.citizenshipNumberController,
      decoration: const InputDecoration(
        labelText: "Citizenship Number",
        border: OutlineInputBorder(),
      ),
    );
  }
}
