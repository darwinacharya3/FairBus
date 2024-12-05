import 'package:flutter/material.dart';
import 'package:major_project/utils/app_constants.dart';
import 'package:major_project/widgets/text_widget.dart';

Widget welcomeWidget() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // "Welcome to our app" text
        textWidget(
          text: AppConstants.welcometoourapp,
          fontSize: 25,
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // "Let's get started" text
        textWidget(
          text: AppConstants.letsgetstarted,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
      ],
    ),
  );
}