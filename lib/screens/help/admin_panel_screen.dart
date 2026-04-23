import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Status Constants
const String statusResolved = "resolved";
const String statusInvestigating = "investigating";
const String statusDismissed = "dismissed";
const String statusPending = "pending";

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  // Function to update report status and send notification
  Future<void> _updateReportStatus(
      String reportId, String userId, String status, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection("reports")
          .doc(reportId)
          .update({"status": status});

      // Send notification to user
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": userId,
        "title": "Report Update",
        "message": "Your report is now $status",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marked as $status"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to get color for each status
  Color _statusColor(String status) {
    switch (status) {
      case statusResolved:
        return Colors.green;
      case statusInvestigating:
        return Colors.orange;
      case statusDismissed:
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports found ✅"));
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;

              final status = data["status"] ?? statusPending;
              final userId = data["userId"] ?? "unknown";
              final message = data["message"] ?? "No message";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.report, color: _statusColor(status)),
                  title: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text("User: $userId\nStatus: $status"),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _updateReportStatus(report.id, userId, value, context),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: statusResolved,
                        child: const Text("Mark Resolved"),
                      ),
                      PopupMenuItem(
                        value: statusInvestigating,
                        child: const Text("Mark Investigating"),
                      ),
                      PopupMenuItem(
                        value: statusDismissed,
                        child: const Text("Dismiss"),
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