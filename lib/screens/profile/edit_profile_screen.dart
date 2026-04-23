import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final skillsOfferedController = TextEditingController();
  final skillsWantedController = TextEditingController();

  /// 🔗 SOCIAL
  final linkedinController = TextEditingController();
  final githubController = TextEditingController();
  final instagramController = TextEditingController();

  UserModel? currentUser;
  File? imageFile;
  bool isLoading = false;
  static const int _bioMax = 500;
  static const int _skillsMax = 5;
  List<String> _offered = [];
  List<String> _wanted = [];

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  /// ================= LOAD USER =================
  void _initUserData() {
    if (_currentUid.isEmpty) return;

    _firestoreService.streamUserProfile(userId: _currentUid).first.then((user) {
      if (user != null && mounted) {
        setState(() {
          currentUser = user;

          nameController.text = user.name;
          bioController.text = user.bio ?? "";
          _offered = List<String>.from(user.skillsOffered);
          _wanted = List<String>.from(user.skillsWanted);
          skillsOfferedController.text = _offered.join(", ");
          skillsWantedController.text = _wanted.join(", ");

          linkedinController.text = user.linkedin ?? "";
          githubController.text = user.github ?? "";
          instagramController.text = user.instagram ?? "";
        });
      }
    });
  }

  /// ================= PICK IMAGE =================
  Future<void> pickImage() async {
    // Best-effort permissions (Android 13+ uses photos, older uses storage).
    try {
      await Permission.photos.request();
      await Permission.storage.request();
    } catch (_) {}

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  /// ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    setState(() => isLoading = true);

    try {
      String? imageUrl = currentUser!.photoUrl;

      /// 🔥 IMAGE UPLOAD
      if (imageFile != null) {
        imageUrl = await CloudinaryService().uploadImage(imageFile!);
      }

      /// 🔥 SKILLS
      final offered = _offered;
      final wanted = _wanted;

      /// 🔥 SINGLE FIRESTORE UPDATE (BEST)
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUid)
          .update({
        "name": nameController.text.trim(),
        "bio": bioController.text.trim().substring(
              0,
              bioController.text.trim().length.clamp(0, _bioMax),
            ),
        "skillsOffered": offered,
        "skillsWanted": wanted,
        "linkedin": linkedinController.text.trim(),
        "github": githubController.text.trim(),
        "instagram": instagramController.text.trim(),
        "photoUrl": imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile Updated Successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<List<String>> _loadSkillNames() async {
    final snap = await FirebaseFirestore.instance.collection("skills").get();
    final names = <String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final title = (data['title'] ?? data['skillName'] ?? data['name'])?.toString();
      if (title != null && title.trim().isNotEmpty) names.add(title.trim());
    }
    final list = names.toList()..sort();
    // Fallback list if DB empty
    if (list.isEmpty) {
      return const [
        "Flutter",
        "Dart",
        "UI/UX",
        "Firebase",
        "Python",
        "Java",
        "C++",
        "Data Structures",
        "Web Development",
        "Public Speaking",
      ];
    }
    return list;
  }

  Future<void> _pickSkills({
    required String title,
    required List<String> initial,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final all = await _loadSkillNames();
    final selected = initial.toSet();

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Select up to $_skillsMax", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: all.map((skill) {
                        final isOn = selected.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isOn,
                          onSelected: (v) {
                            setStateSheet(() {
                              if (v) {
                                if (selected.length >= _skillsMax) return;
                                selected.add(skill);
                              } else {
                                selected.remove(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onChanged(selected.toList()..sort());
                          Navigator.pop(context);
                        },
                        child: const Text("Done"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _skillsField({
    required String label,
    required List<String> values,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: values.isEmpty
            ? const Text("Select skills", style: TextStyle(color: Colors.grey))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values.map((s) => Chip(label: Text(s))).toList(),
              ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading || currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// 🔥 PROFILE IMAGE
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: imageFile != null
                                ? Image.file(imageFile!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover)
                                : (currentUser!.photoUrl != null &&
                                        currentUser!.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        currentUser!.photoUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person,
                                        size: 60, color: Colors.grey)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                              onPressed: pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// 🔤 NAME
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration("Full Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 15),

                    /// 📝 BIO
                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      maxLength: _bioMax,
                      decoration: _inputDecoration("Short Bio").copyWith(
                        helperText: "${bioController.text.length}/$_bioMax",
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 15),

                    /// 🧠 SKILLS
                    _skillsField(
                      label: "Skills Offered",
                      values: _offered,
                      onTap: () => _pickSkills(
                        title: "Skills Offered",
                        initial: _offered,
                        onChanged: (v) => setState(() {
                          _offered = v;
                          skillsOfferedController.text = _offered.join(", ");
                        }),
                      ),
                    ),

                    const SizedBox(height: 15),

                    _skillsField(
                      label: "Skills Wanted",
                      values: _wanted,
                      onTap: () => _pickSkills(
                        title: "Skills Wanted",
                        initial: _wanted,
                        onChanged: (v) => setState(() {
                          _wanted = v;
                          skillsWantedController.text = _wanted.join(", ");
                        }),
                      ),
                    ),

                    const Divider(height: 40),

                    /// 🔗 SOCIAL
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Social Links",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: linkedinController,
                      decoration:
                          _inputDecoration("LinkedIn Profile URL"),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: githubController,
                      decoration:
                          _inputDecoration("GitHub Profile URL"),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: instagramController,
                      decoration:
                          _inputDecoration("Instagram Profile URL"),
                    ),

                    const SizedBox(height: 30),

                    /// 💾 SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: saveProfile,
                        child: const Text("Save Changes",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= INPUT STYLE =================
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}