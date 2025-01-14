import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:major_project/views/user_verification_screen.dart';

class AdminUserListScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminUserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Verification Panel'),
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var userId = snapshot.data!.docs[index].id;
              
              bool isVerified = userData['isVerified'] ?? false;
              String verificationStatus = userData['verificationStatus'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profileUrl'] != null
                        ? CachedNetworkImageProvider(userData['profileUrl'])
                        : null,
                    child: userData['profileUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(userData['username'] ?? 'Unknown User'),
                  subtitle: Text('Status: ${verificationStatus.toUpperCase()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      Get.to(() => UserVerificationScreen(
                        userData: userData,
                        userId: userId,
                      ));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


