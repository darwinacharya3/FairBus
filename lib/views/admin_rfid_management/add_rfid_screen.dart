import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project/controller/admin_rfid_controller.dart';

class AddRFIDScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();

  AddRFIDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminRFIDController = Get.find<AdminRFIDController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add RFID Card', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _uidController,
                decoration: InputDecoration(
                  labelText: 'RFID UID',
                  hintText: 'Enter the RFID card UID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the RFID UID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    adminRFIDController.addRFIDCard(_uidController.text);
                    _uidController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add Card', style: GoogleFonts.poppins()),
              ),
              const SizedBox(height: 24),
              Text(
                'Added Cards',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: adminRFIDController.rfidCards.length,
                  itemBuilder: (context, index) {
                    final card = adminRFIDController.rfidCards[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          'UID: ${card.uid}',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          card.isAssigned ? 'Assigned' : 'Available',
                          style: GoogleFonts.poppins(
                            color: card.isAssigned ? Colors.green : Colors.green[700],
                          ),
                        ),
                      ),
                    );
                  },
                )),
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
// import 'package:major_project/controller/admin_rfid_controller.dart';

// class AddRFIDScreen extends StatelessWidget {
//   final _formKey = GlobalKey<FormState>();
//   final _uidController = TextEditingController();

//   AddRFIDScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final adminRFIDController = Get.find<AdminRFIDController>();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Add RFID Card', style: GoogleFonts.poppins()),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextFormField(
//                 controller: _uidController,
//                 decoration: InputDecoration(
//                   labelText: 'RFID UID',
//                   hintText: 'Enter the RFID card UID',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter the RFID UID';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     adminRFIDController.addRFIDCard(_uidController.text);
//                     _uidController.clear();
//                   }
//                 },
//                 child: Text('Add Card', style: GoogleFonts.poppins()),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Added Cards',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: Obx(() => ListView.builder(
//                   itemCount: adminRFIDController.rfidCards.length,
//                   itemBuilder: (context, index) {
//                     final card = adminRFIDController.rfidCards[index];
//                     return Card(
//                       child: ListTile(
//                         title: Text(
//                           'UID: ${card.uid}',
//                           style: GoogleFonts.poppins(),
//                         ),
//                         subtitle: Text(
//                           card.isAssigned ? 'Assigned' : 'Available',
//                           style: GoogleFonts.poppins(
//                             color: card.isAssigned ? Colors.green : Colors.blue,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 )),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }