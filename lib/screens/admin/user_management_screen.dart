import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        /// 👥 USER LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              /// ⏳ LOADING
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              /// ❌ NO DATA
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No users found"),
                );
              }

              /// 🔍 FILTER USERS
              final users = snapshot.data!.docs.where((doc) {
                final raw = doc.data();

if (raw == null) return false;  // ✅ SAFE

final data = raw as Map<String, dynamic>;

                if (data['disabled'] == true) return false;

                final email = (data['email'] ?? "").toLowerCase();
                return email.contains(searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child:
                            const Icon(Icons.person, color: Colors.white),
                      ),

                      /// 👤 USER INFO
                      title: Text(
                        data['email'] ?? "No Email",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        "Role: ${data['role'] ?? "user"}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      /// 👉 OPEN DETAIL SCREEN
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserDetailScreen(userId: user.id),
                          ),
                        );
                      },

                      /// ⚙️ ACTIONS
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// ❌ DELETE (SOFT DELETE)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete User"),
                                  content: const Text(
                                      "Are you sure you want to remove this user?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.id)
                                    .update({'disabled': true});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("User removed")),
                                );
                              }
                            },
                          ),

                          /// 👑 MAKE ADMIN
                          IconButton(
                            icon: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.blue),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.id)
                                  .update({'role': 'admin'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("User promoted to admin")),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}