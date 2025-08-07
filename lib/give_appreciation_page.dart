import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'app_user_model.dart';

class GiveAppreciationPage extends StatefulWidget {
  const GiveAppreciationPage({super.key});

  @override
  State<GiveAppreciationPage> createState() => _GiveAppreciationPageState();
}

class _GiveAppreciationPageState extends State<GiveAppreciationPage> {
  final _messageController = TextEditingController();
  final List<String> _companyValues = [
    'Respect, Trust & Integrity', 'Responsibility & Accountability', 'Collaboration, Co-creation & Team Spirit', 
    'Excellence in Execution', 'Continuous Learning & Improvement',
  ];
  String? _selectedValue;

  List<AppUser> _users = [];
  AppUser? _selectedUser;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _selectedValue = _companyValues[0];
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'employee')
          .get();
      
      final usersData = snapshot.docs
          .where((doc) => doc.data().containsKey('uid')) 
          .where((doc) => doc.data()['uid'] != currentUserId) 
          .map((doc) => AppUser(
                id: doc.id,
                fullName: doc['fullName'],
              ))
          .toList();

      usersData.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      setState(() {
        _users = usersData;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch users: $e')),
      );
    }
  }

  Future<void> submitAppreciation() async {
    // 1. Your validation logic is perfect.
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a colleague to appreciate.')),
      );
      return;
    }
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an appreciation message.')),
      );
      return;
    }

    final fromUser = FirebaseAuth.instance.currentUser;
    if (fromUser == null) return;

    // --- Start of New Logic ---
    // Wrap our database calls in a try-catch block for safety.
    try {
      // 2. Fetch the sender's full name from the 'users' collection first.
      // This makes our notification message more personal.
      final senderDoc = await FirebaseFirestore.instance.collection('users').doc(fromUser.uid).get();
      final senderName = senderDoc.data()?['fullName'] ?? 'Someone';

      // 3. Add the appreciation document (this is your existing code).
      await FirebaseFirestore.instance.collection('appreciations').add({
        'message': _messageController.text.trim(),
        'from_uid': fromUser.uid,
        'to_uid': _selectedUser!.id,
        'value': _selectedValue,
        'timestamp': Timestamp.now(),
      });

      // 4. ALSO, create the notification document for the recipient.
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_uid': _selectedUser!.id, // The person who gets the notification
        'title': "You've received a new appreciation!",
        'body': "$senderName appreciated you for $_selectedValue.",
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'appreciation',
      });

      // 5. If everything succeeds, go back to the previous page.
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // If anything goes wrong during the process, show an error message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
    // --- End of New Logic ---
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Appreciation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownSearch<AppUser>(
                      items: (filter, infiniteScrollProps) => _users,
                      
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (context, user, isSelected, isHighlighted) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  radius: 18,
                                  child: Text(
                                    user.fullName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected) 
                                  Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ],
                            ),
                          );
                        },
                        searchFieldProps: const TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: "Search colleagues...",
                            hintText: "Type to search",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Appreciate a Colleague",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      itemAsString: (AppUser user) => user.fullName,
                      
                      compareFn: (AppUser user1, AppUser user2) {
                        return user1.id == user2.id;
                      },
                      
                      onChanged: (AppUser? user) {
                        setState(() {
                          _selectedUser = user;
                        });
                      },

                      selectedItem: _selectedUser,
                    ),
              
              const SizedBox(height: 20),
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
                  hintText: 'Write your appreciation message here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitAppreciation,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Submit', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// bottom up user dropdown
/* import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'app_user_model.dart';

class GiveAppreciationPage extends StatefulWidget {
  const GiveAppreciationPage({super.key});

  @override
  State<GiveAppreciationPage> createState() => _GiveAppreciationPageState();
}

class _GiveAppreciationPageState extends State<GiveAppreciationPage> {
  final _messageController = TextEditingController();
  final List<String> _companyValues = [
    'Integrity', 'Innovation', 'Customer First', 'Teamwork', 'Excellence',
  ];
  String? _selectedValue;

  List<AppUser> _users = [];
  AppUser? _selectedUser;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _selectedValue = _companyValues[0];
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'employee')
          .get();
      
      final usersData = snapshot.docs
          .where((doc) => doc.data().containsKey('uid')) 
          .where((doc) => doc.data()['uid'] != currentUserId) 
          .map((doc) => AppUser(
                id: doc.id,
                fullName: doc['fullName'],
              ))
          .toList();

      setState(() {
        _users = usersData;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch users: $e')),
      );
    }
  }

  Future<void> submitAppreciation() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a colleague to appreciate.')),
      );
      return;
    }
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an appreciation message.')),
      );
      return;
    }

    final fromUser = FirebaseAuth.instance.currentUser;
    if (fromUser == null) return;

    await FirebaseFirestore.instance.collection('appreciations').add({
      'message': _messageController.text.trim(),
      'from_uid': fromUser.uid,
      'to_uid': _selectedUser!.id,
      'value': _selectedValue,
      'timestamp': Timestamp.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Appreciation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownSearch<AppUser>(
                      items: (filter, infiniteScrollProps) => _users,
                      
                      popupProps: PopupProps.modalBottomSheet(
                        showSearchBox: true,
                        itemBuilder: (context, user, isSelected, isHighlighted) {
                          return ListTile(
                            title: Text(user.fullName),
                            selected: isSelected,
                          );
                        },
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            labelText: "Search for a colleague",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Appreciate a Colleague",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      itemAsString: (AppUser user) => user.fullName,
                      
                      compareFn: (AppUser user1, AppUser user2) {
                        return user1.id == user2.id;
                      },
                      
                      onChanged: (AppUser? user) {
                        setState(() {
                          _selectedUser = user;
                        });
                      },

                      selectedItem: _selectedUser,
                    ),
              
              const SizedBox(height: 20),
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
                  hintText: 'Write your appreciation message here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitAppreciation,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Submit', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 */

