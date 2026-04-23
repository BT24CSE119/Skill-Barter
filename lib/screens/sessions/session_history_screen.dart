import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Login required")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Session History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("sessions")
            .where("status", isEqualTo: "completed")
            .snapshots(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.where((doc) {
          final raw = doc.data();

if (raw == null) return false;  // ✅ SAFE

final data = raw as Map<String, dynamic>;

            return data['hostId'] == uid ||
                   data['targetUserId'] == uid;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text("No completed sessions"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              final skill = data['skillOffered'] ?? "Skill";
              final type = data['type'] ?? "credit";

              final rating =
                  data['rating_$uid']?.toString() ?? "Not rated";

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(skill),
                  subtitle: Text("Type: $type"),
                  trailing: Text("⭐ $rating"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}