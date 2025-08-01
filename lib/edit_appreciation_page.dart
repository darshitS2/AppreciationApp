// lib/edit_appreciation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAppreciationPage extends StatefulWidget {
  final String postId; // This page receives the ID of the post to edit

  const EditAppreciationPage({super.key, required this.postId});

  @override
  State<EditAppreciationPage> createState() => _EditAppreciationPageState();
}

class _EditAppreciationPageState extends State<EditAppreciationPage> {
  final _messageController = TextEditingController();
  final List<String> _companyValues = [
    'Respect, Trust & Integrity', 'Responsibility & Accountability', 'Collaboration, Co-creation & Team Spirit', 
    'Excellence in Execution', 'Continuous Learning & Improvement',
  ];
  String? _selectedValue;
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _fetchPostData(); // Fetch the post data when the page loads
  }

  // Function to get the existing post data from Firestore
  Future<void> _fetchPostData() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('appreciations')
          .doc(widget.postId) // Use the postId passed to this page
          .get();

      if (postDoc.exists) {
        final data = postDoc.data()!;
        // Pre-fill the form fields with the existing data
        setState(() {
          _messageController.text = data['message'];
          _selectedValue = data['value'];
          _isLoading = false; // Stop loading
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load post data: $e')),
      );
    }
  }

  // Function to UPDATE the post in Firestore
  Future<void> saveChanges() async {
    if (_messageController.text.isEmpty) return;

    // Use the .update() method on the specific document
    await FirebaseFirestore.instance
        .collection('appreciations')
        .doc(widget.postId)
        .update({
          'message': _messageController.text.trim(),
          'value': _selectedValue,
        });

    if (mounted) {
      Navigator.pop(context); // Go back to the feed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appreciation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'Select a Company Value',
                      border: OutlineInputBorder(),
                    ),
                    items: _companyValues.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Edit your appreciation message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveChanges,
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