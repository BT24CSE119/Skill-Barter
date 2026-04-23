import 'package:flutter/material.dart';
import '../../core/utils/helpers.dart'; // 👈 for getLevel()

class ProfileHeader extends StatelessWidget {
  final String userName;
  final int credits;
  final int xp;
  final int streak; // 👈 new field
  final String? photoUrl;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.credits,
    required this.xp,
    required this.streak,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: photoUrl != null
              ? NetworkImage(photoUrl!)
              : const AssetImage("assets/profile.png") as ImageProvider,
        ),
        const SizedBox(height: 12),
        Text(
          userName.isNotEmpty ? "Welcome, $userName!" : "Welcome, User!",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text("Credits: $credits",
            style: const TextStyle(fontSize: 16, color: Colors.amber)),
        Text("XP: $xp",
            style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
        const SizedBox(height: 8),

        // 🔧 Level + Progress Bar
        Text("Level ${getLevel(xp)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (xp % 1000) / 1000, // progress to next level
          backgroundColor: Colors.grey[300],
          color: Colors.redAccent,
          minHeight: 6,
        ),
        const SizedBox(height: 8),

        // 🔧 Streak
        Text("Streak: $streak days",
            style: const TextStyle(fontSize: 16, color: Colors.green)),
      ],
    );
  }
}
