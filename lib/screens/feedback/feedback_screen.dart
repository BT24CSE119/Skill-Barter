import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  final String sessionId;

  const FeedbackScreen({super.key, required this.sessionId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();

  /// 🔥 FEEDBACK FIELDS
  String teaching = "good";
  String communication = "clear";
  double behavior = 5;
  double knowledge = 5;
  double experience = 0;
  bool recommend = true;

  /// ================= SUBMIT =================
  Future<void> _submitFeedback(User user) async {
    if (_controller.text.trim().isEmpty) return;

    await _db.collection("reports").add({
      "userId": user.uid,
      "sessionId": widget.sessionId,

      "teaching": teaching,
      "communication": communication,
      "behavior": behavior,
      "knowledge": knowledge,
      "experience": experience,
      "recommend": recommend,

      "message": _controller.text.trim(),

      "type": "feedback",
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback submitted successfully ✅")),
    );
  }

  /// ================= FEEDBACK CARD =================
  Widget _buildFeedbackCard(
      Map<String, dynamic> data, DocumentReference ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// MESSAGE
          Text(
            data['message'] ?? "",
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 8),

          /// DETAILS
         /// DETAILS
Text(
  "Teaching: ${data['teaching'] ?? "N/A"}",
  style: const TextStyle(color: Colors.blueAccent),
),

Text(
  "Communication: ${data['communication'] ?? "N/A"}",
  style: const TextStyle(color: Colors.blueAccent),
),

Text(
  "Behavior: ${(data['behavior'] ?? 0)}/10",
  style: const TextStyle(color: Colors.white),
),

Text(
  "Knowledge: ${(data['knowledge'] ?? 0)}/10",
  style: const TextStyle(color: Colors.white),
),

Text(
  "Experience: ${(data['experience'] ?? 0)} ⭐",
  style: const TextStyle(color: Colors.amber),
),

          Text(
  (data['recommend'] ?? false)
      ? "Recommended ✅"
      : "Not Recommended ❌",
  style: TextStyle(
    color: (data['recommend'] ?? false)
        ? Colors.green
        : Colors.red,
  ),
),

          const SizedBox(height: 10),

          /// DELETE BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => ref.delete(),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

   return Scaffold(
  backgroundColor: const Color(0xFF0F0F0F),

  appBar: AppBar(
    title: const Text(
      "Feedback",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    centerTitle: true,
    backgroundColor: const Color(0xFF0F0F0F),
    elevation: 0,
  ),

  body: SafeArea(
    child: Column(
      children: [

        /// 🔽 SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 TITLE
                const Text(
                  "Rate Your Teacher",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔷 CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// TEACHING
                      _buildDropdown(
  label: "Teaching Ability",
  value: teaching,
  items: const ["bad", "average", "good", "excellent"],
  onChanged: (v) => setState(() => teaching = v),
),

                      const SizedBox(height: 12),

                      /// TEACHING

/// COMMUNICATION
_buildDropdown(
  label: "Communication Ability",
  value: communication,
  items: const ["poor", "clear", "very_clear"],
  onChanged: (v) => setState(() => communication = v),
),

                      const SizedBox(height: 12),

                      /// BEHAVIOR
                      _buildSlider(
                        title: "Behavior (out of 10)",
                        value: behavior,
                        onChanged: (v) => setState(() => behavior = v),
                      ),

                      /// KNOWLEDGE
                      _buildSlider(
                        title: "Knowledge (out of 10)",
                        value: knowledge,
                        onChanged: (v) => setState(() => knowledge = v),
                      ),

                      const SizedBox(height: 12),

                      /// EXPERIENCE
                      const Text(
                        "Overall Experience",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Row(
                        children: List.generate(5, (i) {
                          return IconButton(
                            iconSize: 30,
                            icon: Icon(
                              i < experience
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () =>
                                setState(() => experience = i + 1.0),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      /// MESSAGE BOX
                      TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Write your feedback...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// RECOMMEND
                      SwitchListTile(
                        value: recommend,
                        onChanged: (v) => setState(() => recommend = v),
                        title: const Text(
                          "Recommend this teacher",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 🔥 FIXED SUBMIT BUTTON
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  user != null ? () => _submitFeedback(user) : null,
              child: const Text(
                "Submit Feedback",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  /// ================= HELPER WIDGETS =================

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          label: value.toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}