import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FcmHelper {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // This function is still great for asking for permission
  static Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // We no longer need to get the token here, as we'll do it on login/signup
  }

  // --- THIS IS THE NEW, IMPORTANT FUNCTION ---
  static Future<void> saveTokenToFirestore() async {
    // Get the current logged-in user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("FcmHelper: Cannot save token, no user is logged in.");
      return;
    }

    try {
      // Get the unique FCM token for this specific device
      final fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken == null) {
        print("FcmHelper: Could not get FCM token.");
        return;
      }

      print("FCM Token found: $fcmToken");

      // Get the reference to the user's document in Firestore
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Use .update() to add the token to the 'fcmTokens' array.
      // FieldValue.arrayUnion ensures we don't add duplicate tokens.
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([fcmToken]),
      });

      print("FCM token successfully saved for user: ${user.uid}");

    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }
}