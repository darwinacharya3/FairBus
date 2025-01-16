import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:major_project/views/user_verification_screen.dart';
import 'package:major_project/controller/auth_controller.dart';


class AdminUserListScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  AdminUserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Verification Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          _authController.logoutUser();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, 
                       color: Colors.green[600], 
                       size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage user verifications',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'User Verification Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .orderBy('created_at', descending: true)  // Sort by creation time
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    );
                  }

                  // Filter and sort users
                  var users = snapshot.data!.docs;
                  var pendingUsers = users.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['verificationStatus'] == 'pending';
                  }).toList();
                  
                  var otherUsers = users.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['verificationStatus'] != 'pending';
                  }).toList();

                  // Combine lists with pending users first
                  var sortedUsers = [...pendingUsers, ...otherUsers];

                  return ListView.builder(
                    itemCount: sortedUsers.length,
                    itemBuilder: (context, index) {
                      var userData = sortedUsers[index].data() as Map<String, dynamic>;
                      var userId = sortedUsers[index].id;
                      
                      bool isVerified = userData['isVerified'] ?? false;
                      String verificationStatus = userData['verificationStatus'] ?? 'pending';
                      
                      // Check if the user is new (less than 24 hours old)
                      bool isNew = false;
                      if (userData['created_at'] != null) {
                        Timestamp createdAt = userData['created_at'] as Timestamp;
                        isNew = DateTime.now().difference(createdAt.toDate()).inHours < 24;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isNew ? BorderSide(
                            color: Colors.green[600]!,
                            width: 2,
                          ) : BorderSide.none,
                        ),
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.green[50],
                                backgroundImage: userData['profileUrl'] != null
                                    ? CachedNetworkImageProvider(userData['profileUrl'])
                                    : null,
                                child: userData['profileUrl'] == null
                                    ? Icon(Icons.person, 
                                          color: Colors.green[600])
                                    : null,
                              ),
                              title: Text(
                                userData['username'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(verificationStatus),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      verificationStatus.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: Colors.green[600],
                                ),
                                onPressed: () {
                                  Get.to(
                                    () => UserVerificationScreen(
                                      userData: userData,
                                      userId: userId,
                                    ),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                              ),
                            ),
                            if (isNew) Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[400]!;
      case 'pending':
        return Colors.orange[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
}


































// class AdminUserListScreen extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController _authController = Get.find<AuthController>();  // Add this

//   AdminUserListScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'User Verification Panel',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.green[600],
//         elevation: 2,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return AlertDialog(
//                     title: const Text('Logout'),
//                     content: const Text('Are you sure you want to logout?'),
//                     actions: [
//                       TextButton(
//                         child: const Text('Cancel'),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       TextButton(
//                         child: const Text(
//                           'Logout',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                         onPressed: () {
//                           _authController.logoutUser();
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//       backgroundColor: Colors.grey[100],  // Add background color
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Add dashboard header
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 5,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.admin_panel_settings, 
//                        color: Colors.green[600], 
//                        size: 32),
//                   const SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Admin Dashboard',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Manage user verifications',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // User list section header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Text(
//                 'User Verification Requests',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[800],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // StreamBuilder wrapped in Expanded
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return Center(
//                       child: Text(
//                         'Error: ${snapshot.error}',
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     );
//                   }

//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                       child: CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//                       ),
//                     );
//                   }

//                   return ListView.builder(
//                     itemCount: snapshot.data!.docs.length,
//                     itemBuilder: (context, index) {
//                       var userData = snapshot.data!.docs[index].data() 
//                           as Map<String, dynamic>;
//                       var userId = snapshot.data!.docs[index].id;
                      
//                       bool isVerified = userData['isVerified'] ?? false;
//                       String verificationStatus = 
//                           userData['verificationStatus'] ?? 'pending';

//                       return Card(
//                         elevation: 2,
//                         margin: const EdgeInsets.symmetric(
//                           vertical: 8,
//                           horizontal: 4,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           leading: CircleAvatar(
//                             radius: 25,
//                             backgroundColor: Colors.green[50],
//                             backgroundImage: userData['profileUrl'] != null
//                                 ? CachedNetworkImageProvider(userData['profileUrl'])
//                                 : null,
//                             child: userData['profileUrl'] == null
//                                 ? Icon(Icons.person, 
//                                       color: Colors.green[600])
//                                 : null,
//                           ),
//                           title: Text(
//                             userData['username'] ?? 'Unknown User',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 4),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: _getStatusColor(verificationStatus),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   verificationStatus.toUpperCase(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: IconButton(
//                             icon: Icon(
//                               Icons.visibility,
//                               color: Colors.green[600],
//                             ),
//                             onPressed: () {
//                               Get.to(
//                                 () => UserVerificationScreen(
//                                   userData: userData,
//                                   userId: userId,
//                                 ),
//                                 transition: Transition.rightToLeft,
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'verified':
//         return Colors.green[600]!;
//       case 'rejected':
//         return Colors.red[400]!;
//       case 'pending':
//         return Colors.orange[400]!;
//       default:
//         return Colors.grey[400]!;
//     }
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:get/get.dart';
// import 'package:major_project/views/user_verification_screen.dart';

// class AdminUserListScreen extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   AdminUserListScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('User Verification Panel'),
//         backgroundColor: const Color(0xFFA8E6CF),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('users').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
//               var userId = snapshot.data!.docs[index].id;
              
//               bool isVerified = userData['isVerified'] ?? false;
//               String verificationStatus = userData['verificationStatus'] ?? 'pending';

//               return Card(
//                 margin: const EdgeInsets.all(8),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundImage: userData['profileUrl'] != null
//                         ? CachedNetworkImageProvider(userData['profileUrl'])
//                         : null,
//                     child: userData['profileUrl'] == null
//                         ? const Icon(Icons.person)
//                         : null,
//                   ),
//                   title: Text(userData['username'] ?? 'Unknown User'),
//                   subtitle: Text('Status: ${verificationStatus.toUpperCase()}'),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.visibility),
//                     onPressed: () {
//                       Get.to(() => UserVerificationScreen(
//                         userData: userData,
//                         userId: userId,
//                       ));
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }


