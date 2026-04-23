import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? receiverId;

  final double amount;
  final String type; // earn / spend / transfer
  final String title;
  final String description;

  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.userId,
    this.receiverId,
    required this.amount,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  // 🔥 FROM FIRESTORE
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      receiverId: map['receiverId'],

      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'unknown',

      title: map['title'] ?? 'Transaction',
      description: map['description'] ?? '',

      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  // 🔥 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'receiverId': receiverId,
      'amount': amount,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // 🔥 UI HELPER (FOR LIST TILE / HISTORY)
  Map<String, dynamic> toUIMap() {
    return {
      "amount": amount,
      "type": type,
      "title": title,
      "description": description,
      "createdAt": Timestamp.fromDate(timestamp),
    };
  }

  // 🔥 CHECK HELPERS (VERY USEFUL)
  bool get isCredit => type == "earn";
  bool get isDebit => type == "spend";
  bool get isTransfer => type == "transfer";
}