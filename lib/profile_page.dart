// lib/profile_page.dart
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
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // The DefaultTabController should wrap the entire Scaffold.
    return DefaultTabController(
      length: 2, // We have 2 tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
        ),
        body: Column(
          children: [
            // 1. The User Info Header is now a permanent part of the body, outside the tabs.
            _buildUserInfoHeader(),

            // 2. The TabBar now sits below the header, providing the navigation.
            const TabBar(
              tabs: [
                Tab(text: 'Received'),
                Tab(text: 'Sent'),
              ],
            ),

            // 3. The TabBarView takes up the remaining space and shows the correct list.
            Expanded(
              child: TabBarView(
                children: [
                  // VIEW 1: Appreciations Received
                  _buildAppreciationList(
                    query: FirebaseFirestore.instance
                        .collection('appreciations')
                        .where('to_uid', isEqualTo: currentUser!.uid)
                        .orderBy('timestamp', descending: true),
                    emptyMessage: 'You have not received any appreciations yet.',
                  ),

                  // VIEW 2: Appreciations Sent
                  _buildAppreciationList(
                    query: FirebaseFirestore.instance
                        .collection('appreciations')
                        .where('from_uid', isEqualTo: currentUser!.uid)
                        .orderBy('timestamp', descending: true),
                    emptyMessage: 'You have not sent any appreciations yet.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- We move the User Info Header into its own reusable widget method ---
  Widget _buildUserInfoHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = userData['fullName'] ?? 'No Name';
        final email = userData['email'] ?? 'No Email';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(email, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        );
      },
    );
  }

  // --- We create a reusable method for building the lists to avoid duplicate code ---
  Widget _buildAppreciationList({required Query query, required String emptyMessage}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(emptyMessage, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          );
        }

        final appreciations = snapshot.data!.docs;

        return ListView.builder(
          itemCount: appreciations.length,
          itemBuilder: (context, index) {
            // Your existing robust itemBuilder logic for fetching names and building the post
            final appreciation = appreciations[index];
            final data = appreciation.data() as Map<String, dynamic>;
            final postId = appreciation.id;
            final fromUid = data['from_uid'] as String;
            final toUid = data['to_uid'] as String;
            // ... (safely get message, value, timestamp)
            
            // This is the same robust FutureBuilder from your main feed
            return FutureBuilder<List<DocumentSnapshot>>(
              future: Future.wait([
                FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                FirebaseFirestore.instance.collection('users').doc(toUid).get(),
              ]),
              builder: (context, userSnapshots) {
                // ... (your existing robust logic to get names and handle inactive users)
                String fromUserName = "Unknown User";
                String toUserName = "Unknown User";
                
                if (userSnapshots.hasData && userSnapshots.data != null) {
                  if (userSnapshots.data![0].exists) {
                     final fromData = userSnapshots.data![0].data() as Map<String, dynamic>;
                     fromUserName = fromData['fullName'] ?? 'Unknown User';
                     if (fromData['status'] == 'inactive') fromUserName += " (Inactive)";
                  }
                  if (userSnapshots.data![1].exists) {
                     final toData = userSnapshots.data![1].data() as Map<String, dynamic>;
                     toUserName = toData['fullName'] ?? 'Unknown User';
                     if (toData['status'] == 'inactive') toUserName += " (Inactive)";
                  }
                }

                return AppreciationPost(
                  postId: postId,
                  fromUid: fromUid,
                  message: data['message'] ?? '',
                  from: fromUserName,
                  to: toUserName,
                  value: data['value'] ?? '',
                  time: DateFormat('MMM d, yyyy').format((data['timestamp'] as Timestamp).toDate()),
                  // We can now use this to customize the view if needed
                  showSender: true, 
                );
              },
            );
          },
        );
      },
    );
  }
}