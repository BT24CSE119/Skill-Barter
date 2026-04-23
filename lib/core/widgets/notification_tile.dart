import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMention = notification['isMention'] ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: Icon(
          isMention ? Icons.alternate_email : Icons.notifications,
          color: isMention ? Colors.blueAccent : Colors.orange,
          size: 28,
        ),
        title: Text(
          notification['title'] ?? "Notification",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification['message'] ?? ""),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}