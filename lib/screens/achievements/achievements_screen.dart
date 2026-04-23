import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../core/utils/helpers.dart'; // 👈 for getLevel()

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Achievements"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.streamUserProfile(userId: currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;
          final badges = user.badges;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🔧 Level, XP, Streak Section
              Text(
                "Level ${getLevel(user.xp)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (user.xp % 1000) / 1000, // progress to next level
                backgroundColor: Colors.grey[300],
                color: Colors.redAccent,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text("XP: ${user.xp}"),
              Text("Streak: ${user.streak} days"),
              const SizedBox(height: 24),

              const Divider(),

              // 🔧 Badges Section
              const Text(
                "Badges",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (badges.isEmpty)
                const Center(
                  child: Text(
                    "No badges unlocked yet.\nKeep earning XP to unlock achievements!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    return Card(
                      color: Colors.redAccent.withOpacity(0.1),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.redAccent, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              badge,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}