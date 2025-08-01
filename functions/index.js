// This file is at: appreciation_app/functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK, which gives our function server-level access
admin.initializeApp();

/**
 * This Cloud Function is triggered whenever a new document is created
 * in the 'appreciations' collection.
 */
exports.sendAppreciationPushNotification = functions.firestore
    .document("appreciations/{appreciationId}")
    .onCreate(async (snap, context) => {
      // 1. Get the data from the new appreciation.
      const appreciationData = snap.data();
      const recipientUid = appreciationData.to_uid;
      const senderUid = appreciationData.from_uid;

      // Safety check: Don't do anything if someone appreciates themselves.
      if (recipientUid === senderUid) {
        return console.log("User appreciated themselves, no push notification sent.");
      }

      try {
        // 2. Get the recipient's user document to find their device tokens.
        const recipientDoc = await admin.firestore().collection("users").doc(recipientUid).get();
        if (!recipientDoc.exists) {
          return console.log("Recipient user document not found:", recipientUid);
        }
        
        // Get the array of FCM tokens from the user's document.
        const tokens = recipientDoc.data().fcmTokens;

        // If the user has no tokens (e.g., they've never logged in on a device), we can't do anything.
        if (!tokens || tokens.length === 0) {
          return console.log("No FCM tokens found for recipient:", recipientUid);
        }

        // 3. Get the sender's name to make the notification message personal.
        const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
        const senderName = senderDoc.exists ? senderDoc.data().fullName : "Someone";

        // 4. Construct the push notification payload.
        const payload = {
          notification: {
            title: "You've Received an Appreciation! 🎉",
            body: `${senderName} appreciated you. Tap to see!`,
          },
          // You can also add custom data to handle taps, etc.
          data: {
            // For example, you could add a key to navigate to a specific page on tap.
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "notifications_page",
          },
        };

        // 5. Use the FCM Admin SDK to send the notification to all the user's device tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log("Successfully sent push notification to user:", recipientUid);

        // Optional: Clean up invalid tokens from the user's document
        // This is an advanced step, but good practice.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
          const error = result.error;
          if (error) {
            console.error("Failure sending notification to", tokens[index], error);
            // Check for common errors that mean a token is no longer valid.
            if (error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered") {
              tokensToRemove.push(tokens[index]);
            }
          }
        });

        if (tokensToRemove.length > 0) {
          await recipientDoc.ref.update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
          });
          console.log("Cleaned up invalid tokens for user:", recipientUid);
        }

        return null;

      } catch (error) {
        console.error("Error sending push notification:", error);
        return null;
      }
    });