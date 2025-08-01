import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appreciation_app/fcm_helper.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const SignUpPage({super.key, required this.showLoginPage});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSigningUp = false;

  Future<void> signUp() async {
    // Show a loading indicator
    setState(() { _isSigningUp = true; });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    // Check if passwords match
    if (password != _confirmPasswordController.text.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
      }
      setState(() { _isSigningUp = false; });
      return;
    }

    try {
      // 1. AUTHORIZATION: Check if the user is pre-registered by an admin
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This email is not authorized. Contact an administrator.')),
          );
        }
        setState(() { _isSigningUp = false; });
        return;
      }

      // A user doc exists. Check if it's already been registered.
      final preRegisteredUserDoc = userQuery.docs.first;
      if ((preRegisteredUserDoc.data()).containsKey('uid')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account is already registered. Please log in.')),
          );
        }
        setState(() { _isSigningUp = false; });
        return;
      }

      // 2. REGISTRATION & LINKING
      
      // Create the user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // This is the correct "re-keying" logic.
      // We create a NEW document using the UID from FirebaseAuth as the document ID.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid) // Use the new UID as the doc ID
          .set({
            'fullName': preRegisteredUserDoc.data()['fullName'],
            'email': preRegisteredUserDoc.data()['email'],
            'role': preRegisteredUserDoc.data()['role'],
            'uid': userCredential.user!.uid, // Store the UID in the document as well
            'status': 'active',
          });
          
      // Finally, delete the original, temporary pre-registered document.
      await preRegisteredUserDoc.reference.delete();
      
      // After a successful sign-up and document creation, save the device token.
      await FcmHelper.saveTokenToFirestore();

      // The user will now be logged in, and the AuthGate will successfully find their document.

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up failed: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSigningUp = false; });
      }
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.app_registration, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Hello There!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Register below with your details!",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 50),

                // Email textfield
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Password textfield
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm password textfield
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSigningUp ? null : signUp, // Disable button while loading
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSigningUp
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 25),

                // Already a member? Login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already a member?'),
                    GestureDetector(
                      onTap: widget.showLoginPage,
                      child: const Text(
                        ' Login now',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}