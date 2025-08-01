// lib/admin_all_posts_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'appreciation_post.dart'; // We will be reusing our awesome post widget
import 'export_service.dart';

class AdminAllPostsPage extends StatelessWidget {
  const AdminAllPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Appreciations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              // Show a loading indicator
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating export...')));
              await ExportService().exportAppreciationsToCsv();
            },
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // This query is simple: get ALL documents from the 'appreciations' collection
        stream: FirebaseFirestore.instance
            .collection('appreciations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appreciations found in the system.'));
          }

          final appreciations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appreciations.length,
            itemBuilder: (context, index) {
              final data = appreciations[index].data() as Map<String, dynamic>;
              final postId = appreciations[index].id;
              final fromUid = data['from_uid'] as String;
              final toUid = data['to_uid'] as String;
              final message = data['message'] as String;
              final value = data['value'] ?? 'General';
              final timestamp = data['timestamp'] ?? Timestamp.now();
              final formattedTime = DateFormat('MMM d, yyyy - hh:mm a').format((timestamp as Timestamp).toDate());

              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                  FirebaseFirestore.instance.collection('users').doc(toUid).get(),
                ]),
                builder: (context, userSnapshots) {
                  if (!userSnapshots.hasData) {
                    return const SizedBox.shrink(); // Don't show anything while names are loading
                  }

                  final fromUserName = (userSnapshots.data![0].data() as Map<String, dynamic>?)?['fullName'] ?? 'Unknown User';
                  final toUserName = (userSnapshots.data![1].data() as Map<String, dynamic>?)?['fullName'] ?? 'Unknown User';

                  // Here we reuse our existing widget, but tell it this is an Admin View
                  return AppreciationPost(
                    postId: postId,
                    fromUid: fromUid,
                    message: message,
                    from: fromUserName,
                    to: toUserName,
                    value: value,
                    time: formattedTime,
                    isAdminView: true, // <-- The key change! We'll add this property next.
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}