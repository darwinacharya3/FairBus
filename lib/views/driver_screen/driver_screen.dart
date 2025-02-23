// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:major_project/utils/cloudinary_helper.dart';

// class DriverScreen extends StatefulWidget {
//   final String driverId;
//   final String username;

//   const DriverScreen({
//     Key? key,
//     required this.driverId,
//     required this.username,
//   }) : super(key: key);

//   @override
//   _DriverScreenState createState() => _DriverScreenState();
// }

// class _DriverScreenState extends State<DriverScreen> {
//   final DatabaseReference _database = FirebaseDatabase.instance.ref();
//   final ImagePicker _picker = ImagePicker();
  
//   String? _profileImageUrl;
//   double _currentBalance = 0.0;
//   List<Map<String, dynamic>> _transactions = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupRealtimeListeners();
//   }

//   void _setupRealtimeListeners() {
//     // Listen to balance changes
//     _database
//         .child('total_balance_collected')
//         .child(widget.driverId)
//         .child('balance_collected')
//         .onValue
//         .listen((event) {
//       if (event.snapshot.value != null) {
//         setState(() {
//           _currentBalance = double.parse(event.snapshot.value.toString());
//         });
//       }
//     });

//     // Listen to transaction history
//     _database
//         .child('transactions')
//         .child(widget.driverId)
//         .onValue
//         .listen((event) {
//       if (event.snapshot.value != null) {
//         setState(() {
//           _transactions = (event.snapshot.value as Map)
//               .entries
//               .map((e) => {
//                     'id': e.key,
//                     ...Map<String, dynamic>.from(e.value as Map),
//                   })
//               .toList()
//             ..sort((a, b) => (b['timestamp'] as int)
//                 .compareTo(a['timestamp'] as int));
//         });
//       }
//     });
//   }

//   Future<void> _updateProfilePhoto() async {
//     try {
//       setState(() => _isLoading = true);
      
//       // Pick image from gallery
//       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//       if (image == null) return;

//       // Upload to Cloudinary
//       final String? imageUrl = await CloudinaryHelper.uploadImageToCloudinary(
//         image.path,
//         widget.username,
//       );

//       if (imageUrl != null) {
//         // Update profile image URL in Firebase
//         await _database
//             .child('drivers')
//             .child(widget.driverId)
//             .child('profile_photo')
//             .set(imageUrl);

//         setState(() => _profileImageUrl = imageUrl);
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Driver Profile'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Profile Photo Section
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 60,
//                     backgroundImage: _profileImageUrl != null
//                         ? NetworkImage(_profileImageUrl!)
//                         : null,
//                     child: _profileImageUrl == null
//                         ? const Icon(Icons.person, size: 60)
//                         : null,
//                   ),
//                   if (_isLoading)
//                     const CircularProgressIndicator()
//                   else
//                     FloatingActionButton.small(
//                       onPressed: _updateProfilePhoto,
//                       child: const Icon(Icons.camera_alt),
//                     ),
//                 ],
//               ),
//             ),

//             // Balance Section
//             Card(
//               margin: const EdgeInsets.all(16.0),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Current Balance',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                     Text(
//                       '\$${_currentBalance.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Transaction History
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Transaction History',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _transactions.length,
//                     itemBuilder: (context, index) {
//                       final transaction = _transactions[index];
//                       return Card(
//                         child: ListTile(
//                           title: Text(
//                             '\$${transaction['amount'].toStringAsFixed(2)}',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             DateFormat('MMM dd, yyyy hh:mm a').format(
//                               DateTime.fromMillisecondsSinceEpoch(
//                                 transaction['timestamp'],
//                               ),
//                             ),
//                           ),
//                           trailing: Text(
//                             transaction['type'] ?? 'Transaction',
//                             style: TextStyle(
//                               color: transaction['type'] == 'credit'
//                                   ? Colors.green
//                                   : Colors.red,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }