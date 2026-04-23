import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/language/language_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart'; // ✅ Using Cloudinary as per your earlier files
import '../../models/user_model.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  /// ================= LOGOUT =================
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await AuthService().logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  /// ================= EDIT PROFILE DIALOG =================
  void _showEditDialog(UserModel user) {
    _nameController.text = user.name;
    _bioController.text = user.bio ?? "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Basic Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "Bio"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                // ✅ FIXED: Using updateUserField from your service
                await _firestoreService.updateUserField(uid, "name", _nameController.text.trim());
                await _firestoreService.updateUserField(uid, "bio", _bioController.text.trim());
                
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile Updated")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// ================= CHANGE PHOTO =================
  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (picked != null && uid != null) {
      final file = File(picked.path);

      // ✅ FIXED: Using CloudinaryService to match your project setup
      final url = await CloudinaryService().uploadImage(file);

      if (url != null) {
        await _firestoreService.updateProfilePicture(uid, url);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Photo Updated")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) return const Scaffold(body: Center(child: Text("Logged out")));

    return Scaffold(
      appBar: AppBar(
      title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔥 PROFILE CARD
          StreamBuilder<UserModel?>(
            stream: _firestoreService.streamUserProfile(userId: userAuth.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData) return const Text("User data not found");

              final user = snap.data!;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (user.photoUrl ?? "").isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl ?? "").isEmpty 
                            ? const Icon(Icons.person, size: 40) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(user.email, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(user.bio ?? "No bio added", maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.green),
                            onPressed: _changePhoto,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          /// DARK MODE TOGGLE
          StreamBuilder<UserModel?>(
            stream: _firestoreService.streamUserProfile(userId: userAuth.uid),
            builder: (context, snap) {
              final user = snap.data;
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text("Dark Mode"),
                value: user?.darkMode ?? false,
                onChanged: (val) async {
                  await _firestoreService.updateUserField(userAuth.uid, "darkMode", val);
                  if (context.mounted) {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val);
                  }
                },
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy & Security"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help & Support"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SUPPORTING SCREENS =================

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete account?"),
        content: const Text(
          "This will permanently delete your profile data and sign you out.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final uid = user.uid;

      // Best-effort cleanup
      await FirebaseFirestore.instance.collection("users").doc(uid).delete();

      // Sign out first to clear local state
      await AuthService().logout();

      // Try to delete auth user (may require recent login; Google sign-in usually OK)
      await FirebaseAuth.instance.currentUser?.delete();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item['icon'], size: 20, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['text'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy & Security")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🔐 DATA PROTECTION
          _section("🔐 Data Protection", [
            {
              "icon": Icons.lock,
              "text": "Your personal data is securely stored using encryption.",
            },
            {
              "icon": Icons.security,
              "text": "We do not share your data with third parties without permission.",
            },
            {
              "icon": Icons.cloud_done,
              "text": "All sessions and chats are protected with secure cloud storage.",
            },
          ]),

          /// 🎓 STUDENT SAFETY
          _section("🎓 Student Safety", [
            {
              "icon": Icons.school,
              "text": "Only verified users can participate in skill sessions.",
            },
            {
              "icon": Icons.block,
              "text": "You can block or report any user for misuse.",
            },
            {
              "icon": Icons.warning,
              "text": "Avoid sharing personal details like phone numbers or passwords.",
            },
          ]),

          /// 💬 CHAT & SESSION SECURITY
          _section("💬 Chat & Session Security", [
            {
              "icon": Icons.video_call,
              "text": "Video calls are private and accessible only to participants.",
            },
            {
              "icon": Icons.chat,
              "text": "Chats are visible only to session participants.",
            },
            {
              "icon": Icons.history,
              "text": "Session history is stored securely for tracking learning.",
            },
          ]),

          /// 💰 PAYMENT / CREDITS
          _section("💰 Credits & Transactions", [
            {
              "icon": Icons.account_balance_wallet,
              "text": "Credits are safely managed and updated in real-time.",
            },
            {
              "icon": Icons.receipt,
              "text": "All transactions are recorded for transparency.",
            },
            {
              "icon": Icons.verified,
              "text": "No hidden charges or unauthorized deductions.",
            },
          ]),

          /// 🛡 USER CONTROL
          _section("🛡 Your Control", [
            {
              "icon": Icons.settings,
              "text": "You can update or delete your profile anytime.",
            },
            {
              "icon": Icons.visibility_off,
              "text": "Control your visibility and online status.",
            },
            {
              "icon": Icons.logout,
              "text": "Logging out ensures your account safety on shared devices.",
            },
          ]),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Permanently delete your profile and sign out."),
            onTap: () => _deleteAccount(context),
          ),

          const SizedBox(height: 10),

          /// 🔥 FOOTER NOTE
          const Center(
            child: Text(
              "We are committed to keeping your learning safe and secure 🚀",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Language")),
      body: Column(
        children: [

          RadioListTile(
            title: const Text("English"),
            value: "en",
            groupValue: langProvider.locale.languageCode,
            onChanged: (val) {
              langProvider.changeLanguage(val!);
            },
          ),

          RadioListTile(
            title: const Text("Hindi"),
            value: "hi",
            groupValue: langProvider.locale.languageCode,
            onChanged: (val) {
              langProvider.changeLanguage(val!);
            },
          ),
        ],
      ),
    );
  }
}



class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item['icon'], color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['text'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🚀 HOW TO USE APP
          _section("🚀 Getting Started", [
            {
              "icon": Icons.person,
              "text": "Create your profile and add your skills.",
            },
            {
              "icon": Icons.search,
              "text": "Explore other users and their skills.",
            },
            {
              "icon": Icons.handshake,
              "text": "Send session requests to connect and learn.",
            },
            {
              "icon": Icons.video_call,
              "text": "Join video sessions and start learning.",
            },
          ]),

          /// 📚 SESSION GUIDE
          _section("📚 Sessions Guide", [
            {
              "icon": Icons.schedule,
              "text": "Sessions are scheduled for a minimum of 1 hour.",
            },
            {
              "icon": Icons.swap_horiz,
              "text": "You can either exchange skills or use credits.",
            },
            {
              "icon": Icons.check_circle,
              "text": "Mark session as completed after finishing.",
            },
          ]),

          /// 💰 CREDITS SYSTEM
          _section("💰 Credits System", [
            {
              "icon": Icons.account_balance_wallet,
              "text": "Earn credits by teaching others.",
            },
            {
              "icon": Icons.payment,
              "text": "Spend credits to learn from others.",
            },
            {
              "icon": Icons.warning,
              "text": "Missing sessions may result in credit deduction.",
            },
          ]),

          /// ⚠️ COMMON ISSUES
          _section("⚠️ Common Issues", [
            {
              "icon": Icons.error,
              "text": "If video call doesn't start, check internet connection.",
            },
            {
              "icon": Icons.notifications,
              "text": "Enable notifications to receive session updates.",
            },
            {
              "icon": Icons.account_circle,
              "text": "Make sure your profile is complete for better matching.",
            },
          ]),

          /// 📞 CONTACT SUPPORT
          _section("📞 Contact Support", [
            {
              "icon": Icons.email,
              "text": "Email: support@skillbarter.com",
            },
            {
              "icon": Icons.bug_report,
              "text": "Report bugs from inside the app.",
            },
            {
              "icon": Icons.feedback,
              "text": "Send feedback to improve the platform.",
            },
          ]),

          const SizedBox(height: 20),

          /// 🔥 FOOTER
          const Center(
            child: Text(
              "We’re here to help you learn better 🚀",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About SkillBarter"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🌟 APP INTRO
          _section(
            "🌟 What is SkillBarter?",
            "SkillBarter is a peer-to-peer learning platform where users can exchange skills instead of money. "
            "You can teach what you know and learn what you want — making learning accessible, flexible, and collaborative.",
          ),

          /// 🎯 MISSION
          _section(
            "🎯 Our Mission",
            "Our mission is to empower students and individuals to learn and grow without financial barriers. "
            "We aim to create a community where knowledge is shared freely and everyone benefits.",
          ),

          /// ⚙️ FEATURES
          Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "⚙️ Key Features",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _featureItem(Icons.swap_horiz, "Skill exchange between users"),
                  _featureItem(Icons.video_call, "Real-time video learning sessions"),
                  _featureItem(Icons.account_balance_wallet, "Credit-based learning system"),
                  _featureItem(Icons.chat, "In-app chat and communication"),
                  _featureItem(Icons.star, "Feedback and rating system"),
                ],
              ),
            ),
          ),

          /// 🔐 PRIVACY & SAFETY
          _section(
            "🔐 Privacy & Safety",
            "We prioritize user safety and data privacy. Your personal information is protected, and sessions are monitored "
            "to ensure a safe and respectful learning environment.",
          ),

          /// 👨‍🎓 WHO CAN USE
          _section(
            "👨‍🎓 Who Can Use SkillBarter?",
            "SkillBarter is designed for students, professionals, and anyone who wants to learn or teach skills. "
            "Whether you're a beginner or an expert, there's always something to gain.",
          ),

          /// 📈 FUTURE VISION
          _section(
            "📈 Future Vision",
            "We aim to expand SkillBarter into a global learning platform with advanced features like AI recommendations, "
            "certifications, and community-driven learning paths.",
          ),

          /// 🏷 VERSION
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),

          /// 🚀 FOOTER
          const Center(
            child: Text(
              "Learn. Share. Grow 🚀",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}