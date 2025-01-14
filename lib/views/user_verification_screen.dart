import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserVerificationScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserVerificationScreen({
    Key? key,
    required this.userData,
    required this.userId,
  }) : super(key: key);

  Widget _buildUserInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Username'),
              subtitle: Text(userData['username'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Citizenship Number'),
              subtitle: Text(userData['citizenshipNumber'] ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Profile Picture
            _buildImageSection(
              'Profile Picture',
              userData['profileUrl'],
            ),
            const SizedBox(height: 16),
            
            // Citizenship Front
            _buildImageSection(
              'Citizenship Front',
              userData['citizenshipFrontUrl'],
            ),
            const SizedBox(height: 16),
            
            // Citizenship Back
            _buildImageSection(
              'Citizenship Back',
              userData['citizenshipBackUrl'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  )
                : Center(child: Text('No image available')),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String? imageUrl) {
    if (imageUrl == null) return;
    
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationHistorySection() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (userData['verificationHistory'] != null &&
              (userData['verificationHistory'] as List).isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (userData['verificationHistory'] as List).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                var history = (userData['verificationHistory'] as List)[index];
                return ListTile(
                  leading: Icon(
                    history['status'] == 'verified'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: history['status'] == 'verified'
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(
                    'Status: ${history['status']?.toString().toUpperCase() ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (history['notes'] != null)
                        Text('Notes: ${history['notes']}'),
                      if (history['adminUsername'] != null)
                        Text('By: ${history['adminUsername']}'),
                      if (history['timestamp'] != null)
                        Text(
                          'At: ${(history['timestamp'] as Timestamp).toDate().toString()}',
                        ),
                    ],
                  ),
                );
              },
            ),
          ] else
            const Center(
              child: Text(
                'No verification history available',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildVerificationForm() {
    final TextEditingController notesController = TextEditingController();
    bool hasIssues = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Checklist',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Verification checklist
                CheckboxListTile(
                  title: Text('Profile picture matches citizenship photo'),
                  value: !hasIssues,
                  onChanged: (value) {
                    setState(() => hasIssues = !value!);
                  },
                ),
                CheckboxListTile(
                  title: Text('Citizenship details are clear and legible'),
                  value: !hasIssues,
                  onChanged: (value) {
                    setState(() => hasIssues = !value!);
                  },
                ),
                CheckboxListTile(
                  title: Text('Documents are not expired'),
                  value: !hasIssues,
                  onChanged: (value) {
                    setState(() => hasIssues = !value!);
                  },
                ),
                
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Verification Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Add any notes about the verification...',
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _showRejectDialog(
                        context,
                        notesController.text,
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed: hasIssues
                          ? null
                          : () => _updateVerificationStatus(
                                true,
                                notesController.text,
                              ),
                      child: Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateVerificationStatus(bool isApproved, String notes) async {
    try {
      User? adminUser = _auth.currentUser;
      if (adminUser == null) throw "Admin not authenticated";

      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(adminUser.uid)
          .get();

      if (!adminDoc.exists) throw "Admin document not found";

      Map<String, dynamic> verificationData = {
        'isVerified': isApproved,
        'verificationStatus': isApproved ? 'verified' : 'rejected',
        'verificationNotes': notes,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': {
          'adminId': adminUser.uid,
          'adminUsername': adminDoc['username'] ?? 'Unknown Admin',
        },
        'verificationHistory': FieldValue.arrayUnion([
          {
            'status': isApproved ? 'verified' : 'rejected',
            'notes': notes,
            'timestamp': FieldValue.serverTimestamp(),
            'adminId': adminUser.uid,
            'adminUsername': adminDoc['username'] ?? 'Unknown Admin',
          }
        ]),
      };

      await _firestore.collection('users').doc(userId).update(verificationData);
      await _addVerificationNotification(isApproved, notes);

      Get.snackbar(
        'Success',
        'User ${isApproved ? 'verified' : 'rejected'} successfully',
        backgroundColor: isApproved ? Colors.green[100] : Colors.red[100],
      );
      
      Get.back();
    } catch (e) {
      print("Error in _updateVerificationStatus: $e");
      Get.snackbar(
        'Error',
        'Failed to update verification status: $e',
        backgroundColor: Colors.red[100],
      );
    }
  }

  Future<void> _addVerificationNotification(bool isApproved, String notes) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'verification_status',
        'status': isApproved ? 'verified' : 'rejected',
        'message': isApproved 
            ? 'Your account has been verified successfully!'
            : 'Your account verification was rejected. Reason: $notes',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false
      });
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  void _showRejectDialog(BuildContext context, String notes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reject this verification?',
              ),
              if (notes.isEmpty)
                Text(
                  '\nPlease add notes explaining the rejection reason.',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: notes.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _updateVerificationStatus(false, notes);
                    },
              child: Text(
                'Reject',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Documents'),
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const SizedBox(height: 16),
            _buildDocumentViewer(),
            const SizedBox(height: 16),
            _buildVerificationHistorySection(),
            const SizedBox(height: 16),
            _buildVerificationForm(),
          ],
        ),
      ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// // import 'package:google_fonts/google_fonts.dart';

// class UserVerificationScreen extends StatelessWidget {
//   final Map<String, dynamic> userData;
//   final String userId;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   UserVerificationScreen({
//     Key? key,
//     required this.userData,
//     required this.userId,
//   }) : super(key: key);

//   Future<void> _updateVerificationStatus(bool isApproved) async {
//     try {
//       // Get current admin info
//       User? adminUser = _auth.currentUser;
//       if (adminUser == null) throw "Admin not authenticated";

//       DocumentSnapshot adminDoc = await _firestore
//           .collection('users')
//           .doc(adminUser.uid)
//           .get();

//       if (!adminDoc.exists) throw "Admin document not found";

//       // Create verification metadata
//       Map<String, dynamic> verificationData = {
//         'isVerified': isApproved,
//         'verificationStatus': isApproved ? 'verified' : 'rejected',
//         'verifiedAt': FieldValue.serverTimestamp(),
//         'verifiedBy': {
//           'adminId': adminUser.uid,
//           'adminUsername': adminDoc['username'] ?? 'Unknown Admin',
//         },
//         'verificationHistory': FieldValue.arrayUnion([
//           {
//             'status': isApproved ? 'verified' : 'rejected',
//             'timestamp': FieldValue.serverTimestamp(),
//             'adminId': adminUser.uid,
//             'adminUsername': adminDoc['username'] ?? 'Unknown Admin',
//           }
//         ]),
//       };

//       // Update user document with verification data
//       await _firestore.collection('users').doc(userId).update(verificationData);

//       // Send notification to the user (you can implement this later)
//       await _addVerificationNotification(isApproved);

//       Get.snackbar(
//         'Success',
//         'User ${isApproved ? 'verified' : 'rejected'} successfully',
//         backgroundColor: isApproved ? Colors.green[100] : Colors.red[100],
//       );
      
//       Get.back(); // Return to user list
//     } catch (e) {
//       print("Error in _updateVerificationStatus: $e");
//       Get.snackbar(
//         'Error',
//         'Failed to update verification status: $e',
//         backgroundColor: Colors.red[100],
//       );
//     }
//   }

//   Future<void> _addVerificationNotification(bool isApproved) async {
//     try {
//       await _firestore.collection('notifications').add({
//         'userId': userId,
//         'type': 'verification_status',
//         'status': isApproved ? 'verified' : 'rejected',
//         'message': isApproved 
//             ? 'Your account has been verified successfully!'
//             : 'Your account verification was rejected. Please contact support.',
//         'createdAt': FieldValue.serverTimestamp(),
//         'read': false
//       });
//     } catch (e) {
//       print("Error adding notification: $e");
//     }
//   }

//   Widget _buildVerificationHistorySection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Verification History',
//               // style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 8),
//             if (userData['verificationHistory'] != null) ...[
//               for (var history in (userData['verificationHistory'] as List)) ...[
//                 ListTile(
//                   leading: Icon(
//                     history['status'] == 'verified' 
//                         ? Icons.check_circle 
//                         : Icons.cancel,
//                     color: history['status'] == 'verified' 
//                         ? Colors.green 
//                         : Colors.red,
//                   ),
//                   title: Text('Status: ${history['status']}'),
//                   subtitle: Text(
//                     'By: ${history['adminUsername']}\n'
//                     'At: ${(history['timestamp'] as Timestamp).toDate().toString()}'
//                   ),
//                 ),
//                 const Divider(),
//               ],
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Documents'),
//         backgroundColor: const Color(0xFFA8E6CF),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Keep existing user info and documents sections...

//             // Add verification history section
//             const SizedBox(height: 16),
//             _buildVerificationHistorySection(),
            
//             const SizedBox(height: 24),
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   ),
//                   onPressed: () => _showRejectDialog(context),
//                   child: const Text(
//                     'Reject',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   ),
//                   onPressed: () => _updateVerificationStatus(true),
//                   child: const Text(
//                     'Approve',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showRejectDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Reject Verification'),
//           content: const Text(
//             'Are you sure you want to reject this verification? '
//             'This will notify the user and they will need to resubmit their documents.'
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _updateVerificationStatus(false);
//               },
//               child: const Text(
//                 'Reject',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:get/get.dart';

// class UserVerificationScreen extends StatelessWidget {
//   final Map<String, dynamic> userData;
//   final String userId;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   UserVerificationScreen({
//     Key? key,
//     required this.userData,
//     required this.userId,
//   }) : super(key: key);

//   Future<void> _updateVerificationStatus(bool isApproved) async {
//     try {
//       await _firestore.collection('users').doc(userId).update({
//         'isVerified': isApproved,
//         'verificationStatus': isApproved ? 'verified' : 'rejected',
//         'verifiedAt': FieldValue.serverTimestamp(),
//       });

//       Get.snackbar(
//         'Success',
//         'User ${isApproved ? 'verified' : 'rejected'} successfully',
//         backgroundColor: isApproved ? Colors.green[100] : Colors.red[100],
//       );
      
//       Get.back(); // Return to user list
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to update verification status: $e',
//         backgroundColor: Colors.red[100],
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Documents'),
//         backgroundColor: const Color(0xFFA8E6CF),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // User Info Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'User Details',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 8),
//                     ListTile(
//                       title: Text('Username: ${userData['username']}'),
//                       subtitle: Text('Citizenship Number: ${userData['citizenshipNumber']}'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Documents Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Citizenship Documents',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Front Side
//                     Text('Front Side:', style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 8),
//                     if (userData['citizenshipFrontUrl'] != null)
//                       CachedNetworkImage(
//                         imageUrl: userData['citizenshipFrontUrl'],
//                         placeholder: (context, url) => const CircularProgressIndicator(),
//                         errorWidget: (context, url, error) => const Icon(Icons.error),
//                       ),
                    
//                     const SizedBox(height: 16),
                    
//                     // Back Side
//                     Text('Back Side:', style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 8),
//                     if (userData['citizenshipBackUrl'] != null)
//                       CachedNetworkImage(
//                         imageUrl: userData['citizenshipBackUrl'],
//                         placeholder: (context, url) => const CircularProgressIndicator(),
//                         errorWidget: (context, url, error) => const Icon(Icons.error),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   ),
//                   onPressed: () => _updateVerificationStatus(false),
//                   child: const Text(
//                     'Reject',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   ),
//                   onPressed: () => _updateVerificationStatus(true),
//                   child: const Text(
//                     'Approve',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }