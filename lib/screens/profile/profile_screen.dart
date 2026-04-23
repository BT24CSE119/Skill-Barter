import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';
import '../chat/chat_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final isMyProfile = userId == null || userId == currentUserId;
    final targetUserId = isMyProfile ? currentUserId : userId!;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      appBar: AppBar(
        title: Text(isMyProfile ? "My Profile" : "User Profile"),
        centerTitle: true,
      ),

      body: StreamBuilder<UserModel?>(
        stream: FirestoreService().streamUserProfile(userId: targetUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 HEADER
                _buildHeader(context, user, isMyProfile),

                const SizedBox(height: 20),

                /// 🔥 ACTION BUTTONS
                if (!isMyProfile)
                  _buildActionButtons(context, currentUserId, user),

                if (!isMyProfile) const SizedBox(height: 20),

                /// 🔥 ABOUT
                _sectionHeader(context, "About"),
                _textBlock(context, user.bio ?? "No bio added"),

                /// 🔥 SKILLS
                _sectionHeader(context, "Skills Offered"),
                _buildChips(context, user.skillsOffered),

                const SizedBox(height: 10),

                _sectionHeader(context, "Skills Wanted"),
                _buildChips(context, user.skillsWanted),

                const SizedBox(height: 10),

                /// 🔥 NEW SOCIAL LINKS SECTION
                _sectionHeader(context, "Social Links"),
                _buildSocialLinks(context, user),

                const SizedBox(height: 20),

                /// 🔥 ONLY MY PROFILE EXTRA DATA
                if (isMyProfile) ...[
                  _sectionHeader(context, "Achievements"),
                  _buildChips(context, user.badges),

                  const SizedBox(height: 20),

                  _sectionHeader(context, "Wallet"),
                  _buildCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                    title: "Credits",
                    trailing: "${user.credits}",
                  ),

                  const SizedBox(height: 20),

                  _sectionHeader(context, "Statistics"),
Row(
  children: [
    _buildStatCard(
      context,
      title: "Sessions",
      value: user.sessionsCount ?? 0,
      icon: Icons.event,
      color: Colors.blue,
    ),
    _buildStatCard(
      context,
      title: "Exchanges",
      value: user.exchangesCount ?? 0,
      icon: Icons.swap_horiz,
      color: Colors.green,
    ),
  ],
),
                ],

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader(
      BuildContext context, UserModel user, bool isMyProfile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? Image.network(
                      user.photoUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 50),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          if (isMyProfile)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
            ),
        ],
      ),
    );
  }

  /// 🔥 SOCIAL LINKS UI
  Widget _buildSocialLinks(BuildContext context, UserModel user) {
    final links = [
      {"title": "LinkedIn", "value": user.linkedin, "icon": Icons.business},
      {"title": "GitHub", "value": user.github, "icon": Icons.code},
      {"title": "Instagram", "value": user.instagram, "icon": Icons.camera_alt},
    ];

    final validLinks =
        links.where((l) => l["value"] != null && l["value"] != "").toList();

    if (validLinks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text("No links added"),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: validLinks.map((link) {
          return Card(
            child: ListTile(
              leading: Icon(link["icon"] as IconData, color: Colors.blue),
              title: Text(link["title"] as String),
              subtitle: Text(link["value"] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= ACTION BUTTONS =================
  Widget _buildActionButtons(
      BuildContext context, String myId, UserModel user) {

    return StreamBuilder<String>(
      stream: FirestoreService().connectionStatusStream(myId, user.uid),
      builder: (context, snapshot) {
        final status = snapshot.data ?? "none";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Reject"),
            ),

            if (status == "accepted")
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

            if (status == "pending")
              ElevatedButton(
                onPressed: null,
                child: const Text("Pending"),
              ),

            if (status == "none")
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  await FirestoreService()
                      .sendConnectionRequest(myId, user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request Sent")),
                  );
                },
                child: const Text("Connect"),
              ),
          ],
        );
      },
    );
  }

  /// ================= HELPERS =================

Widget _sectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    ),
  );
}
Widget _buildChips(BuildContext context, List<String> items) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.blueAccent, Colors.purpleAccent]
                  : [Colors.blue, Colors.purple],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 8,
              )
            ],
          ),
          child: Text(
            e,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      String? trailing}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: trailing != null ? Text(trailing) : null,
      ),
    );
  }

 Widget _buildStatCard(
  BuildContext context, {
  required String title,
  required int value,
  required IconData icon,
  required Color color,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 10),

          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _textBlock(BuildContext context, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        /// 🔥 GRADIENT BACKGROUND
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blueGrey.shade900, Colors.black]
              : [Colors.blue.shade50, Colors.white],
        ),

        /// 🔥 BORDER
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),

        /// 🔥 SHADOW
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.black12,
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 TITLE ROW
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Bio",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔥 BIO TEXT
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );
}
}