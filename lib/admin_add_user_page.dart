// lib/admin_add_user_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddUserPage extends StatefulWidget {
  const AdminAddUserPage({super.key});

  @override
  State<AdminAddUserPage> createState() => _AdminAddUserPageState();
}

class _AdminAddUserPageState extends State<AdminAddUserPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'employee'; // Default role is 'employee'

  // Function to add the new user document to Firestore
  Future<void> _addUser() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    // Basic validation
    if (fullName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }
    
    // Check if a user with this email already exists
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A user with this email already exists.')),
      );
      return;
    }

    // Add the new user document to the 'users' collection
    await FirebaseFirestore.instance.collection('users').add({
      'fullName': fullName,
      'email': email,
      'role': _selectedRole,
      'status': 'active',
      // Note: We are NOT creating a FirebaseAuth account here.
    });

    if (mounted) {
      // Show success message and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User successfully added.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('Employee')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addUser,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Add User', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}