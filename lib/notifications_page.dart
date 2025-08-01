// lib/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // When the page loads, mark all unread notifications as read.
    _markAllAsRead();
  }

  // This function finds all unread notifications for the user and updates them in one go.
  Future<void> _markAllAsRead() async {
    if (currentUser == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_uid', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .get();

    // A "Write Batch" is the most efficient way to update multiple documents at once.
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    // Commit the batch to send all the updates to Firebase.
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Get all notifications for the user, with the newest ones first.
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipient_uid', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no notifications yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No Title';
              final body = data['body'] ?? 'No Body';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              // The isRead field might not exist on older test data, so we default to true.
              final isRead = data['isRead'] ?? true; 

              return Container(
                color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(body),
                  trailing: Text(
                    DateFormat('MMM d').format(timestamp), // Format the date nicely
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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