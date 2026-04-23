import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connection Requests"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
stream: const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No requests yet 💌", style: TextStyle(fontSize: 16)),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              final fromUserId = req['fromUserId'] ?? "";

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUser(fromUserId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final name = userData?['name'] ?? "Unknown User";
                  final photo = userData?['photoUrl'] ?? "";

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          const Text("Wants to connect with you"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ❌ DECLINE
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await _firestore
                                  .declineConnectionRequest(fromUserId);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Request declined")),
                                );
                              }
                            },
                          ),

                          // ✅ ACCEPT
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              try {
                                await _firestore
                                    .acceptConnectionRequest(fromUserId);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "You are now connected with $name!")),
                                  );

                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                debugPrint(
                                    "Error accepting request: $e");
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}