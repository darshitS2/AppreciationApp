import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'appreciation_post.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Get the current user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Appreciations'),
      ),
      body: Column(
        children: [
          // User Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                const Icon(Icons.person, size: 72),
                const SizedBox(height: 10),
                Text(
                  currentUser?.email ?? 'Loading...', // Display user's email
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),

          // List of received appreciations
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // This is the special query!
              stream: FirebaseFirestore.instance
                  .collection('appreciations')
                  .where('to_uid', isEqualTo: currentUser!.uid) // Get posts WHERE 'to_uid' matches my ID
                  .orderBy('timestamp', descending: true) // And sort them
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have not received any appreciations yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final appreciations = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appreciations.length,
                  itemBuilder: (context, index) {
                    final appreciation = appreciations[index];
                    final postId = appreciation.id;
                    final message = appreciation['message'] as String;
                    final value = appreciation['value'] as String;
                    final fromUid = appreciation['from_uid'] as String;
                    final toUid = appreciation['to_uid'] as String;
                    final timestamp = appreciation['timestamp'] as Timestamp;
                    final formattedTime = DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate());

                    // We still need to fetch the user names
                    return FutureBuilder<List<DocumentSnapshot>>(
                      future: Future.wait([
                        FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                        FirebaseFirestore.instance.collection('users').doc(toUid).get(),
                      ]),
                      builder: (context, userSnapshots) {
                        if (!userSnapshots.hasData) {
                          return const SizedBox.shrink(); // Show nothing while loading names
                        }
                        final fromUserName = userSnapshots.data![0]['fullName'] as String;
                        final toUserName = userSnapshots.data![1]['fullName'] as String;

                        // On this page, we WANT to show the sender, so we use the default
                        return AppreciationPost(
                          postId: postId,
                          fromUid: fromUid,
                          message: message,
                          from: fromUserName,
                          to: toUserName,
                          value: value,
                          time: formattedTime,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}