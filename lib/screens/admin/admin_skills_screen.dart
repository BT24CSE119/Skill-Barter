import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/skill_model.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSkillsScreen extends StatelessWidget {
  const AdminSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Skills")),

      body: StreamBuilder<List<SkillModel>>(
        stream: FirestoreService().streamSkills(),

        builder: (context, snapshot) {
          /// 🔥 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          /// ❌ NO DATA
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No skills found"));
          }

          /// 🔥 FILTER PENDING
          final skills = snapshot.data!
              .where((s) => s.status == "pending")
              .toList();

          if (skills.isEmpty) {
            return const Center(child: Text("No pending skills"));
          }

          return ListView.builder(
            itemCount: skills.length,

            itemBuilder: (context, index) {
              final skill = skills[index]; // ✅ SAFE

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,

                child: ListTile(
                  title: Text(
                    skill.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(skill.description),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// ✅ APPROVE
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),

                        onPressed: () async {
                          try {
                            await FirestoreService().updateSkill(
                              skill.copyWith(
                                status: "approved",
                                isVerified: true,
                              ),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Skill approved"),
                              ),
                            );
                          } catch (e) {
                            debugPrint("Approve error: $e");
                          }
                        },
                      ),

                      /// ❌ DELETE
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),

                        onPressed: () async {
                          print("CURRENT UID: ${FirebaseAuth.instance.currentUser!.uid}");
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Skill"),
                              content: const Text(
                                "This will permanently delete the skill. Continue?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          try {
                            /// 🔥 DELETE
                            await FirestoreService()
                                .deleteSkill(skill.id);

                            /// 🔥 USER PENALTY
                            final userRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(skill.ownerId);

                            await userRef.update({
                              'invalidSkillCount':
                                  FieldValue.increment(1),
                            });

                            final userDoc = await userRef.get();
                            final count =
                                userDoc.data()?['invalidSkillCount'] ?? 0;

                            if (count >= 3) {
                              await userRef.update({
                                'isBannedFromSkills': true,
                              });
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Skill deleted permanently"),
                              ),
                            );

                          } catch (e) {
  print("🔥 DELETE ERROR: $e"); // 👈 IMPORTANT

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())),
  );
}
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}