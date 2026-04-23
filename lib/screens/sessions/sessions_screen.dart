import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../core/widgets/session_card.dart';
import 'session_room_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with WidgetsBindingObserver {
  final FirestoreService _service = FirestoreService();

  int _selectedTab = 0;
  bool _isRoomOpened = false;
  String _searchQuery = "";

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  void _showRatingDialog(String sessionId) {
  double rating = 3;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Rate Session ⭐"),
      content: StatefulBuilder(
        builder: (_, setState) => Slider(
          value: rating,
          min: 1,
          max: 5,
          divisions: 4,
          label: rating.toString(),
          onChanged: (v) => setState(() => rating = v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("sessions")
                .doc(sessionId)
                .set({
              "ratings": {
                FirebaseAuth.instance.currentUser!.uid: rating
              }
            }, SetOptions(merge: true));

            Navigator.pop(context);
          },
          child: const Text("Submit"),
        )
      ],
    ),
  );
}
 /// ================= OPEN LINK =================
Future<void> _openLink(String link) async {
  try {
    final uri = Uri.tryParse(link);

    if (uri == null) {
      _showSnack("Invalid link");
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack("Unable to open link");
    }
  } catch (e) {
    _showSnack("Error opening link");
  }
}
Future<void> _startSession(String otherUserId) async {
  if (uid == null) return;

  try {
    /// 🔥 CHECK WALLET
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final balance = userDoc.data()?['walletBalance'] ?? 0;

    if (balance < 5) {
      _showSnack("Not enough credits ❌");
      return;
    }

    final sessionRef =
        FirebaseFirestore.instance.collection("sessions").doc();

    /// 🔥 CREATE SESSION
    await sessionRef.set({
      "hostId": uid,
      "targetUserId": otherUserId,
      "type": "credit",

      "topic": "Skill Session",
      "duration": 60,
      "scheduledAt": FieldValue.serverTimestamp(),

      "hostCompleted": false,
      "targetCompleted": false,
      "missCount": 0,

      "participants": [uid],
      "users": [uid, otherUserId],
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    /// 🔥 CREATE REQUEST
    await FirebaseFirestore.instance.collection("sessionRequests").add({
      "fromUserId": uid,
      "toUserId": otherUserId,
      "sessionId": sessionRef.id,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    _showSnack("Session request sent ✅");

  } catch (e) {
    _showSnack("Error starting session");
    debugPrint("Start session error: $e");
  }
}

  /// ================= UI HELPERS =================
  void _showSnack(String msg) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
Future<void> _leaveSession(String id) async {
  if (uid == null) return;

  try {
    final ref = FirebaseFirestore.instance
        .collection("sessions")
        .doc(id);

    /// 🔥 FETCH DATA FIRST
    final doc = await ref.get();
    final data = doc.data();

    if (data == null) return;

    /// 🔥 PREVENT LEAVING COMPLETED SESSION
    if (data['status'] == "completed") {
      _showSnack("Session already completed");
      return;
    }

    /// ✅ REMOVE USER
    await ref.update({
      "participants": FieldValue.arrayRemove([uid]),
    });

  } catch (e) {
    _showSnack("Error leaving session");
  }
}
  /// ================= JOIN =================
Future<void> _joinSession(String id) async {
  if (uid == null) return;

  try {
    final ref = FirebaseFirestore.instance.collection("sessions").doc(id);

    final doc = await ref.get();
    final data = doc.data();
    if (data == null) return;

    final participants = List<String>.from(data['participants'] ?? []);

    if (participants.contains(uid)) return;

    if (participants.length >= 2) {
      _showSnack("Session already full");
      return;
    }

    final updatedParticipants = [...participants, uid];

    await ref.update({
      "participants": updatedParticipants,
      "status": updatedParticipants.length == 2 ? "ongoing" : "pending",
      "startTime": FieldValue.serverTimestamp(),
    });

  } catch (e) {
    _showSnack("Error joining session");
  }
}
Future<void> _setOnline() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "isOnline": true,
      "lastSeen": FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint("Online error: $e");
  }
}
Future<void> _setOffline() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "isOnline": false,
      "lastSeen": FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint("Offline error: $e");
  }
 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _setOnline();
}
}
// //


  /// ================= COMPLETE =================
