import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:major_project/controller/admin_rfid_controller.dart';

class ViewAssignmentsScreen extends StatelessWidget {
  const ViewAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminRFIDController = Get.find<AdminRFIDController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('RFID Assignments', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Cards',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final assignedCards = adminRFIDController.rfidCards
                    .where((card) => card.isAssigned)
                    .toList();

                if (assignedCards.isEmpty) {
                  return Center(
                    child: Text(
                      'No cards assigned yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: assignedCards.length,
                  itemBuilder: (context, index) {
                    final card = assignedCards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RFID UID: ${card.uid}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Assigned to: ${card.assignedToName ?? "Unknown"}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (card.assignedDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Assigned on: ${DateFormat('MMM dd, yyyy').format(card.assignedDate!)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}