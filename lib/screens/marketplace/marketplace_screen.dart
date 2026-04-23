import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/skill_model.dart';
import '../../core/widgets/skill_card.dart';
import '../../services/firestore_service.dart';
import 'add_skill_screen.dart';
import 'skill_detail_screen.dart'; // ✅ IMPORTANT

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = "All";
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  void _editSkill(SkillModel skill) {
    final nameController = TextEditingController(text: skill.name);
    final descriptionController = TextEditingController(text: skill.description);
    String category = skill.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Skill"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Skill Name"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      items: ["General", "Programming", "Design", "Business", "Creative", "Lifestyle"]
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => category = value!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedSkill = skill.copyWith(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: category,
                    );

                    await FirestoreService().updateSkill(updatedSkill);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Skill updated successfully")),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSkill(String skillId) async {
    await FirestoreService().deleteSkill(skillId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Skill deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Skill Marketplace"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          /// 🔽 CATEGORY FILTER
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Filter by Category",
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: ["All", "Programming", "Design", "Business", "Creative", "Lifestyle", "General"]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ),

          /// 🔥 SKILLS LIST
          Expanded(
            child: StreamBuilder<List<SkillModel>>(
              stream: FirestoreService().streamSkills().map(
                    (skills) => skills.where((s) => s.status == "approved").toList(),
                  ),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        Text("Error: ${snapshot.error}"),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No skills available yet."));
                }

                final skills = snapshot.data!;
                final filteredSkills = _selectedCategory == "All"
                    ? skills
                    : skills.where((s) => s.category == _selectedCategory).toList();

                if (filteredSkills.isEmpty) {
                  return const Center(child: Text("No skills found in this category."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredSkills.length,
                  itemBuilder: (context, index) {
                    final skill = filteredSkills[index];

                    /// 🔥 FIX: CLICK NAVIGATION ADDED HERE
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkillDetailScreen(skill: skill),
                          ),
                        );
                      },

                      child: SkillCard(
                        skill: skill,
                        onEdit: skill.ownerId == currentUserId
                            ? () => _editSkill(skill)
                            : null,
                        onDelete: skill.ownerId == currentUserId
                            ? () => _deleteSkill(skill.id)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSkillScreen()),
          );
        },
      ),
    );
  }
}