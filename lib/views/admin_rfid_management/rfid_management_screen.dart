import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class RFIDManagementScreen extends StatelessWidget {
  const RFIDManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RFID Management', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildManagementCard(
              title: 'Add RFID Cards',
              description: 'Add new RFID cards to the system',
              icon: Icons.add_card,
              onTap: () => Get.toNamed('/admin/rfid-management/add'),
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              title: 'Assign Cards',
              description: 'Assign RFID cards to user requests',
              icon: Icons.person_add,
              onTap: () => Get.toNamed('/admin/rfid-management/assign'),
            ),
             const SizedBox(height: 16),
            _buildManagementCard(
              title: 'View Assignments',
              description: 'View all RFID card assignments',
              icon: Icons.assignment,
              onTap: () => Get.toNamed('/admin/rfid-management/view-assignments'),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}












// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// class RFIDManagementScreen extends StatelessWidget {
//   const RFIDManagementScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('RFID Management', style: GoogleFonts.poppins()),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildManagementCard(
//               title: 'Add RFID Cards',
//               description: 'Add new RFID cards to the system',
//               icon: Icons.add_card,
//               onTap: () => Get.toNamed('/admin/rfid-management/add'),
//             ),
//             const SizedBox(height: 16),
//             _buildManagementCard(
//               title: 'Assign Cards',
//               description: 'Assign RFID cards to user requests',
//               icon: Icons.person_add,
//               onTap: () => Get.toNamed('/admin/rfid-management/assign'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildManagementCard({
//     required String title,
//     required String description,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, size: 32, color: Colors.blue[700]),
//                   const SizedBox(width: 12),
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 description,
//                 style: GoogleFonts.poppins(
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }