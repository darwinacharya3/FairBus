import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project/controller/admin_rfid_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignRFIDScreen extends StatelessWidget {
  const AssignRFIDScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminRFIDController = Get.find<AdminRFIDController>();
    final selectedValues = <String, RxString>{}.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign RFID Cards', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pending Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: adminRFIDController.pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = adminRFIDController.pendingRequests[index];
                  selectedValues.putIfAbsent(request['uid'], () => RxString(''));

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${request['name']}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Request Date: ${_formatDate(request['cardRequestDate'])}',
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() {
                                  final availableCards = adminRFIDController.availableCards;
                                  return DropdownButtonFormField<String>(
                                    value: selectedValues[request['uid']]!.value,
                                    decoration: InputDecoration(
                                      labelText: 'Select RFID Card',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.green),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text('Select a card'),
                                      ),
                                      ...availableCards.map((card) => DropdownMenuItem(
                                        value: card.uid,
                                        child: Text(
                                          'UID: ${card.uid}',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      )),
                                    ],
                                    onChanged: (value) async {
                                      if (value != null && value.isNotEmpty) {
                                        await adminRFIDController.assignCard(
                                          request['uid'],
                                          value,
                                        );
                                        selectedValues[request['uid']]?.value = '';
                                      }
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (date.runtimeType.toString() == 'Timestamp') {
      final DateTime dateTime = (date as Timestamp).toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'N/A';
  }
}













// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/controller/admin_rfid_controller.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AssignRFIDScreen extends StatelessWidget {
//   const AssignRFIDScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final adminRFIDController = Get.find<AdminRFIDController>();
//     final selectedValues = <String, RxString>{}.obs;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Assign RFID Cards', style: GoogleFonts.poppins()),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Pending Requests',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Obx(() => ListView.builder(
//                 itemCount: adminRFIDController.pendingRequests.length,
//                 itemBuilder: (context, index) {
//                   final request = adminRFIDController.pendingRequests[index];
//                   selectedValues.putIfAbsent(request['uid'], () => RxString(''));

//                   return Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Name: ${request['name']}',
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Request Date: ${_formatDate(request['cardRequestDate'])}',
//                             style: GoogleFonts.poppins(),
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Obx(() {
//                                   final availableCards = adminRFIDController.availableCards;
//                                   return DropdownButtonFormField<String>(
//                                     value: selectedValues[request['uid']]!.value,
//                                     decoration: InputDecoration(
//                                       labelText: 'Select RFID Card',
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                     ),
//                                     items: [
//                                       const DropdownMenuItem<String>(
//                                         value: '',
//                                         child: Text('Select a card'),
//                                       ),
//                                       ...availableCards.map((card) => DropdownMenuItem(
//                                         value: card.uid,
//                                         child: Text(
//                                           'UID: ${card.uid}',
//                                           style: GoogleFonts.poppins(),
//                                         ),
//                                       )),
//                                     ],
//                                     onChanged: (value) async {
//                                       if (value != null && value.isNotEmpty) {
//                                         await adminRFIDController.assignCard(
//                                           request['uid'],
//                                           value,
//                                         );
//                                         selectedValues[request['uid']]?.value = '';
//                                       }
//                                     },
//                                   );
//                                 }),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               )),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(dynamic date) {
//     if (date == null) return 'N/A';
//     if (date is DateTime) {
//       return '${date.day}/${date.month}/${date.year}';
//     }
//     if (date.runtimeType.toString() == 'Timestamp') {
//       final DateTime dateTime = (date as Timestamp).toDate();
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     }
//     return 'N/A';
//   }
// }













// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:major_project/controller/admin_rfid_controller.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';

// // class AssignRFIDScreen extends StatelessWidget {
// //   const AssignRFIDScreen({Key? key}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     final adminRFIDController = Get.find<AdminRFIDController>();
// //     // Create a map to store selected values for each request
// //     final selectedValues = <String, RxString>{}.obs;

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Assign RFID Cards', style: GoogleFonts.poppins()),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Text(
// //               'Pending Requests',
// //               style: GoogleFonts.poppins(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //             Expanded(
// //               child: Obx(() => ListView.builder(
// //                 itemCount: adminRFIDController.pendingRequests.length,
// //                 itemBuilder: (context, index) {
// //                   final request = adminRFIDController.pendingRequests[index];
// //                   // Initialize selected value for this request if not exists
// //                   selectedValues.putIfAbsent(request['uid'], () => RxString(''));

// //                   return Card(
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(16.0),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             'Name: ${request['name']}',
// //                             style: GoogleFonts.poppins(
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 8),
// //                           Text(
// //                             'Request Date: ${_formatDate(request['cardRequestDate'])}',
// //                             style: GoogleFonts.poppins(),
// //                           ),
// //                           const SizedBox(height: 16),
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: Obx(() {
// //                                   final availableCards = adminRFIDController.availableCards;
// //                                   return DropdownButtonFormField<String>(
// //                                     value: selectedValues[request['uid']]!.value.isEmpty ? null : selectedValues[request['uid']]!.value,
// //                                     decoration: InputDecoration(
// //                                       labelText: 'Select RFID Card',
// //                                       border: OutlineInputBorder(
// //                                         borderRadius: BorderRadius.circular(8),
// //                                       ),
// //                                     ),
// //                                     items: [
// //                                       DropdownMenuItem<String>(
// //                                         value: '',
// //                                         child: Text(
// //                                           'Select a card',
// //                                           style: GoogleFonts.poppins(),
// //                                         ),
// //                                       ),
// //                                       ...availableCards.map((card) => DropdownMenuItem(
// //                                         value: card.uid,
// //                                         child: Text(
// //                                           'UID: ${card.uid}',
// //                                           style: GoogleFonts.poppins(),
// //                                         ),
// //                                       )),
// //                                     ],
// //                                     onChanged: (value) async {
// //                                       if (value != null && value.isNotEmpty) {
// //                                         await adminRFIDController.assignCard(
// //                                           request['uid'],
// //                                           value,
// //                                         );
// //                                         // Reset the selected value after successful assignment
// //                                         selectedValues[request['uid']]?.value = '';
// //                                       }
// //                                     },
// //                                   );
// //                                 }),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               )),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatDate(dynamic date) {
// //     if (date == null) return 'N/A';
// //     if (date is DateTime) {
// //       return '${date.day}/${date.month}/${date.year}';
// //     }
// //     if (date.runtimeType.toString() == 'Timestamp') {
// //       final DateTime dateTime = (date as Timestamp).toDate();
// //       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
// //     }
// //     return 'N/A';
// //   }
// // }











// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:major_project/controller/admin_rfid_controller.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

// // class AssignRFIDScreen extends StatelessWidget {
// //   const AssignRFIDScreen({Key? key}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     final adminRFIDController = Get.find<AdminRFIDController>();

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Assign RFID Cards', style: GoogleFonts.poppins()),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Text(
// //               'Pending Requests',
// //               style: GoogleFonts.poppins(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //             Expanded(
// //               child: Obx(() => ListView.builder(
// //                 itemCount: adminRFIDController.pendingRequests.length,
// //                 itemBuilder: (context, index) {
// //                   final request = adminRFIDController.pendingRequests[index];
// //                   return Card(
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(16.0),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             'Name: ${request['name']}',
// //                             style: GoogleFonts.poppins(
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 8),
// //                           Text(
// //                             'Request Date: ${_formatDate(request['cardRequestDate'])}',
// //                             style: GoogleFonts.poppins(),
// //                           ),
// //                           const SizedBox(height: 16),
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: Obx(() => DropdownButtonFormField<String>(
// //                                   decoration: InputDecoration(
// //                                     labelText: 'Select RFID Card',
// //                                     border: OutlineInputBorder(
// //                                       borderRadius: BorderRadius.circular(8),
// //                                     ),
// //                                   ),
// //                                   items: adminRFIDController.availableCards
// //                                       .map((card) => DropdownMenuItem(
// //                                             value: card.uid,
// //                                             child: Text(
// //                                               'UID: ${card.uid}',
// //                                               style: GoogleFonts.poppins(),
// //                                             ),
// //                                           ))
// //                                       .toList(),
// //                                   onChanged: (value) {
// //                                     if (value != null) {
// //                                       adminRFIDController.assignCard(
// //                                         request['uid'],
// //                                         value,
// //                                       );
// //                                     }
// //                                   },
// //                                 )),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               )),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatDate(dynamic date) {
// //     if (date == null) return 'N/A';
// //     if (date is DateTime) {
// //       return '${date.day}/${date.month}/${date.year}';
// //     }
// //     if (date.runtimeType.toString() == 'Timestamp') { // Changed the type check
// //       final DateTime dateTime = (date as Timestamp).toDate();
// //       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
// //     }
// //     return 'N/A';
// //   }
// // }


















// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:major_project/controller/admin_rfid_controller.dart';

// // class AssignRFIDScreen extends StatelessWidget {
// //   const AssignRFIDScreen({Key? key}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     final adminRFIDController = Get.find<AdminRFIDController>();

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Assign RFID Cards', style: GoogleFonts.poppins()),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Text(
// //               'Pending Requests',
// //               style: GoogleFonts.poppins(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //             Expanded(
// //               child: Obx(() => ListView.builder(
// //                 itemCount: adminRFIDController.pendingRequests.length,
// //                 itemBuilder: (context, index) {
// //                   final request = adminRFIDController.pendingRequests[index];
// //                   return Card(
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(16.0),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             'Name: ${request['name']}',
// //                             style: GoogleFonts.poppins(
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 8),
// //                           Text(
// //                             'Request Date: ${_formatDate(request['cardRequestDate'])}',
// //                             style: GoogleFonts.poppins(),
// //                           ),
// //                           const SizedBox(height: 16),
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: Obx(() => DropdownButtonFormField<String>(
// //                                   decoration: InputDecoration(
// //                                     labelText: 'Select RFID Card',
// //                                     border: OutlineInputBorder(
// //                                       borderRadius: BorderRadius.circular(8),
// //                                     ),
// //                                   ),
// //                                   items: adminRFIDController.availableCards
// //                                       .map((card) => DropdownMenuItem(
// //                                             value: card.uid,
// //                                             child: Text(
// //                                               'UID: ${card.uid}',
// //                                               style: GoogleFonts.poppins(),
// //                                             ),
// //                                           ))
// //                                       .toList(),
// //                                   onChanged: (value) {
// //                                     if (value != null) {
// //                                       adminRFIDController.assignCard(
// //                                         request['uid'],
// //                                         value,
// //                                       );
// //                                     }
// //                                   },
// //                                 )),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               )),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatDate(dynamic date) {
// //   if (date == null) return 'N/A';
// //   if (date is DateTime) {
// //     return '${date.day}/${date.month}/${date.year}';
// //   }
// //   if (date is Timestamp) {
// //     final DateTime dateTime = date.toDate();
// //     return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
// //   }
// //   return 'N/A';
// // }

// //   // String _formatDate(DateTime? date) {
// //   //   if (date == null) return 'N/A';
// //   //   return '${date.day}/${date.month}/${date.year}';
// //   // }
// // }
