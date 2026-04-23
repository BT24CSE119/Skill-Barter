import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _reportController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reportController.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please describe your issue before submitting."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";

      // Adding the report to Firestore
      final docRef = await FirebaseFirestore.instance.collection("reports").add({
  "userId": uid,
  "message": _reportController.text.trim(),
  "timestamp": FieldValue.serverTimestamp(),
  "status": "pending",
});

      _reportController.clear(); // Clear the input field after submitting

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e\nPlease try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Safety"),
        backgroundColor: Colors.redAccent,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔹 GUIDELINES
         Card(
  child: ExpansionTile(
    leading: const Icon(Icons.rule, color: Colors.blue),
    title: const Text("Community Guidelines"),
    children: const [
      Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          "• Be respectful and professional in all interactions\n\n"
          "• Do not use abusive, offensive, or inappropriate language\n\n"
          "• Stay focused on learning and teaching skills\n\n"
          "• Do not share personal or sensitive information unnecessarily\n\n"
          "• Avoid spam, fake requests, or misleading information\n\n"
          "• Respect session timings and commitments\n\n"
          "• Report suspicious or harmful behavior immediately\n\n"
          "• Help maintain a positive and collaborative environment",
        ),
      ),
    ],
  ),
),

          const SizedBox(height: 12),

          /// 🔹 SAFETY
         Card(
  child: ExpansionTile(
    leading: const Icon(Icons.shield, color: Colors.green),
    title: const Text("Safety Resources"),
    children: const [
      ListTile(
        leading: Icon(Icons.verified_user),
        title: Text("Secure Login & Authentication"),
        subtitle: Text("Your account is protected using Firebase authentication."),
      ),
      ListTile(
        leading: Icon(Icons.lock),
        title: Text("Data Privacy Protection"),
        subtitle: Text("Your personal data is stored securely and not shared."),
      ),
      ListTile(
        leading: Icon(Icons.video_call),
        title: Text("Safe Video Sessions"),
        subtitle: Text("All sessions are monitored for safe usage."),
      ),
      ListTile(
        leading: Icon(Icons.report),
        title: Text("Report & Block Users"),
        subtitle: Text("You can report or avoid suspicious users anytime."),
      ),
      ListTile(
        leading: Icon(Icons.support_agent),
        title: Text("24/7 Support"),
        subtitle: Text("Reach out to us anytime for help."),
      ),
    ],
  ),
),
const SizedBox(height: 12),

Card(
  child: ExpansionTile(
    leading: const Icon(Icons.schedule, color: Colors.orange),
    title: const Text("Session Rules"),
    children: const [
      Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          "• Minimum session duration is 1 hour\n\n"
          "• Be punctual and join sessions on time\n\n"
          "• Complete your session responsibly\n\n"
          "• Mark session as completed after finishing\n\n"
          "• Missing sessions may lead to warnings or penalties\n\n"
          "• Repeated absence may result in temporary restrictions\n\n"
          "• Respect the other user's time and effort\n\n"
          "• Maintain professionalism during video calls",
        ),
      ),
    ],
  ),
),
const SizedBox(height: 12),

Card(
  child: ExpansionTile(
    leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
    title: const Text("Credits & Rewards"),
    children: const [
      Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          "• Earn credits by teaching others\n\n"
          "• Spend credits to learn new skills\n\n"
          "• Fair usage ensures better experience\n\n"
          "• Credits may be deducted for missed sessions\n\n"
          "• Active users gain more opportunities to learn",
        ),
      ),
    ],
  ),
),

          const SizedBox(height: 20),

          /// 🔹 REPORT SECTION
          const Text(
            "Report an Issue",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // TextField for reporting issue
          TextField(
            controller: _reportController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe your issue...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(12), // Padding for better spacing
            ),
          ),

          const SizedBox(height: 12),

          // Submit button for the report
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport, // Disable while submitting
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit Report"),
          ),
        ],
      ),
    );
  }
}