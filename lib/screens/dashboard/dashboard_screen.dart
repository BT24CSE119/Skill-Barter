import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../sessions/session_room_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

import '../sessions/sessions_screen.dart';
import '../wallet/wallet_screen.dart';
import '../notifications/notifications_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../settings/settings_screen.dart' hide HelpScreen;
import '../feedback/feedback_screen.dart';
import '../profile/profile_screen.dart';
import '../discover/discover_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../help/help_screen.dart';
import '../calling/calling_screen.dart';

/// =============================================================
/// DASHBOARD SCREEN
/// =============================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false; // prevent repeat
  bool _isCallScreenOpen = false; // prevent duplicate pushes
  bool _isSessionDialogOpen = false;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _screens = const [
    DashboardHome(),
    SessionsScreen(),
    WalletScreen(),
    LeaderboardScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  /// Mark all notifications as read
  Future<void> _markAllNotificationsRead(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: uid)
        .where("read", isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"read": true});
    }
    await batch.commit();
  }
@override
Widget build(BuildContext context) {
  final userId = uid;

  if (userId == null) {
    return const Scaffold(
      body: Center(child: Text("User not logged in")),
    );
  }

  return Scaffold(
    body: Stack(
      children: [
        _screens[_selectedIndex],

        /// ================= CALL LISTENER =================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('calls')
              .where('receiverId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            for (var doc in snapshot.data!.docs) {
            final raw = doc.data();

if (raw == null) return Container(); // ✅ SAFE

final data = raw as Map<String, dynamic>;
              final status = data['status'];
              final callId = doc.id;
              final sessionId = (data['sessionId'] as String?) ?? callId;

              /// 📞 INCOMING CALL
              if (status == "calling" && !_isRinging && !_isCallScreenOpen) {
                _isRinging = true;
                _isCallScreenOpen = true;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    await _player.setReleaseMode(ReleaseMode.loop);
                    await _player.play(AssetSource('ringtone.mp3'));
                    Vibration.vibrate(duration: 1000);
                  } catch (_) {}

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallingScreen(
  callId: callId,
  sessionId: sessionId,
  isCaller: false,
),
                    ),
                  ).then((_) {
                    _isCallScreenOpen = false;
                  });
                });

                break;
              }

              /// ✅ CALL ACCEPTED
              if (status == "accepted") {
                _isRinging = false;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    await _player.stop();
                  } catch (_) {}
                });

                break;
              }

              /// ❌ CALL ENDED
              if (status == "ended" ||
                  status == "rejected" ||
                  status == "cancelled") {
                _isRinging = false;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    await _player.stop();
                  } catch (_) {}

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                });

                break;
              }
            }

            return const SizedBox();
          },
        ),

        /// ================= 🔥 SESSION REQUEST LISTENER =================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessionRequests')
              .where('toUserId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            final request = snapshot.data!.docs.first;
            final data = request.data() as Map<String, dynamic>;

            final sessionId = data['sessionId'];
            final fromUserId = data['fromUserId'];

            /// 🔥 PREVENT MULTIPLE POPUPS
            if (_isSessionDialogOpen) return const SizedBox();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _isSessionDialogOpen = true;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text("Session Request"),
                  content: const Text(
                      "Someone wants to start a session with you"),
                  actions: [

                    /// ❌ REJECT
                    TextButton(
                      onPressed: () async {
                        await request.reference
                            .update({"status": "rejected"});

                        _isSessionDialogOpen = false;
                        Navigator.pop(context);
                      },
                      child: const Text("Reject"),
                    ),

                    /// ✅ ACCEPT
                    ElevatedButton(
                      onPressed: () async {

                        /// UPDATE SESSION
                        await FirebaseFirestore.instance
                            .collection("sessions")
                            .doc(sessionId)
                            .update({
                          "participants":
                              FieldValue.arrayUnion([userId]),
                          "status": "ongoing",
                          "startTime":
                              FieldValue.serverTimestamp(),
                        });

                        /// UPDATE REQUEST
                        await request.reference
                            .update({"status": "accepted"});

                        _isSessionDialogOpen = false;
                        Navigator.pop(context);

                        /// 🔥 OPEN SESSION ROOM
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionRoomScreen(
                              sessionId: sessionId,
                              otherUserId: fromUserId,
                            ),
                          ),
                        );
                      },
                      child: const Text("Accept"),
                    ),
                  ],
                ),
              );
            });

            return const SizedBox();
          },
        ),
      ],
    ),

    /// ================= BOTTOM NAV =================
    bottomNavigationBar: StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().streamNotifications(userId),
      builder: (context, snapshot) {
        int unread = 0;

        if (snapshot.hasData) {
          unread = snapshot.data!.docs.where((doc) {
          final raw = doc.data();

if (raw == null) return false;  // ✅ SAFE

final data = raw as Map<String, dynamic>;
            return data["read"] == false;
          }).length;
        }

        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.black87,
          onTap: (index) async {
            setState(() => _selectedIndex = index);
            if (index == 4) {
              await _markAllNotificationsRead(userId);
            }
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: "Home"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: "Sessions"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: "Wallet"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: "Leaderboard"),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unread > 9 ? "9+" : "$unread",
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              label: "Notifications",
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings"),
          ],
        );
      },
    ),
  );
}
}

/// =============================================================
/// DASHBOARD HOME
/// =============================================================
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService().streamUserProfile(userId: uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("User not found"));
          }

          return Column(
            children: [
              /// 🔷 HEADER
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor: Colors.white24,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Welcome, ${user.name}!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Credits: ${user.credits}",
                        style: const TextStyle(
                            color: Colors.yellowAccent, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Level ${user.level}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                                            LinearProgressIndicator(
                        value: (user.xp % 100) / 100,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                Colors.orangeAccent),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Streak: ${user.streak} days 🔥",
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔶 GRID OF FEATURES
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _advancedCard(context, "Profile", Icons.person,
                          Colors.teal, const ProfileScreen()),
                      _advancedCard(context, "Discover", Icons.search,
                          Colors.indigo, const DiscoverScreen()),
                      _advancedCard(
                          context,
                          "Marketplace",
                          Icons.shopping_bag,
                          Colors.deepOrange,
                          const MarketplaceScreen()),
                      _advancedCard(context, "Sessions", Icons.schedule,
                          Colors.blueAccent, const SessionsScreen()),
                      _advancedCard(
                          context,
                          "Wallet",
                          Icons.account_balance_wallet,
                          Colors.green,
                          const WalletScreen()),
                      _advancedCard(
                          context,
                          "Notifications",
                          Icons.notifications,
                          Colors.orange,
                          const NotificationsScreen()),
                      _advancedCard(
                          context,
                          "Leaderboard",
                          Icons.emoji_events,
                          Colors.blue,
                          const LeaderboardScreen()),
                      _advancedCard(
                          context,
                          "Feedback",
                          Icons.feedback,
                          Colors.purple,
                          const FeedbackScreen(sessionId: "general")),
                      _advancedCard(context, "Help & Safety", Icons.security,
                          Colors.red, HelpScreen()),
                      _advancedCard(context, "Settings", Icons.settings,
                          Colors.grey, const SettingsScreen()),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ✅ SINGLE CLEAN CARD FUNCTION
  Widget _advancedCard(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 28,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
