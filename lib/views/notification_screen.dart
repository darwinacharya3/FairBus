import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? status;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.read,
    this.status,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      read: map['read'] ?? false,
      status: map['status'],
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> clearAllNotifications() async {
    setState(() => _isLoading = true);
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();
      
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing notifications: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _isLoading 
              ? null 
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Clear All Notifications',
                        style: GoogleFonts.poppins(),
                      ),
                      content: Text(
                        'Are you sure you want to clear all notifications?',
                        style: GoogleFonts.poppins(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await clearAllNotifications();
                  }
                },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Wait for a short time to simulate refresh
          await Future.delayed(const Duration(seconds: 1));
          // StreamBuilder will automatically update
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Add debugging logs
            // print('Connection state: ${snapshot.connectionState}');
            // print('Has error: ${snapshot.hasError}');
            // if (snapshot.hasError) print('Error: ${snapshot.error}');
            // if (snapshot.hasData) {
              // print('Number of notifications: ${snapshot.data?.docs.length}');
            // }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data?.docs ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = NotificationModel.fromMap(
                  notifications[index].data() as Map<String, dynamic>,
                  notifications[index].id,
                );

                return Dismissible(
                  key: Key(notification.id),
                  onDismissed: (direction) async {
                    try {
                      await _firestore
                          .collection('notifications')
                          .doc(notification.id)
                          .delete();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting notification: $e')),
                      );
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(
                      notification.type == 'verification_status'
                          ? notification.status == 'verified'
                              ? Icons.verified_user
                              : Icons.gpp_bad
                          : Icons.notifications,
                      color: notification.status == 'verified'
                          ? Colors.green
                          : Colors.red,
                      size: 28,
                    ),
                    title: Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontWeight:
                            notification.read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(notification.createdAt),
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      if (!notification.read) {
                        try {
                          await _firestore
                              .collection('notifications')
                              .doc(notification.id)
                              .update({'read': true});
                        } catch (e) {
                          print('Error marking notification as read: $e');
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        if (minutes < 1) return 'Just now';
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      }
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}























// notification_screen.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';



// // notification_model.dart
// class NotificationModel {
//   final String id;
//   final String userId;
//   final String type;
//   final String message;
//   final DateTime createdAt;
//   final bool read;
//   final String? status;

//   NotificationModel({
//     required this.id,
//     required this.userId,
//     required this.type,
//     required this.message,
//     required this.createdAt,
//     required this.read,
//     this.status,
//   });

//   factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
//     return NotificationModel(
//       id: id,
//       userId: map['userId'] ?? '',
//       type: map['type'] ?? '',
//       message: map['message'] ?? '',
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//       read: map['read'] ?? false,
//       status: map['status'],
//     );
//   }
// }


// class NotificationScreen extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   NotificationScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Notifications',
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('notifications')
//             .where('userId', isEqualTo: _auth.currentUser?.uid)
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final notifications = snapshot.data?.docs ?? [];

//           if (notifications.isEmpty) {
//             return Center(
//               child: Text(
//                 'No notifications yet',
//                 style: GoogleFonts.poppins(
//                   color: Colors.grey,
//                   fontSize: 16,
//                 ),
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: notifications.length,
//             itemBuilder: (context, index) {
//               final notification = NotificationModel.fromMap(
//                 notifications[index].data() as Map<String, dynamic>,
//                 notifications[index].id,
//               );

//               return Dismissible(
//                 key: Key(notification.id),
//                 onDismissed: (direction) {
//                   _firestore
//                       .collection('notifications')
//                       .doc(notification.id)
//                       .delete();
//                 },
//                 background: Container(
//                   color: Colors.red,
//                   alignment: Alignment.centerRight,
//                   padding: const EdgeInsets.only(right: 20),
//                   child: const Icon(Icons.delete, color: Colors.white),
//                 ),
//                 child: ListTile(
//                   leading: Icon(
//                     notification.type == 'verification_status'
//                         ? notification.status == 'verified'
//                             ? Icons.verified_user
//                             : Icons.gpp_bad
//                         : Icons.notifications,
//                     color: notification.status == 'verified'
//                         ? Colors.green
//                         : Colors.red,
//                   ),
//                   title: Text(
//                     notification.message,
//                     style: GoogleFonts.poppins(
//                       fontWeight:
//                           notification.read ? FontWeight.normal : FontWeight.bold,
//                     ),
//                   ),
//                   subtitle: Text(
//                     _formatDate(notification.createdAt),
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey,
//                       fontSize: 12,
//                     ),
//                   ),
//                   onTap: () {
//                     if (!notification.read) {
//                       _firestore
//                           .collection('notifications')
//                           .doc(notification.id)
//                           .update({'read': true});
//                     }
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       if (difference.inHours == 0) {
//         return '${difference.inMinutes} minutes ago';
//       }
//       return '${difference.inHours} hours ago';
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     }
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }