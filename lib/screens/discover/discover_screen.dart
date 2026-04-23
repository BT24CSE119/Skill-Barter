import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import 'recommendation_engine.dart';
import '../calling/calling_screen.dart';
import 'dart:async';
class DiscoverScreen extends StatefulWidget {
  
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final FirestoreService _firestore = FirestoreService();
  final PageController _pageController = PageController();

  String _nameQuery = "";
  String _skillOfferedQuery = "";
  String _skillWantedQuery = "";

  bool _isProcessing = false;
  bool _showSearch = false;
  bool _isCallActive = false;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// ================= SEND REQUEST =================
  Future<void> _handleLikeAction(UserModel targetUser) async {
    if (currentUid == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _firestore.sendConnectionRequest(
        currentUid!,
        targetUser.uid,
      );
      _showFeedback("Request Sent ❤️", Colors.green);
    } catch (e) {
      _showFeedback("Error sending request", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  @override
void initState() {
  super.initState();
  listenForIncomingCalls();
}

StreamSubscription? _callSubscription;

void listenForIncomingCalls() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  _callSubscription?.cancel();

  _callSubscription = FirebaseFirestore.instance
      .collection('calls')
      .where('receiverId', isEqualTo: uid)
      .snapshots()
      .listen((snapshot) {

    if (snapshot.docs.isEmpty) return;

    final doc = snapshot.docs.first;
    final data = doc.data();

    if (data['status'] == 'calling' && !_isCallActive) {
      _isCallActive = true;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Incoming Call"),
          content: Text("${data['callerName']} is calling..."),
          actions: [

            /// ❌ REJECT BUTTON
            TextButton(
              onPressed: () async {
                await doc.reference.update({'status': 'rejected'});
                Navigator.pop(context);
                _isCallActive = false;
              },
              child: const Text("Reject"),
            ),

            /// ✅ ACCEPT BUTTON (FULL FIX)
            TextButton(
              onPressed: () async {
                await doc.reference.update({'status': 'accepted'});

                /// 🔥 ADD RECEIVER TO SESSION
                await FirebaseFirestore.instance
                    .collection("sessions")
                    .doc(data['sessionId'])
                    .update({
                  "participants": FieldValue.arrayUnion([uid])
                });

                Navigator.pop(context);

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallingScreen(
                      callId: doc.id,
                      sessionId: data['sessionId'],
                      isCaller: false,
                    ),
                  ),
                ).then((_) {
                  _isCallActive = false;
                });
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    }
  });
}
  /// ================= ACCEPT REQUEST =================
Future<void> _acceptRequest(String otherUserId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection("connectionRequests")
        .where("fromUserId", isEqualTo: otherUserId)
        .where("toUserId", isEqualTo: currentUid)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        "status": "accepted",
      });
    }

    _showFeedback("Accepted ✅", Colors.green);
  } catch (e) {
    debugPrint("Accept error: $e");
  }
}

  String getChannelName(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0
        ? "channel_${uid1}_$uid2"
        : "channel_${uid2}_$uid1";
  }

  /// ================= VIDEO CALL =================
Future<void> _handleVideoCallAction(UserModel targetUser) async {  if (currentUid == null) return;

  final callId = getChannelName(currentUid!, targetUser.uid);
  final currentUser = FirebaseAuth.instance.currentUser;

  print("CALL INIT START");

  try {
    /// 🔥 CREATE SESSION
    final sessionRef =
        FirebaseFirestore.instance.collection("sessions").doc();

    await sessionRef.set({
      "hostId": currentUid,
      "targetUserId": targetUser.uid,
      "participants": [currentUid],
      "status": "calling",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final sessionId = sessionRef.id;

    print("SESSION CREATED: $sessionId");

    /// 🔥 CREATE CALL DOC
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .set({
      'callerId': currentUid,
      'callerName': currentUser?.displayName ?? "User",
      'receiverId': targetUser.uid,
      'sessionId': sessionId,
      'status': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("CALL DOC CREATED");

    /// 🔥 LISTEN FOR RESPONSE
    StreamSubscription? sub;

    sub = FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((doc) {

      if (!doc.exists) return;

      final data = doc.data()!;
      print("CALL STATUS: ${data['status']}");

      /// ✅ ACCEPTED
      if (data['status'] == 'accepted') {
        print("CALL ACCEPTED");

        sub?.cancel();

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              callId: callId,
              sessionId: sessionId,
              isCaller: true,
            ),
          ),
        );
      }

      /// ❌ REJECTED
      if (data['status'] == 'rejected') {
        print("CALL REJECTED");

        sub?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Call Rejected ❌")),
        );
      }
    });

    /// ⏳ AUTO TIMEOUT
    Future.delayed(const Duration(seconds: 30), () async {
      final doc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .get();

      if (doc.exists && doc['status'] == 'calling') {
        print("CALL MISSED");

        await doc.reference.update({'status': 'missed'});
        sub?.cancel();
      }
    });

  } catch (e) {
    print("CALL ERROR: $e");
  }
}
@override
void dispose() {
  _pageController.dispose();
  _callSubscription?.cancel(); // ✅ prevent memory leak
  super.dispose();
}

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUid == null) {
      return const Scaffold(
        body: Center(child: Text("Please Login")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Discover"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () => setState(() => _showSearch = !_showSearch),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      _showSearch ? "Hide Search" : "Search Users...",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildSearchBar(),
            ),

          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _firestore.streamUserProfile(userId: currentUid!),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUser = userSnap.data!;

                return StreamBuilder<List<UserModel>>(
                  stream: _firestore.streamAllProfiles(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!
                        .where((u) {
                          if (u.uid == currentUid) return false;

                          final nameMatch = u.name
                              .toLowerCase()
                              .contains(_nameQuery.toLowerCase());

                          final offeredMatch = u.skillsOffered
                              .join(",")
                              .toLowerCase()
                              .contains(_skillOfferedQuery.toLowerCase());

                          final wantedMatch = u.skillsWanted
                              .join(",")
                              .toLowerCase()
                              .contains(_skillWantedQuery.toLowerCase());

                          return nameMatch &&
                              offeredMatch &&
                              wantedMatch;
                        })
                        .toList()
                      ..shuffle();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Users Found",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return _buildCard(users[index], currentUser);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CARD =================
  Widget _buildCard(UserModel user, UserModel currentUser) {
    final matchPercent =
        RecommendationEngine.calculateMatchPercentage(currentUser, user);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                  : Container(
  color: Colors.black54,
  child: const Icon(Icons.person, size: 60, color: Colors.white),
)
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${matchPercent.toInt()}% Match",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        user.isVerified == true
                            ? Icons.verified
                            : Icons.verified_outlined,
                        color: user.isVerified == true
                            ? Colors.blue
                            : Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: StreamBuilder<String>(
                          stream: _firestore.connectionStatusStream(
                            currentUid!,
                            user.uid,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }

                            final status = snapshot.data!;

                            if (status == "none") {
                              return ElevatedButton(
                                style: _btnStyle(),
                                onPressed: _isProcessing
                                    ? null
                                    : () => _handleLikeAction(user),
                                child: const Text("Connect"),
                              );
                            }

                            if (status == "pending") {
                              return ElevatedButton(
                                style: _btnStyle(),
                                onPressed: null,
                                child: const Text("Pending"),
                              );
                            }

                            if (status == "incoming") {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
  style: _btnStyle(color: Colors.green),
 onPressed: () => _acceptRequest(user.uid), // ✅ FIXED
  child: const Text("Accept"),
),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style:
                                          _btnStyle(color: Colors.red),
                                      onPressed: () async {
                                        await _firestore
                                            .rejectConnectionRequest(
                                                user.uid);
                                        _showFeedback(
                                            "Rejected ❌", Colors.red);
                                      },
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (status == "accepted") {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style:
                                          _btnStyle(color: Colors.orange),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              otherUserId: user.uid,
                                              otherUserName: user.name,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Chat"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                Expanded(
  child: Container(
    color: Colors.transparent,
    child: ElevatedButton.icon(
      style: _btnStyle(color: Colors.purple),
      onPressed: () async {
        print("CALL BUTTON CLICKED");

        if (_isProcessing) return;

        setState(() => _isProcessing = true);

        await _handleVideoCallAction(user);

        setState(() => _isProcessing = false);
      },
      icon: const Icon(Icons.video_call, size: 18),
      label: const Text("Call"),
    ),
  ),
),
                                ],
                              );
                            }

                            return const SizedBox();
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: _btnStyle(color: Colors.white24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileScreen(userId: user.uid),
                              ),
                            );
                          },
                          child: const Text("View Profile"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        _buildField("Search Name...", (v) => _nameQuery = v),
        const SizedBox(height: 8),
        _buildField("Skill Offered...", (v) => _skillOfferedQuery = v),
        const SizedBox(height: 8),
        _buildField("Skill Wanted...", (v) => _skillWantedQuery = v),
      ],
    );
  }

  Widget _buildField(String hint, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        onChanged: (v) => setState(() => onChanged(v)),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }

  ButtonStyle _btnStyle({Color? color}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color ?? Colors.white.withOpacity(0.15),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}