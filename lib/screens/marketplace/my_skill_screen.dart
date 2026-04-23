import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/skill_model.dart';
import '../../core/widgets/skill_card.dart';
import '../../services/firestore_service.dart';
import 'add_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  // 🔥 FIXED: Safe getter to prevent initialization crashes
String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  void _editSkill(SkillModel skill) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: skill.name);
        final descriptionController = TextEditingController(text: skill.description);
        String category = skill.category;

        return AlertDialog(
          title: const Text("Edit Skill"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: category,
                  items: ["General","Programming","Design","Business","Creative","Lifestyle"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                // 🔥 FIXED: Using copyWith preserves the ID and the createdAt date!
final updatedSkill = skill.copyWith(
  name: nameController.text.trim(),
  description: descriptionController.text.trim(),
  category: category,
);
                await FirestoreService().updateSkill(updatedSkill);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Skill updated successfully")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteSkill(String skillId) async {
    await FirestoreService().deleteSkill(skillId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Skill deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Skills"),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: StreamBuilder<List<SkillModel>>(
        stream: FirestoreService().streamSkills(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading skills"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No skills found"));
          }

          final skills = snapshot.data!
              .where((s) => s.ownerId == currentUserId) // ✅ only my skills
              .toList();

          if (skills.isEmpty) {
            return const Center(child: Text("You haven't added any skills yet"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editSkill(skill);
                            },
                            icon: const Icon(Icons.edit, size: 28),
                            label: const Text("Edit Skill", style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteSkill(skill.id);
                            },
                            icon: const Icon(Icons.delete, size: 28),
                            label: const Text("Delete Skill", style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: SkillCard(skill: skill),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSkillScreen()),
          );
        },
      ),
    );
  }
}