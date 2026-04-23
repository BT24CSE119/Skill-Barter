import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Requests"),
        backgroundColor: Colors.black,
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text("Login Required", style: TextStyle(color: Colors.white)))
          : StreamBuilder<List<Map<String, dynamic>>>(
             stream: const Stream.empty(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!;

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Requests 😴",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    final fromUserId = request['fromUserId'] ?? "";
                    final requestId = request['id'] ?? "";

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(fromUserId)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox();
                        }

                        final userData =
                            userSnap.data!.data() as Map<String, dynamic>?;

                        final name = userData?['name'] ?? "User";
                        final photo = userData?['photoUrl'] ?? "";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            /// PROFILE IMAGE
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey,
                              backgroundImage:
                                  photo.isNotEmpty ? NetworkImage(photo) : null,
                              child: photo.isEmpty
                                  ? Text(name[0].toUpperCase())
                                  : null,
                            ),

                            /// NAME
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: const Text(
                              "Wants to connect with you",
                              style: TextStyle(color: Colors.white70),
                            ),

                            /// ACTION BUTTONS
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// ❌ REJECT
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await FirestoreService()
                                        .declineConnectionRequest(requestId);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("Rejected ❌")),
                                      );
                                    }
                                  },
                                ),

                                /// ✅ ACCEPT
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () async {
                                    await FirestoreService()
                                        .acceptConnectionRequest(requestId);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("Connected ✅")),
                                      );
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
}