// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_page.dart';
import 'login_or_signup_page.dart';
import 'main.dart'; // Contains AppreciationFeed

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // User is not logged in, show login/signup page
          if (!authSnapshot.hasData) {
            return const LoginOrSignUpPage();
          }

          // User IS logged in, now check their role using a real-time stream
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, userDocSnapshot) {
              // --- THIS IS THE KEY CHANGE ---
              // If we're waiting for data OR the user document doesn't exist yet (the race condition),
              // just show a loading circle. The stream will automatically update once the doc is created.
              if (userDocSnapshot.connectionState == ConnectionState.waiting || !userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }
              // -----------------------------

              // If there's a specific error from Firestore, handle it
              if (userDocSnapshot.hasError) {
                return const Center(child: Text("Error fetching user data."));
              }
              
              // We have the user document, let's check the role
              final userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
              final role = userData['role'] ?? 'employee';

              if (role == 'admin') {
                // User is an admin, show the admin dashboard
                return const AdminDashboardPage();
              } else {
                // User is an employee, show the regular feed
                return const AppreciationFeed();
              }
            },
          );
        },
      ),
    );
  }
}