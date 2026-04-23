import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../achievements/achievements_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark background like screenshot
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              );
            },
          )
        ],
        
      ),
      body: Column(
  children: [
    const SizedBox(height: 10),

    /// 🔥 CENTER TITLE
    const Text(
      "Top Users",
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 10),

    /// 🔥 LEADERBOARD
    Expanded(
      child: _buildLeaderboard("users"),
    ),
  ],
),
    );
  }

  Widget _buildLeaderboard(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy("xp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No data yet",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final users = snapshot.data!.docs;

        // Find current user rank
        final myIndex = users.indexWhere((doc) => doc.id == currentUserId);
        final myRank = myIndex >= 0 ? myIndex + 1 : null;
        final myXp = myIndex >= 0
            ? (users[myIndex].data() as Map<String, dynamic>)['xp'] ?? 0
            : 0;

        return Column(
          children: [
            if (myRank != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Your Rank: #$myRank   XP: $myXp ★",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
              ),

            // 🏆 Podium for top 3
            _buildPodium(users),

            const Divider(color: Colors.white54),

            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final xp = data['xp'] ?? 0;
                  final name = data['name'] ?? "User";
                  final rank = index + 1;

                  final isCurrentUser = users[index].id == currentUserId;

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentUser
                            ? Colors.redAccent
                            : Colors.grey.shade700,
                        child: Text(
                          "#$rank",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.redAccent : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "XP: $xp",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: isCurrentUser
                          ? const Text(
                              "KEEP IT UP!",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // 🏆 Podium UI for Top 3 with medals
  // =========================================================
// =========================================================
// 🏆 Podium UI with gradient bases + glow effect
// =========================================================
Widget _buildPodium(List<QueryDocumentSnapshot> users) {
  final top3 = users.take(3).toList();

  if (top3.length < 3) {
    return const SizedBox(); // show nothing if less than 3 users
  }

  final first = top3[0].data() as Map<String, dynamic>;
  final second = top3[1].data() as Map<String, dynamic>;
  final third = top3[2].data() as Map<String, dynamic>;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // 🥈 Second place (left)
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: second['photoUrl'] != null
                  ? NetworkImage(second['photoUrl'])
                  : null,
              backgroundColor: Colors.grey,
              child: second['photoUrl'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.emoji_events, color: Colors.grey, size: 20),
            Text(second['name'] ?? "User",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 28),
            Text("${second['xp'] ?? 0} XP",
                style: const TextStyle(color: Colors.white70)),
            // Silver podium base with glow
            Container(
              height: 50,
              width: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.grey, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text("2",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),

      // 🥇 First place (center, tallest)
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: first['photoUrl'] != null
                  ? NetworkImage(first['photoUrl'])
                  : null,
              backgroundColor: Colors.amber,
              child: first['photoUrl'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
            Text(first['name'] ?? "User",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 22),
            Text("${first['xp'] ?? 0} XP",
                style: const TextStyle(color: Colors.white70)),
            // Gold podium base with glow
            Container(
              height: 70,
              width: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.yellow],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text("1",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),

      // 🥉 Third place (right, same level as 2nd)
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: third['photoUrl'] != null
                  ? NetworkImage(third['photoUrl'])
                  : null,
              backgroundColor: Colors.brown,
              child: third['photoUrl'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.emoji_events, color: Colors.brown, size: 20),
            Text(third['name'] ?? "User",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text("${third['xp'] ?? 0} XP",
                style: const TextStyle(color: Colors.white70)),
            // Bronze podium base with glow
            Container(
              height: 50, // same as #2
              width: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.brown, Colors.orange],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text("3",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ],
  );
}
    }