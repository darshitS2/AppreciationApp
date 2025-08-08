// lib/admin_manage_users_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add_user_page.dart';
import 'edit_user_page.dart';

// --- STEP 1: CONVERT TO STATEFUL WIDGET ---
class AdminManageUsersPage extends StatefulWidget {
  const AdminManageUsersPage({super.key});

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  // --- STEP 2: ADD STATE VARIABLES ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedStatus = "active"; // Default to 'active'
  String _selectedRole = "all"; // Default to 'all'

  @override
  void initState() {
    super.initState();
    // Add a listener to the search controller to update the UI in real-time
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterDialog() async {
    // These will hold the temporary selections within the dialog
    String tempStatus = _selectedStatus;
    String tempRole = _selectedRole;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Users'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter by Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: tempStatus == 'active',
                        onSelected: (selected) => setDialogState(() => tempStatus = 'active'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Inactive'),
                        selected: tempStatus == 'inactive',
                        onSelected: (selected) => setDialogState(() => tempStatus = 'inactive'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Filter by Role", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap( // Use Wrap to handle different screen sizes gracefully
                    spacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempRole == 'all',
                        onSelected: (selected) => setDialogState(() => tempRole = 'all'),
                      ),
                      ChoiceChip(
                        label: const Text('Admin'),
                        selected: tempRole == 'admin',
                        onSelected: (selected) => setDialogState(() => tempRole = 'admin'),
                      ),
                      ChoiceChip(
                        label: const Text('Employee'),
                        selected: tempRole == 'employee',
                        onSelected: (selected) => setDialogState(() => tempRole = 'employee'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply the changes to the main page's state
                    setState(() {
                      _selectedStatus = tempStatus;
                      _selectedRole = tempRole;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // We will build the UI and logic in the build method next.
  @override
  Widget build(BuildContext context) {
    // ---- THIS IS THE NEW FILTER DIALOG METHOD ----

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddUserPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- THIS IS THE NEW SEARCH & FILTER BAR UI ----
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Bar takes up most of the space
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter Button
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Users',
                ),
              ],
            ),
          ),
          // ---------------------------------------------
          
          const Divider(thickness: 1, height: 0),

          // USER LIST (This part remains exactly the same)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                // The filter logic here works perfectly with the new UI
                List<DocumentSnapshot> filteredUsers = snapshot.data!.docs;
                
                filteredUsers = filteredUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'inactive') == _selectedStatus;
                }).toList();
                
                if (_selectedRole != 'all') {
                  filteredUsers = filteredUsers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['role'] == _selectedRole;
                  }).toList();
                }
                
                if (_searchQuery.isNotEmpty) {
                  filteredUsers = filteredUsers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] as String? ?? '').toLowerCase();
                    final email = (data['email'] as String? ?? '').toLowerCase();
                    return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                filteredUsers.sort((a, b) {
                  final nameA = (a.data() as Map<String, dynamic>)['fullName'] as String? ?? '';
                  final nameB = (b.data() as Map<String, dynamic>)['fullName'] as String? ?? '';
                  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                });

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final fullName = userData['fullName'] ?? 'No Name';
                    final email = userData['email'] ?? 'No Email';
                    final role = userData['role'] ?? 'employee';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                          child: Icon(role == 'admin' ? Icons.admin_panel_settings : Icons.person),
                        ),
                        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(email),
                        trailing: Text(role),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditUserPage(userId: userDoc.id))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}