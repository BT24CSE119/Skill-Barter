import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MyConnectionsScreen extends StatelessWidget {
  const MyConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Using a safe getter for the UID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Connections"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text("Please log in to see connections"))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().streamMyConnections(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading connections"));
                }

                final connections = snapshot.data!;
                if (connections.isEmpty) {
                  return const Center(child: Text("No connections yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    final conn = connections[index];

                    // ✅ LOGIC: Determine who the OTHER person is in the relationship
                    final otherUser = conn['fromUserId'] == currentUserId
                        ? conn['toUserId']
                        : conn['fromUserId'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text("Connected with: $otherUser"),
                        subtitle: Text(
                          conn['timestamp'] != null
                              ? "Friends since: ${conn['timestamp'].toDate().toString().split(' ')[0]}"
                              : "Added just now",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                          onPressed: () {
                            // Navigate to chat logic here later
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}