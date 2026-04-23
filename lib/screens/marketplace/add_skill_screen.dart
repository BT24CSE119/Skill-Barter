import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/skill_model.dart';
import '../../services/firestore_service.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController(); // ✅ LINK

  String _selectedCategory = "General";
  bool _isSaving = false;

  final List<String> _categories = [
    "General",
    "Programming",
    "Design",
    "Business",
    "Creative",
    "Lifestyle",
  ];

  /// 🔥 SAVE SKILL
  Future<void> _saveSkill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please login first");

      /// 🔥 BAN CHECK
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      if (userData?['isBannedFromSkills'] == true) {
        throw Exception("🚫 You are banned from adding skills");
      }

      /// 🔥 CLEAN INPUT
      final name = _nameController.text.trim();
      final desc = _descriptionController.text.trim();
      final link = _linkController.text.trim(); // ✅ GET LINK

      /// 🔥 VALIDATION
      if (name.length < 3) {
        throw Exception("Skill name too short");
      }

      if (desc.length < 5) {
        throw Exception("Description too short");
      }

      /// 🔥 CATEGORY FIX
      final category = _categories.contains(_selectedCategory)
          ? _selectedCategory
          : "General";

      /// 🔥 CREATE MODEL (UPDATED)
      final skill = SkillModel(
        id: "",
        name: name,
        description: desc,
        category: category,
        ownerId: user.uid,
        createdAt: DateTime.now(),
        status: "pending",
        isVerified: false,
        resourceLink: link.isEmpty ? null : link, // ✅ IMPORTANT
      );

      /// 🔥 SAVE
      await FirestoreService().addSkill(skill);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Skill sent for verification"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose(); // ✅ FIX MEMORY
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Skill"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Skill Details",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// 🔤 NAME
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Skill Name",
                  hintText: "e.g. Flutter Development",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.psychology),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter skill name";
                  }
                  if (value.trim().length < 3) {
                    return "Minimum 3 characters required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// 📝 DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Describe what you can teach...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter description";
                  }
                  if (value.trim().length < 5) {
                    return "Minimum 5 characters required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// 🔗 LEARNING LINK (NEW FEATURE)
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: "Learning Link (optional)",
                  hintText: "https://youtube.com/...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),

              const SizedBox(height: 20),

              /// 📂 CATEGORY
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 30),

              /// 🚀 BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSkill,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isSaving ? "Saving..." : "Save Skill"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}