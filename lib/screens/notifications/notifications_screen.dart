import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_screen.dart';
import '../../services/firestore_service.dart';
import '../calling/calling_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _search = "";
  String _filter = "All";

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "";
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${d.day}/${d.month}/${d.year}";
  }

  Icon _icon(String title) {
    if (title.contains("Badge")) {
      return const Icon(Icons.emoji_events, color: Colors.orange);
    } else if (title.contains("Connection")) {
      return const Icon(Icons.people, color: Colors.green);
    }
    return const Icon(Icons.notifications, color: Colors.blue);
  }

  Future<void> _markRead(String id) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(id)
        .update({"read": true});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(id)
        .delete();
  }

  Future<void> _togglePin(String id, bool pinned) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(id)
        .update({"pinned": !pinned});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search notifications...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["All", "Unread", "Pinned"].map((f) {
                return ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  selectedColor: Colors.redAccent,
                  onSelected: (_) {
                    setState(() => _filter = f);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("userId", isEqualTo: uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Text("Loading notifications..."),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error loading notifications"),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No notifications found"),
                  );
                }

                List<QueryDocumentSnapshot> docs =
                    snapshot.data!.docs;

                docs = docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final title =
                      (d['title'] ?? "").toLowerCase();
                  final msg =
                      (d['message'] ?? "").toLowerCase();

                  final read =
                      d.containsKey('read') ? d['read'] : false;
                  final pinned =
                      d.containsKey('pinned') ? d['pinned'] : false;

                  if (_filter == "Unread" && read == true)
                    return false;
                  if (_filter == "Pinned" && pinned != true)
                    return false;

                  if (_search.isNotEmpty &&
                      !title.contains(_search) &&
                      !msg.contains(_search)) {
                    return false;
                  }

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No matching notifications"),
                  );
                }

                docs.sort((a, b) {
                  final ap =
                      (a.data() as Map)['pinned'] == true;
                  final bp =
                      (b.data() as Map)['pinned'] == true;
                  return (bp ? 1 : 0) - (ap ? 1 : 0);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    return _card(docs[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot doc) {
    final raw = doc.data();

if (raw == null) return Container(); // ✅ SAFE

final data = raw as Map<String, dynamic>;
     final read = data['read'] ?? false;
    final pinned = data['pinned'] ?? false;
    if (data['type'] == "report_reply") {
  return GestureDetector(
    onTap: () async {
      await _markRead(doc.id);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(data['title'] ?? "Support"),
          content: Text(data['message'] ?? ""),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    },

    onLongPress: () {
      showModalBottomSheet(
        context: context,
        builder: (_) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text("Mark as Read"),
              onTap: () {
                Navigator.pop(context);
                _markRead(doc.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(pinned ? "Unpin" : "Pin"),
              onTap: () {
                Navigator.pop(context);
                _togglePin(doc.id, pinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete"),
              onTap: () {
                Navigator.pop(context);
                _delete(doc.id);
              },
            ),
          ],
        ),
      );
    },

    child: Card(
      color: Colors.blueGrey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.support_agent, color: Colors.lightBlue),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "Support",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['message'] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(data['timestamp']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            if (!read)
              TextButton(
                onPressed: () => _markRead(doc.id),
                child: const Text("Mark read"),
              ),
          ],
        ),
      ),
    ),
  );
}

   

    final type = data['type'] ?? "";

    if (type == "video_call_request") {
      return Card(
        elevation: pinned ? 6 : 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'] ?? "Video Call Request",
                style:
                    const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(data['message'] ??
                  "Incoming video call request"),
              const SizedBox(height: 10),

              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    onPressed: () async {
                      await FirestoreService();
                         

                      await FirebaseFirestore.instance
                          .collection("notifications")
                          .doc(doc.id)
                          .update({"read": true});

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (_) => CallingScreen(
  callId: "test_call",
  sessionId: "test_call", // temporary fix
  isCaller: false,
),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await FirestoreService();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        await _markRead(doc.id);

        if (data['title'] != null &&
            data['title'].contains("Connection")) {
          if (data['senderId'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProfileScreen(userId: data['senderId']),
              ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(data['title'] ?? "Notification"),
              content: Text(data['message'] ?? ""),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text("Mark as Read"),
                onTap: () {
                  Navigator.pop(context);
                  _markRead(doc.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text(pinned ? "Unpin" : "Pin"),
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(doc.id, pinned);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  _delete(doc.id);
                },
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: pinned ? 6 : 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: pinned ? Colors.yellow.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _icon(data['title'] ?? ""),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Notification",
                      style: TextStyle(
                        fontWeight: read
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['message'] ?? "",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(data['timestamp']),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!read)
                TextButton(
                  onPressed: () => _markRead(doc.id),
                  child: const Text("Mark read"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}