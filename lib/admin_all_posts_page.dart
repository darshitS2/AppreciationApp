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
              final appreciation = appreciations[index];
              final data = appreciation.data() as Map<String, dynamic>;
              final postId = appreciation.id; 

              final fromUid = data['from_uid'] as String? ?? 'unknown';
              final toUid = data['to_uid'] as String? ?? 'unknown';
              final message = data['message'] as String? ?? 'No message.';
              final value = data['value'] as String? ?? 'General';
              final timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now();
              final formattedTime = DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate());

              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                  FirebaseFirestore.instance.collection('users').doc(toUid).get(),
                ]),
                builder: (context, userSnapshots) {
                  if (userSnapshots.connectionState == ConnectionState.waiting) {
                    // You can use a placeholder or shimmer effect here as well
                    return Container(height: 150, margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), color: Colors.white);
                  }
                  
                  String fromUserName = "Unknown User";
                  String toUserName = "Unknown User";

                  if (userSnapshots.hasData && userSnapshots.data != null) {
                    // FROM USER LOGIC
                    if (userSnapshots.data![0].exists) {
                      final fromData = userSnapshots.data![0].data() as Map<String, dynamic>;
                      fromUserName = fromData['fullName'] ?? 'Unknown User';
                      // Append the (Inactive) label if needed
                      if (fromData['status'] == 'inactive') {
                        fromUserName += " (Inactive)";
                      }
                    }
                    
                    // TO USER LOGIC
                    if (userSnapshots.data![1].exists) {
                      final toData = userSnapshots.data![1].data() as Map<String, dynamic>;
                      toUserName = toData['fullName'] ?? 'Unknown User';
                      // Append the (Inactive) label if needed
                      if (toData['status'] == 'inactive') {
                        toUserName += " (Inactive)";
                      }
                    }
                  }
                  
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