Future<void> _completeSession(String sessionId) async {
  if (uid == null) return;

  final ref = FirebaseFirestore.instance
      .collection("sessions")
      .doc(sessionId);

  try {
    final doc = await ref.get();
    final data = doc.data();

    if (data == null) return;

    /// 🔒 Prevent double completion
    if (data['status'] == "completed") {
      _showSnack("Session already completed");
      return;
    }

    final type = data['type'] ?? "credit";

    /// 🔥 DEFINE IDS (FIXED)
    final hostId = data['hostId'];
    final targetId = data['targetUserId'];

    /// ================= CREDIT SESSION =================
    if (type == "credit") {

      /// 🔒 Prevent duplicate credit processing
      if (data['creditsProcessed'] == true) return;

      /// 👨‍🏫 HOST TEACHES → +5
      await FirebaseFirestore.instance.collection("transactions").add({
        "userId": hostId,
        "amount": 5,
        "type": "credit",
        "title": "Earned from session",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(hostId)
          .update({
        "walletBalance": FieldValue.increment(5),
        "totalEarned": FieldValue.increment(5),
      });

      /// 🎓 TARGET LEARNS → -5
      await FirebaseFirestore.instance.collection("transactions").add({
        "userId": targetId,
        "amount": 5,
        "type": "debit",
        "title": "Spent on session",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(targetId)
          .update({
        "walletBalance": FieldValue.increment(-5),
        "totalSpent": FieldValue.increment(5),
      });

      /// 🔥 MARK COMPLETE
     await ref.update({
  "creditsProcessed": true,
  "status": "completed",
  "completedAt": FieldValue.serverTimestamp(),
});

      /// 🔥 ADMIN LOG
      await FirebaseFirestore.instance
          .collection("admin_sessions")
          .add({
        "sessionId": sessionId,
        "type": "credit",
        "hostId": hostId,
        "targetId": targetId,
        "status": "completed",
        "timestamp": FieldValue.serverTimestamp(),
      });

      _showRatingDialog(sessionId);
      return;
    }

    /// ================= SWAP SESSION =================
    if (type == "swap") {

      if (uid == hostId) {
        await ref.update({"hostCompleted": true});
      } else {
        await ref.update({"targetCompleted": true});
      }

      final updated = await ref.get();
      final d = updated.data();

      if (d?['hostCompleted'] == true &&
          d?['targetCompleted'] == true) {

        await ref.update({
          "status": "completed",
          "completedAt": FieldValue.serverTimestamp(),
        });

        /// 🔥 ADMIN LOG
        await FirebaseFirestore.instance
            .collection("admin_sessions")
            .add({
          "sessionId": sessionId,
          "type": "swap",
          "hostId": hostId,
          "targetId": targetId,
          "status": "completed",
          "timestamp": FieldValue.serverTimestamp(),
        });

        _showRatingDialog(sessionId);

      } else {
        _showSnack("Now learn from other user");
      }

      return;
    }

  } catch (e) {
    _showSnack("Error completing session");
    debugPrint("Complete session error: $e");
  }
}
  
/// ================= OPEN ROOM =================
void _openRoom(String id, String otherUserId) {
  if (_isRoomOpened || !mounted) return;

  _isRoomOpened = true;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SessionRoomScreen(
        sessionId: id,
        otherUserId: otherUserId,
      ),
    ),
  ).then((_) {
    if (mounted) {
      _isRoomOpened = false;
    }
  });
}


@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _setOffline();
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _setOnline();
  }

  /// 🔥 Only mark offline when actually backgrounded
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached) {
    _setOffline();
  }
}
  /// ================= BUILD =================
  @override
