import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserPage extends StatefulWidget {
  final String userId; // Receive the document ID of the user to edit

  const EditUserPage({super.key, required this.userId});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _fullNameController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _fullNameController.text = userData['fullName'] ?? '';
          _selectedRole = userData['role'] ?? 'employee';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty || _selectedRole == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
          'fullName': fullName,
          'role': _selectedRole,
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  // ---- THIS IS THE NEW SOFT DELETE FUNCTION ----
  Future<void> _softDeleteUser() async {
    // Show a confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User?'),
        content: const Text(
          'This will mark the user as inactive. They will not be able to log in and will be hidden from lists. This action is reversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Update the user's status to 'inactive'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'status': 'inactive'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          // Add the delete icon button to the app bar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _softDeleteUser,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                  // We use DropdownButtonFormField for the role selection
                  if (_selectedRole != null)
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
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}