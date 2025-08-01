import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_all_posts_page.dart';
import 'admin_manage_users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add some padding around the edges
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch to fill width
          children: [
            // First Panel: View All Appreciations
            Expanded(
              child: Card(
                elevation: 4, // Give it a nice shadow
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell( // Makes the whole card tappable with a splash effect
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminAllPostsPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16), // Match the card's border radius
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 48, color: Colors.blue),
                      SizedBox(height: 10),
                      Text("View All Appreciations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16), // Space between the cards

            // Second Panel: Manage Users
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminManageUsersPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add, size: 48, color: Colors.blue),
                      SizedBox(height: 10),
                      Text("Manage Users", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}