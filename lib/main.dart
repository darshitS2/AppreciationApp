// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'firebase_options.dart';
import 'auth_gate.dart'; // Import our new AuthGate
import 'give_appreciation_page.dart';
import 'appreciation_post.dart';
import 'package:intl/intl.dart'; // We'll use this to format the date
import 'profile_page.dart';
import 'notification_bell.dart';
import 'fcm_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FcmHelper.initialize();

  runApp(const AppreciationApp());
}

class AppreciationApp extends StatelessWidget {
  const AppreciationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // This removes the debug banner
      title: 'Appreciation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthGate(), // Use the AuthGate as the home page
    );
  }
}

class AppreciationFeed extends StatefulWidget {
  const AppreciationFeed({super.key});

  @override
  State<AppreciationFeed> createState() => _AppreciationFeedState();
}

class _AppreciationFeedState extends State<AppreciationFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appreciation Feed'),
        actions: [
          const NotificationBell(), 
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Add a sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('appreciations').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5, // Show 5 shimmering placeholders
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 150, // Approximate height of your post card
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                  "No appreciations yet... Be the first to give one!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appreciations yet.'));
          }
          final appreciations = snapshot.data!.docs;
          return ListView.builder(
            itemCount: appreciations.length,
            itemBuilder: (context, index) {
              // Get the specific appreciation document
              final appreciation = appreciations[index];
              final postId = appreciation.id;

              // Get the data from the appreciation document
              final fromUid = appreciation['from_uid'] as String;
              final toUid = appreciation['to_uid'] as String;
              final message = appreciation['message'] as String;
              final value = appreciation.data().toString().contains('value') ? appreciation.get('value') as String : 'General';
              final timestamp = appreciation.data().toString().contains('timestamp') 
                ? appreciation.get('timestamp') as Timestamp 
                : Timestamp.now(); // Provide a default value if it's missing
              final formattedTime = DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate());

              // Now, we need to find the full name of the user who sent this
              // We do this by looking in our 'users' collection
              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                  FirebaseFirestore.instance.collection('users').doc(toUid).get(),
                ]),
                builder: (context, userSnapshots) {
                  if (!userSnapshots.hasData) {
                    return Container(height: 100, margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), color: Colors.white);
                  }

                  // We found the users! Get their full names.
                  final fromUserName = userSnapshots.data![0]['fullName'] as String;
                  final toUserName = userSnapshots.data![1]['fullName'] as String;

                  // Use our new, beautiful AppreciationPost widget
                  return AppreciationPost(
                    postId: postId,           // <-- ADD THIS
                    fromUid: fromUid,
                    message: message,
                    from: fromUserName,
                    to: toUserName, 
                    value: value,
                    time: formattedTime,
                    showSender: false,
                    showMessage: false,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // This is the action that happens when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GiveAppreciationPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}