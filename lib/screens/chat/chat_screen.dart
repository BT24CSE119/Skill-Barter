import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  /// ✅ AUTO CHAT ID (NO NEED TO PASS)
  String get chatId {
    return currentUserId.compareTo(widget.otherUserId) < 0
        ? "${currentUserId}_${widget.otherUserId}"
        : "${widget.otherUserId}_$currentUserId";
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// ✅ MARK AS READ
  Future<void> _markAsRead(List<Map<String, dynamic>> messages) async {
    final firestore = FirebaseFirestore.instance;

    for (final msg in messages) {
      if (msg['fromUserId'] != currentUserId && msg['id'] != null) {
        await firestore
            .collection("chats")
            .doc(chatId)
            .collection("messages")
            .doc(msg['id'])
            .update({"read": true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),

      body: Column(
        children: [
          /// ================= MESSAGES =================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().streamMessages(chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text("Start your conversation 👋"),
                  );
                }

                /// AUTO SCROLL + READ
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                  _markAsRead(messages);
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['fromUserId'] == currentUserId;

                    return _buildMessage(msg, isMe, isDark);
                  },
                );
              },
            ),
          ),

          /// ================= INPUT =================
          _buildInputBox(isDark),
        ],
      ),
    );
  }

  /// ================= MESSAGE =================
  Widget _buildMessage(
      Map<String, dynamic> msg, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blueAccent
              : (isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['timestamp']),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= INPUT =================
  Widget _buildInputBox(bool isDark) {
    final isEmpty = _controller.text.trim().isEmpty;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: isDark ? Colors.grey[900] : Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: isDark ? Colors.black : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isEmpty ? null : _sendMessage,
              child: CircleAvatar(
                backgroundColor:
                    isEmpty ? Colors.grey : Colors.blueAccent,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SEND =================
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirestoreService().sendMessage(
      chatId,
      currentUserId,
      text,
    );

    _controller.clear();
    _scrollToBottom();
  }

  /// ================= TIME =================
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      final date = timestamp.toDate();

      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
              ? 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? "PM" : "AM";

      return "$hour:$minute $ampm";
    } catch (_) {
      return "";
    }
  }
}