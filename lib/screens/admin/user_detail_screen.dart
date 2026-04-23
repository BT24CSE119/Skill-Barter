import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          /// ⏳ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ ERROR / NO DATA
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text("User not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 👤 PROFILE CARD
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        /// 👤 AVATAR
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// 🧑 NAME
                        Text(
                          data['name'] ?? "No Name",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        /// 📧 EMAIL
                        Text(
                          data['email'] ?? "No Email",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 10),

                        /// 👑 ROLE BADGE
                        Chip(
                          label: Text(data['role'] ?? "user"),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 💰 WALLET SECTION
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text("Wallet Balance"),
                    trailing: Text(
                      "${data['walletBalance'] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 📊 STATS SECTION
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text("Sessions"),
                        trailing: Text("${data['sessionsCount'] ?? 0}"),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: const Text("XP"),
                        trailing: Text("${data['xp'] ?? 0}"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}