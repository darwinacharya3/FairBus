import 'package:flutter/material.dart';
import 'package:major_project/widgets/home_screen_widget/app_bar_widget.dart';
import 'package:major_project/widgets/home_screen_widget/user_profile_section.dart';
import 'package:major_project/widgets/home_screen_widget/payment_integration_section.dart';
import 'package:major_project/widgets/home_screen_widget/bus_routes_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Total available height of the screen
          double totalHeight = constraints.maxHeight;

          // Define height proportions
          double userProfileHeight = totalHeight * 0.2;
          double paymentIntegrationHeight = totalHeight * 0.4;
          double mapSectionHeight = totalHeight * 0.4;

          return Column(
            children: [
              // User Profile Section (20%)
              SizedBox(
                height: userProfileHeight,
                child: const UserProfileSection(),
              ),

              // Payment Integration Section (40%)
              SizedBox(
                height: paymentIntegrationHeight,
                child: const PaymentIntegrationSection(),
              ),

              // Map Section (40%)
              SizedBox(
                height: mapSectionHeight,
                child: BusRoutesSection(),
              ),
            ],
          );
        },
      ),
    );
  }
}





