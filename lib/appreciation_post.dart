import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_appreciation_page.dart';

class AppreciationPost extends StatelessWidget {
  final String message;
  final String from;
  final String to;
  final String value;
  final String time;
  final bool showSender;
  final String postId; 
  final String fromUid;
  final bool showMessage;
  final bool isAdminView;

  const AppreciationPost({
    super.key,
    required this.message,
    required this.from,
    required this.to,
    required this.value,
    required this.time,
     required this.postId,
    required this.fromUid,
    this.showSender = true,
    this.showMessage = true,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
  // Get the current user to check for ownership
  final currentUser = FirebaseAuth.instance.currentUser;

  // Function to show a delete confirmation dialog (this can stay the same)
  void showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this appreciation?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('appreciations').doc(postId).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---- THIS IS THE NEW UI STRUCTURE ----
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Avatar, Names, and Menu Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                to.isNotEmpty ? to[0] : '?', // Display the first letter of the recipient's name
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),

            // Names and Timestamp Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        if (showSender) ...[
                          TextSpan(
                            text: from,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '  →  '),
                        ],
                        TextSpan(
                          text: to,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // Menu Button
          if (isAdminView || (currentUser != null && currentUser.uid == fromUid))
            SizedBox(
              height: 24, // Constrain the button's size
              width: 24,
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAppreciationPage(postId: postId),
                      ),
                    );
                  } else if (value == 'delete') {
                    showDeleteDialog();
                  }
                },
              ),
            ),
          ],
        ),

        if (showMessage) ...[
          const SizedBox(height: 12),

          // Message Text
          Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],

        const SizedBox(height: 12),

        // Value Chip at the bottom
        Align(
          alignment: Alignment.centerRight,
          child: Chip(
            label: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    ),
  );
}
}