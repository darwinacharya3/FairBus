import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:major_project/controller/auth_controller.dart';
import 'package:major_project/views/admin_user_list_screen.dart';


class AdminDashboardScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  AdminDashboardScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int pendingVerifications = usersSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['verificationStatus'] == 'pending')
          .length;
      int verifiedUsers = usersSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isVerified'] == true)
          .length;

      return {
        'totalUsers': totalUsers,
        'pendingVerifications': pendingVerifications,
        'verifiedUsers': verifiedUsers,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'pendingVerifications': 0,
        'verifiedUsers': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with reduced padding
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.green[600],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Admin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bus Fare Collection System',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Section with LayoutBuilder
            FutureBuilder<Map<String, dynamic>>(
              future: _getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {
                  'totalUsers': 0,
                  'pendingVerifications': 0,
                  'verifiedUsers': 0,
                };

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total\nUsers',
                            '${stats['totalUsers']}',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Pending\nVerifications',
                            '${stats['pendingVerifications']}',
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Verified\nUsers',
                            '${stats['verifiedUsers']}',
                            Icons.verified_user,
                            Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Features Grid with Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _buildFeatureCard(
                        'User Verification',
                        'Verify user documents',
                        Icons.verified_user,
                        Colors.green[600]!,
                        () => 
                        Get.to(() => AdminUserListScreen()),
                        

                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _buildFeatureCard(
                        'Bus Management',
                        'Manage bus routes',
                        Icons.directions_bus,
                        Colors.blue[600]!,
                        () {
                          Get.snackbar(
                            'Coming Soon',
                            'Bus management feature will be available soon',
                            backgroundColor: Colors.blue[100],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _buildFeatureCard(
                        'Transaction History',
                        'View transactions',
                        Icons.receipt_long,
                        Colors.purple[600]!,
                        () {
                          Get.snackbar(
                            'Coming Soon',
                            'Transaction history feature will be available soon',
                            backgroundColor: Colors.purple[100],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _buildFeatureCard(
                        'Reports',
                        'View system reports',
                        Icons.analytics,
                        Colors.orange[600]!,
                        () {
                          Get.snackbar(
                            'Coming Soon',
                            'Reports feature will be available soon',
                            backgroundColor: Colors.orange[100],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class AdminDashboardScreen extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController _authController = Get.find<AuthController>();

//   AdminDashboardScreen({Key? key}) : super(key: key);

//   Future<Map<String, dynamic>> _getDashboardStats() async {
//     try {
//       QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
//       int totalUsers = usersSnapshot.docs.length;
//       int pendingVerifications = usersSnapshot.docs
//           .where((doc) => (doc.data() as Map<String, dynamic>)['verificationStatus'] == 'pending')
//           .length;
//       int verifiedUsers = usersSnapshot.docs
//           .where((doc) => (doc.data() as Map<String, dynamic>)['isVerified'] == true)
//           .length;

//       return {
//         'totalUsers': totalUsers,
//         'pendingVerifications': pendingVerifications,
//         'verifiedUsers': verifiedUsers,
//       };
//     } catch (e) {
//       print('Error getting dashboard stats: $e');
//       return {
//         'totalUsers': 0,
//         'pendingVerifications': 0,
//         'verifiedUsers': 0,
//       };
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Admin Dashboard',
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
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Welcome Section
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
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
//                       color: Colors.green[600], size: 40),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Welcome, Admin',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           'Bus Fare Collection System Dashboard',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Stats Section
//             FutureBuilder<Map<String, dynamic>>(
//               future: _getDashboardStats(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final stats = snapshot.data ?? {
//                   'totalUsers': 0,
//                   'pendingVerifications': 0,
//                   'verifiedUsers': 0,
//                 };

//                 return GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 16.0,
//                   mainAxisSpacing: 16.0,
//                   children: [
//                     _buildStatCard(
//                       'Total Users',
//                       '${stats['totalUsers']}',
//                       Icons.people,
//                       Colors.blue,
//                     ),
//                     _buildStatCard(
//                       'Pending Verifications',
//                       '${stats['pendingVerifications']}',
//                       Icons.pending_actions,
//                       Colors.orange,
//                     ),
//                     _buildStatCard(
//                       'Verified Users',
//                       '${stats['verifiedUsers']}',
//                       Icons.verified_user,
//                       Colors.green,
//                     ),
//                   ],
//                 );
//               },
//             ),
//             const SizedBox(height: 24),

//             // Features Grid
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 16.0,
//               mainAxisSpacing: 16.0,
//               children: [
//                 _buildFeatureCard(
//                   'User Verification',
//                   'Verify user documents and manage approvals',
//                   Icons.verified_user,
//                   Colors.green[600]!,
//                   () => Get.toNamed('/admin/users'),
//                 ),
//                 _buildFeatureCard(
//                   'Bus Management',
//                   'Manage bus routes and schedules',
//                   Icons.directions_bus,
//                   Colors.blue[600]!,
//                   () {
//                     // TODO: Implement bus management navigation
//                     Get.snackbar(
//                       'Coming Soon',
//                       'Bus management feature will be available soon',
//                       backgroundColor: Colors.blue[100],
//                     );
//                   },
//                 ),
//                 _buildFeatureCard(
//                   'Transaction History',
//                   'View and manage fare transactions',
//                   Icons.receipt_long,
//                   Colors.purple[600]!,
//                   () {
//                     // TODO: Implement transaction history navigation
//                     Get.snackbar(
//                       'Coming Soon',
//                       'Transaction history feature will be available soon',
//                       backgroundColor: Colors.purple[100],
//                     );
//                   },
//                 ),
//                 _buildFeatureCard(
//                   'Reports',
//                   'Generate and view system reports',
//                   Icons.analytics,
//                   Colors.orange[600]!,
//                   () {
//                     // TODO: Implement reports navigation
//                     Get.snackbar(
//                       'Coming Soon',
//                       'Reports feature will be available soon',
//                       backgroundColor: Colors.orange[100],
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 32),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeatureCard(
//     String title,
//     String description,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 5,
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 40),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               description,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cached_network_image/cached_network_image.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class AdminDashboardScreen extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController _authController = Get.find<AuthController>();

//   AdminDashboardScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Admin Dashboard',
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
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWelcomeCard(),
//             const SizedBox(height: 24),
//             _buildQuickStats(),
//             const SizedBox(height: 24),
//             _buildMenuGrid(),
//             const SizedBox(height: 24),
//             _buildRecentActivity(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green[600]!, Colors.green[400]!],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.2),
//             spreadRadius: 2,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.admin_panel_settings,
//             color: Colors.white,
//             size: 40,
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Welcome, Admin',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Manage your bus fare collection system',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickStats() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('users').snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         int totalUsers = snapshot.data!.docs.length;
//         int pendingVerifications = snapshot.data!.docs
//             .where((doc) =>
//                 (doc.data() as Map<String, dynamic>)['verificationStatus'] ==
//                 'pending')
//             .length;

//         return Row(
//           children: [
//             _buildStatCard(
//               'Total Users',
//               totalUsers.toString(),
//               Icons.people,
//               Colors.blue,
//             ),
//             const SizedBox(width: 16),
//             _buildStatCard(
//               'Pending Verifications',
//               pendingVerifications.toString(),
//               Icons.pending_actions,
//               Colors.orange,
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildStatCard(
//       String title, String value, IconData icon, MaterialColor color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 5,
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color, size: 28),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuGrid() {
//     final List<Map<String, dynamic>> menuItems = [
//       {
//         'title': 'User Verification',
//         'icon': Icons.verified_user,
//         'color': Colors.green,
//         'route': '/admin/users',
//       },
//       {
//         'title': 'Bus Routes',
//         'icon': Icons.directions_bus,
//         'color': Colors.blue,
//         'route': '/admin/routes',
//       },
//       {
//         'title': 'Fare Management',
//         'icon': Icons.attach_money,
//         'color': Colors.orange,
//         'route': '/admin/fares',
//       },
//       {
//         'title': 'Reports',
//         'icon': Icons.analytics,
//         'color': Colors.purple,
//         'route': '/admin/reports',
//       },
//     ];

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1.3,
//       ),
//       itemCount: menuItems.length,
//       itemBuilder: (context, index) {
//         return _buildMenuCard(
//           title: menuItems[index]['title'],
//           icon: menuItems[index]['icon'],
//           color: menuItems[index]['color'],
//           onTap: () => Get.toNamed(menuItems[index]['route']),
//         );
//       },
//     );
//   }

//   Widget _buildMenuCard({
//     required String title,
//     required IconData icon,
//     required MaterialColor color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 5,
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 32),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivity() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Recent Activity',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           StreamBuilder<QuerySnapshot>(
//             stream: _firestore
//                 .collection('users')
//                 .orderBy('verifiedAt', descending: true)
//                 .limit(5)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               return ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: snapshot.data!.docs.length,
//                 separatorBuilder: (context, index) => const Divider(),
//                 itemBuilder: (context, index) {
//                   var userData =
//                       snapshot.data!.docs[index].data() as Map<String, dynamic>;
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.green[50],
//                       child: Icon(
//                         Icons.person,
//                         color: Colors.green[600],
//                       ),
//                     ),
//                     title: Text(userData['username'] ?? 'Unknown User'),
//                     subtitle: Text(
//                       'Status: ${userData['verificationStatus']?.toString().toUpperCase() ?? 'PENDING'}',
//                     ),
//                     trailing: Text(
//                       userData['verifiedAt'] != null
//                           ? _formatTimestamp(userData['verifiedAt'])
//                           : 'Pending',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final date = timestamp.toDate();
//     final difference = now.difference(date);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }