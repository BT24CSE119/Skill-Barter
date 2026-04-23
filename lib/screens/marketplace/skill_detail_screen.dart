import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/skill_model.dart';
import '../discover/discover_screen.dart'; // ✅ IMPORTANT
import '../profile/profile_screen.dart';
class SkillDetailScreen extends StatelessWidget {
  final SkillModel skill;

  const SkillDetailScreen({super.key, required this.skill});

  /// 🔗 OPEN LINK
  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(skill.name),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🧠 TITLE
            Text(
              skill.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// 📂 CATEGORY
            Chip(
              label: Text(skill.category),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),

            const SizedBox(height: 20),

            /// 📘 DESCRIPTION
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(skill.description),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 👤 OWNER INFO
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text("Posted By"),
                subtitle: Text(skill.ownerId), // later replace with name
              ),
            ),

            const SizedBox(height: 20),

            /// 🔗 LEARNING LINK (if available)
            if (skill.resourceLink != null &&
                skill.resourceLink!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text("Learn More"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _openLink(skill.resourceLink),
                ),
              ),

            const SizedBox(height: 20),

            /// 🔥 VIEW PROFILE → DISCOVER SCREEN
            SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.person),
    label: const Text("View Profile"),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: skill.ownerId, // 🔥 DIRECT PROFILE
          ),
        ),
      );
    },
  ),
),
          ],
        ),
      ),
    );
  }
}