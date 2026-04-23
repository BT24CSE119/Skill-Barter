import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ================= TRANSACTION MODEL =================
class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime timestamp;
  final String type; // credit / debit
  final String title;
  

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.title,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['timestamp'];

    DateTime time;
    if (ts is Timestamp) {
      time = ts.toDate();
    } else {
      time = DateTime.now(); // fallback fix
    }

    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: map['type'] ?? 'debit',
      title: map['title'] ?? 'Transaction',
      timestamp: time,
    );
  }

  bool get isCredit => type == 'credit';
}

/// ================= TRANSACTION TILE =================
class TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const TransactionTile({super.key, required this.txn});

  String getTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inDays < 1) return "${diff.inHours} hr ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat("dd MMM").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            txn.isCredit ? Icons.arrow_upward : Icons.arrow_downward,
            color: txn.isCredit ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  getTime(txn.timestamp),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            "${txn.isCredit ? '+' : '-'}₹${txn.amount.toInt()}",
            style: TextStyle(
              color: txn.isCredit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= WALLET SCREEN =================
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _firestore = FirebaseFirestore.instance;

  /// 🔥 ADD / SPEND FUNCTION (PRO SAFE VERSION)
  Future<void> _addTransaction(int amount, String type, String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection("users").doc(uid);
    final txnRef = _firestore.collection("transactions").doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception("User not found");
        }

        final data = snapshot.data()!;
        int currentBalance = (data['walletBalance'] ?? 0);

        final isCredit = type == "credit";

        /// ❌ Prevent negative balance
        if (!isCredit && currentBalance < amount) {
          throw Exception("Not enough balance");
        }

        /// ✅ Update wallet
        transaction.set(
          userRef,
          {
            "walletBalance":
                FieldValue.increment(isCredit ? amount : -amount),
            "totalEarned":
                FieldValue.increment(isCredit ? amount : 0),
            "totalSpent":
                FieldValue.increment(isCredit ? 0 : amount),
          },
          SetOptions(merge: true),
        );

        /// ✅ Create transaction
        transaction.set(txnRef, {
          "amount": amount,
          "type": type,
          "title": title,
          "userId": uid,
          "timestamp": FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// USER STREAM
  Stream<DocumentSnapshot> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection("users").doc(uid).snapshots();
  }

  /// TRANSACTION STREAM
Stream<List<TransactionModel>> _transactionStream() {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection("transactions")
      .where("userId", isEqualTo: uid)
      .snapshots()
      .map((snapshot) {

        print("Docs count: ${snapshot.docs.length}");

        final list = snapshot.docs.map((doc) {
          final data = doc.data();

          return TransactionModel.fromMap(doc.id, data);
        }).toList();

        /// 🔥 LOCAL SORT
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return list;
      });
}
  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: const Text("Wallet"),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream(),
     builder: (context, snap) {

  if (snap.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (!snap.hasData || snap.data!.data() == null) {
    return const Center(child: Text("No data"));
  }

  final data =
      snap.data!.data() as Map<String, dynamic>? ?? {};


          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// BALANCE
                const Text(
                  "Wallet Balance",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${data['walletBalance'] ?? 0}",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () =>
                            _addTransaction(10, "credit", "Added Credits"),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Credits"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () =>
                            _addTransaction(5, "debit", "Spent Credits"),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Spend"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// STATS
                Row(
                  children: [
                    _stat("Earned", data['totalEarned'] ?? 0, Colors.green),
                    _stat("Spent", data['totalSpent'] ?? 0, Colors.red),
                  ],
                ),

                const SizedBox(height: 20),

                /// TRANSACTIONS
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent Transactions",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<List<TransactionModel>>(
                    stream: _transactionStream(),
                   builder: (context, snap) {

  if (snap.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (snap.hasError) {
  print("🔥 FIRESTORE ERROR: ${snap.error}");
  return Center(
    child: Text(
      "Error: ${snap.error}",
      style: const TextStyle(color: Colors.red),
    ),
  );
}
                      final txns = snap.data!;

                      if (txns.isEmpty) {
                        return const Center(
                          child: Text(
                            "No transactions",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: txns.length,
                        itemBuilder: (_, i) =>
                            TransactionTile(txn: txns[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String title, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              "₹$value",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}