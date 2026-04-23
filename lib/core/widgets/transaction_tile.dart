import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const TransactionTile({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn['type'] == 'earn' || txn['type'] == 'Credit';

    String formattedDate = "";
    final timestamp = txn['createdAt'] ?? txn['timestamp'];
    if (timestamp is Timestamp) {
      formattedDate =
          DateFormat("dd MMM yyyy, hh:mm a").format(timestamp.toDate());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          isCredit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isCredit ? Colors.green : Colors.redAccent,
          size: 28,
        ),
        title: Text(
          txn['description'] ?? 'Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(formattedDate, style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          "${isCredit ? '+' : '-'}${txn['amount']} Credits",
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}