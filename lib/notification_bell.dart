// lib/notification_bell.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_page.dart'; // We will create this page in the next step

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user
    final currentUser = FirebaseAuth.instance.currentUser;

    // If no user is logged in, don't show anything
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      // This stream listens for changes ONLY to unread notifications for the current user
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient_uid', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        // While loading or if there's an error, show a simple, non-functional bell
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Navigate to the notifications page anyway
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          );
        }

        final unreadCount = snapshot.data!.docs.length;

        // Use InkWell to make the whole area tappable
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
            );
          },
          borderRadius: BorderRadius.circular(50), // For a circular splash effect
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The main bell icon
                const Icon(Icons.notifications),

                // The red badge, which only appears if there are unread notifications
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}