Widget build(BuildContext context) {
  final currentUid = uid;

  if (currentUid == null) {
    return const Scaffold(
      body: Center(child: Text("Please login")),
    );
  }

  /// 🔥 SELECT BODY BASED ON TAB
  Widget bodyContent;

  switch (_selectedTab) {
    case 0:
      bodyContent = _buildConnectedUsers();
      break;
    case 1:
      bodyContent = _buildIncomingRequests();
      break;
    case 2:
      bodyContent = _buildOngoingSessions();
      break;
    case 3:
      bodyContent = _buildCompletedSessions();
      break;
    default:
      bodyContent = const Center(child: Text("Invalid tab"));
  }

  return Scaffold(
    backgroundColor: const Color(0xFF121212), // 🔥 dark theme
    appBar: AppBar(
      title: const Text("Sessions"),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Column(
        children: [
          _buildSearch(),
          _buildTabs(),
          Expanded(child: bodyContent),
        ],
      ),
    ),
  );
}
  Widget _buildIncomingRequests() {
  final currentUid = uid;

  if (currentUid == null) {
    return const Center(child: Text("User not logged in"));
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("sessionRequests")
        .where("toUserId", isEqualTo: currentUid)
        .where("status", isEqualTo: "pending")
        .snapshots(),
    builder: (context, snap) {

      /// 🔄 LOADING
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      /// ❌ ERROR
      if (snap.hasError) {
        return const Center(child: Text("Error loading requests"));
      }

      final docs = snap.data?.docs ?? [];

      /// 📭 EMPTY
      if (docs.isEmpty) {
        return const Center(child: Text("No pending requests"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        itemBuilder: (_, i) {

          final doc = docs[i];
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) return const SizedBox();

          final fromUserId = data['fromUserId'] ?? "Unknown";
          final sessionId = data['sessionId'];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                )
              ],
            ),
            child: Row(
              children: [

                /// 👤 AVATAR
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    fromUserId[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(width: 12),

                /// 📄 INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "User: $fromUserId",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Wants to start a session",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                /// ❌ REJECT
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    try {
                      await doc.reference.update({
                        "status": "rejected"
                      });
                    } catch (e) {
                      _showSnack("Error rejecting request");
                    }
                  },
                ),

                /// ✅ ACCEPT
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    try {
                      await doc.reference.update({
                        "status": "accepted"
                      });

                      await _joinSession(sessionId);

                      _openRoom(sessionId, fromUserId);

                    } catch (e) {
                      _showSnack("Error accepting request");
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
Widget _buildSearch() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search sessions...",
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

  /// ================= TABS =================
 Widget _buildTabs() {
  final tabs = ["Friends", "Requests", "Ongoing", "Completed"];

  return SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: tabs.length,
      itemBuilder: (context, i) {
        final selected = _selectedTab == i;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() => _selectedTab = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blueAccent
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.blueAccent
                      : Colors.grey.shade600,
                ),
              ),
              child: Row(
                children: [

                  /// 🔥 OPTIONAL ICONS
                  Icon(
                    i == 0
                        ? Icons.people
                        : i == 1
                            ? Icons.notifications
                            : i == 2
                                ? Icons.play_circle
                                : Icons.check_circle,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : Colors.grey,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    tabs[i],
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
 Widget _buildUserCard({
  required String name,
  required bool isOnline,
  required String buttonText,
  required VoidCallback onTap,
  String? skill,
  bool isLoading = false, // 🔥 NEW
}) {
  final displayName =
      (name.trim().isEmpty) ? "User" : name.trim();

  final initial = displayName[0].toUpperCase();

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap, // 🔥 whole card clickable
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [

          /// 👤 AVATAR (IMPROVED)
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// 🟢 ONLINE DOT
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          /// 📄 INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                /// SKILL
                Text(
                  skill?.isNotEmpty == true
                      ? skill!
                      : "No skill added",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                /// STATUS
                Text(
                  isOnline ? "Active now" : "Offline",
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// 🚀 BUTTON
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isLoading ? null : onTap,
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
          )
        ],
      ),
    ),
  );
}

  /// ================= STREAM =================
Widget _buildConnectedUsers() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("connectionRequests")
        .where("status", isEqualTo: "accepted")
        .snapshots(),
    builder: (context, snap) {

      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final connections = snap.data!.docs.where((doc) {
        final raw = doc.data();
        if (raw == null) return false;

        final d = raw as Map<String, dynamic>;

        return d['status'] == "accepted" &&
               (d['fromUserId'] == uid || d['toUserId'] == uid);
      }).toList();

      if (connections.isEmpty) {
        return const Center(child: Text("No connections"));
      }

      return ListView.builder(
        itemCount: connections.length,
        itemBuilder: (_, i) {

          final raw = connections[i].data(); // ✅ FIX

          if (raw == null) {
            return const SizedBox();
          }

          final data = raw as Map<String, dynamic>;

          final otherUserId =
              data['fromUserId'] == uid
                  ? data['toUserId']
                  : data['fromUserId'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("users")
                .doc(otherUserId)
                .get(),
            builder: (context, userSnap) {

              if (!userSnap.hasData ||
                  userSnap.data!.data() == null) {
                return const SizedBox();
              }

              final user =
                  userSnap.data!.data() as Map<String, dynamic>;

              final name = user['name'] ?? "User";
              final isOnline = user['isOnline'] ?? false;

              return Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [

                    CircleAvatar(
                      child: Text(name[0]),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isOnline ? "🟢 Active" : "🔴 Offline",
                            style: TextStyle(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.red),
                          ),
                        ],
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        _startSession(otherUserId);
                      },
                      child: const Text("Start"),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
Widget _buildOngoingSessions() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("sessions")
        .where("status", isEqualTo: "ongoing")
        .snapshots(),
    builder: (context, snap) {

      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

     final sessions = snap.data!.docs.where((doc) {
  final raw = doc.data();
  if (raw == null) return false;

  final data = raw as Map<String, dynamic>;

  final participants =
      List<String>.from(data['participants'] ?? []);
final users = List<String>.from(data['users'] ?? []);
return users.contains(uid) && data['status'] == "ongoing";
 
}).toList();

      if (sessions.isEmpty) {
        return const Center(child: Text("No ongoing sessions"));
      }

      return ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, i) {

          final raw = sessions[i].data();
          if (raw == null) return const SizedBox();

          final data = raw as Map<String, dynamic>;

          final sessionId = sessions[i].id;
          final participants =
              List<String>.from(data['participants'] ?? []);

          final otherUserId = participants.firstWhere(
  (id) => id != uid,
  orElse: () => "",
);
if (otherUserId.isEmpty) {
  return const SizedBox(); // skip broken session
}

          return ListTile(
            title: Text(data['type'] ?? "Session"),
            subtitle: const Text("Tap to join"),

            trailing: ElevatedButton(
              onPressed: () async {
  await _joinSession(sessionId); // ensure sync
  _openRoom(sessionId, otherUserId);
},
              child: const Text("Join"),
            ),
          );
        },
      );
    },
  );
}
Widget _buildCompletedSessions() {
  final currentUid = uid;

  if (currentUid == null) {
    return const Center(child: Text("User not logged in"));
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("sessions")
        .where("status", isEqualTo: "completed")
        .orderBy("completedAt", descending: true)
        .snapshots(),
    builder: (context, snap) {

      /// 🔄 LOADING
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      /// ❌ ERROR
      if (snap.hasError) {
        return const Center(child: Text("Error loading sessions"));
      }

      final docs = snap.data?.docs ?? [];

      /// 🔥 FILTER (FIXED)
      final sessions = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null) return false;

        /// ✅ PRIMARY (stable)
        final users = List<String>.from(data['users'] ?? []);

        /// ⚠️ fallback for old data
        if (users.isEmpty) {
          final participants =
              List<String>.from(data['participants'] ?? []);
          return participants.contains(currentUid);
        }

        return users.contains(currentUid);
      }).toList();

      /// 📭 EMPTY
      if (sessions.isEmpty) {
        return const Center(child: Text("No completed sessions"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sessions.length,
        itemBuilder: (_, i) {

          final doc = sessions[i];
          final data = doc.data() as Map<String, dynamic>;

          final type = data['type'] ?? "Session";
          final duration = data['duration'] ?? 60;
          final isCredit = type == "credit";

          final otherUserId =
              (data['hostId'] == currentUid)
                  ? data['targetUserId']
                  : data['hostId'];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                )
              ],
            ),
            child: Row(
              children: [

                /// 🔵 ICON
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      isCredit ? Colors.orange : Colors.blueAccent,
                  child: Icon(
                    isCredit
                        ? Icons.monetization_on
                        : Icons.swap_horiz,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 14),

                /// 📄 INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// TITLE
                      Text(
                        isCredit
                            ? "Credit Session"
                            : "Swap Session",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// DETAILS
                      Text(
                        "Duration: $duration mins",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "With: $otherUserId",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 6),

                      /// STATUS
                      Row(
                        children: const [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Completed",
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ⭐ RATE
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () {
                    _showRatingDialog(doc.id);
                  },
                )
              ],
            ),
          );
        },
      );
    },
  );
}
  /// ================= FORMAT =================
  String _formatTime(dynamic ts) {
    if (ts == null) return "No time";

    final date = (ts as Timestamp).toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute}";
  }

  /// ================= CREATE =================
  
}