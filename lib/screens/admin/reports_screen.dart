import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  /// 🔥 SEND NOTIFICATION TO USER
  Future<void> _sendNotification({
    required String userId,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "title": "Support Response",
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "type": "report_reply",
    });
  }

  /// 🔥 SHOW REPLY POPUP
  void _showReplyDialog(
      BuildContext context, String docId, String userId) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Reply to Complaint",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: replyController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter your reply...",
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Send"),
              onPressed: () async {
                final reply = replyController.text.trim();
                if (reply.isEmpty) return;

                try {
                  /// 🔥 UPDATE REPORT
                  await FirebaseFirestore.instance
                      .collection('reports')
                      .doc(docId)
                      .update({
                    'reply': reply,
                    'status': 'resolved',
                  });

                  /// 🔥 SEND NOTIFICATION
                  await _sendNotification(
                    userId: userId,
                    message: reply,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Reply sent & user notified ✅"),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          /// 🔥 ERROR HANDLING (IMPORTANT FIX)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          /// 🔥 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// 🔥 EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No complaints found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return  ListView.builder(
  itemCount: reports.length,
  itemBuilder: (context, index) {
    final report = reports[index];
    final data = report.data() as Map<String, dynamic>;

    /// 🔥 SAFE VARIABLES
    final type = data['type'] ?? "report";
    final rating = data['rating'];
    final category = data['category'] ?? "general";
    final recommend = data['recommend'];

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(

        /// 🔥 TITLE
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['message'] ?? "",
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 4),

            /// CATEGORY
            Text(
              "Category: $category",
              style: const TextStyle(color: Colors.blueAccent),
            ),

            /// ⭐ RATING (only for feedback)
            if (type == "feedback" && rating != null)
              Text(
                "Rating: $rating ★",
                style: const TextStyle(color: Colors.amber),
              ),

            /// 👍 RECOMMEND
            if (recommend != null)
              Text(
                recommend ? "Recommended ✅" : "Not Recommended ❌",
                style: TextStyle(
                  color: recommend ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),

        /// 🔥 SUBTITLE
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: $type",
              style: const TextStyle(color: Colors.purpleAccent),
            ),

            Text(
              "Status: ${data['status'] ?? "pending"}",
              style: const TextStyle(color: Colors.white70),
            ),

            if (data['reply'] != null)
              Text(
                "Reply: ${data['reply']}",
                style: const TextStyle(color: Colors.greenAccent),
              ),
          ],
        ),

        /// 🔥 ACTION
        trailing: const Icon(Icons.reply, color: Colors.blueAccent),

        onTap: () {
          _showReplyDialog(
            context,
            report.id,
            data['userId'],
          );
        },
      ),
    );
  },
);
        },
      ),
    );
  }
}