import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirestoreService _firestore = FirestoreService();

  final Map<String, String> _userCache = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view chats.")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      appBar: AppBar(
        title: const Text("Chats 💬"),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.streamUserChats(uid), // 🔥 MUST EXIST
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No chats yet 💬"));
          }

          final chats = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final List users = chat['users'] ?? [];

              final String otherUserId = users.firstWhere(
                (u) => u != uid,
                orElse: () => "",
              );

              final String lastMessage =
                  chat['lastMessage'] ?? "Start chatting...";

              return FutureBuilder<String>(
                future: _getUserName(otherUserId),
                builder: (context, snap) {
                  final name = snap.data ?? "User";

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),

                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: const Icon(Icons.chat),

                    onTap: () {
                      if (otherUserId.isEmpty) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: otherUserId,
                            otherUserName: name,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return "User";

    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final name = doc.data()?['name'] ?? "User";

      _userCache[userId] = name;

      return name;
    } catch (e) {
      return "User";
    }
  }
}