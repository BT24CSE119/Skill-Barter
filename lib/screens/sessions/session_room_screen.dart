import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../calling/calling_screen.dart';
class SessionRoomScreen extends StatefulWidget {
  final String sessionId;
  final String otherUserId;

  const SessionRoomScreen({
    super.key,
    required this.sessionId,
    required this.otherUserId,
  });

  @override
  State<SessionRoomScreen> createState() => _SessionRoomScreenState();
}


class _SessionRoomScreenState extends State<SessionRoomScreen> {
  final TextEditingController _msgController = TextEditingController();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// ================= CALL =================
  void _startCall() async {
    if (uid == null) return;

    final callId = _generateCallId(uid!, widget.otherUserId);

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .set({
      'callerId': uid,
      'receiverId': widget.otherUserId,
      'sessionId': widget.sessionId,
      'status': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallingScreen(
  callId: callId,
  sessionId: widget.sessionId, // 🔥 ADD THIS
  isCaller: true,
),
      ),
    );
  }
  void _showRatingDialog() {
  double rating = 3;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Rate this session ⭐"),
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
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("sessions")
                .doc(widget.sessionId)
                .update({
              "rating_$uid": rating,
            });

            Navigator.pop(context);
          },
          child: const Text("Submit"),
        )
      ],
    ),
  );
}

  String _generateCallId(String a, String b) {
    return a.compareTo(b) < 0 ? "$a-$b" : "$b-$a";
  }
Future<void> _completeSession() async {
  if (uid == null) return;

  final ref = FirebaseFirestore.instance
      .collection("sessions")
      .doc(widget.sessionId);

  final doc = await ref.get();
  final data = doc.data();

  if (data == null) return;

  /// 🔒 Prevent double completion
  if (data['status'] == "completed") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session already completed")),
    );
    return;
  }

  final type = data['type'] ?? "credit";
  final hostId = data['hostId'];
  final targetId = data['targetUserId'];

  /// ================= CREDIT SESSION =================
  if (type == "credit") {

    /// 🔒 Prevent duplicate credit processing
    if (data['creditsProcessed'] == true) return;

    /// ❌ learner pays
    await FirebaseFirestore.instance
        .collection("users")
        .doc(hostId)
        .update({
      "walletBalance": FieldValue.increment(-5),
      "totalSpent": FieldValue.increment(5),
    });

    /// ✅ teacher earns
    await FirebaseFirestore.instance
        .collection("users")
        .doc(targetId)
        .update({
      "walletBalance": FieldValue.increment(5),
      "totalEarned": FieldValue.increment(5),
    });

    /// 🧾 ADD TRANSACTIONS (IMPORTANT)
    await FirebaseFirestore.instance.collection("transactions").add({
      "userId": hostId,
      "amount": 5,
      "type": "debit",
      "title": "Learned session",
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("transactions").add({
      "userId": targetId,
      "amount": 5,
      "type": "credit",
      "title": "Taught session",
      "timestamp": FieldValue.serverTimestamp(),
    });

    await ref.update({"creditsProcessed": true});
  }

  /// ================= SWAP SESSION =================
  if (type == "swap") {
    final field = "completedBy_$uid";

    /// prevent duplicate
    if (data[field] == true) return;

    await ref.update({field: true});

    final updated = await ref.get();
    final d = updated.data();

    final hostDone = d?["completedBy_${hostId}"] == true;
    final targetDone = d?["completedBy_${targetId}"] == true;

    if (hostDone && targetDone) {
      await ref.update({
        "status": "completed",
        "completedAt": FieldValue.serverTimestamp(),
      });

      _showRatingDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiting for other user")),
      );
    }

    return;
  }

  /// ================= FINAL COMPLETE =================
  await ref.update({
    "status": "completed",
    "completedAt": FieldValue.serverTimestamp(),
  });

  _showRatingDialog();

  /// 🔥 CLOSE VIDEO CALL SCREEN
  if (mounted) Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Session Completed ✅")),
  );
}

  /// ================= SEND MESSAGE =================
  Future<void> _sendMessage() async {
    if (uid == null || _msgController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("sessions")
        .doc(widget.sessionId)
        .collection("messages")
        .add({
      "text": _msgController.text.trim(),
      "senderId": uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _msgController.clear();
  }

  /// ================= TIMER =================
  Widget _buildTimer(Timestamp? startTime) {
    if (startTime == null) {
      return const Text("00:00",
          style: TextStyle(color: Colors.white));
    }

    final start = startTime.toDate();

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (_, __) {
        final now = DateTime.now();
        final diff = now.difference(start);

        final min = diff.inMinutes.toString().padLeft(2, '0');
        final sec = (diff.inSeconds % 60).toString().padLeft(2, '0');

        return Text(
          "$min:$sec",
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
Widget _buildPremiumHeader(Map<String, dynamic> data) {
  final title = (data['topic'] ?? data['type'] ?? "Session").toString();
  final subtitle = (data['status'] ?? "ongoing").toString();

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(14),
    ),
    margin: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        _buildTimer(data['startTime']),
      ],
    ),
  );
}
Widget _buildVideoCard() {
  return Container(
    height: 200,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF1F1F1F), Color(0xFF2A2A2A)],
      ),
    ),
    child: const Center(
      child: Icon(Icons.videocam, color: Colors.white54, size: 40),
    ),
  );
}
Widget _buildEndButton() {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _completeSession(),
      icon: const Icon(Icons.call_end),
      label: const Text(
        "End Session",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
  /// ================= MESSAGE UI =================
Widget _buildMessage(Map<String, dynamic> msg) {
  final isMe = msg['senderId'] == uid;

  return Align(
    alignment:
        isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: isMe ? Colors.blueAccent : Colors.grey[800],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMe ? 14 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 14),
        ),
      ),
      child: Text(
        msg['text'] ?? "",
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Session Room"),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: _startCall,
          )
        ],
      ),

     body: Column(
  children: [

    /// 🔥 HEADER
    StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("sessions")
          .doc(widget.sessionId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.data() == null) {
          return const SizedBox();
        }

        final data = snap.data!.data() as Map<String, dynamic>;

        return _buildPremiumHeader(data);
      },
    ),


    /// 🔥 VIDEO
    _buildVideoCard(),

    const SizedBox(height: 10),

    /// 🔥 CHAT
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("sessions")
            .doc(widget.sessionId)
            .collection("messages")
            .orderBy("timestamp")
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg =
                  messages[i].data() as Map<String, dynamic>;
              return _buildMessage(msg);
            },
          );
        },
      ),
    ),

    /// 🔥 INPUT
    Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type message...",
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          )
        ],
      ),
    ),
  ],
)
    );
  }
}