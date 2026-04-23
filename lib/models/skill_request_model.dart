import 'package:cloud_firestore/cloud_firestore.dart';

class SkillRequestModel {
  final String id;

  final String skillId;
  final String senderId;   // who requested
  final String receiverId; // skill owner

  final int price;
  final String message;

  final String status; // pending / accepted / rejected / completed

  final DateTime createdAt;
  final DateTime? updatedAt;

  SkillRequestModel({
    required this.id,
    required this.skillId,
    required this.senderId,
    required this.receiverId,
    required this.price,
    this.message = "",
    this.status = "pending",
    required this.createdAt,
    this.updatedAt,
  });

  /// 🔥 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'skillId': skillId,
      'senderId': senderId,
      'receiverId': receiverId,
      'price': price,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : null,
    };
  }

  /// 🔥 FROM FIRESTORE
  factory SkillRequestModel.fromMap(
      String id, Map<String, dynamic> map) {
    return SkillRequestModel(
      id: id,
      skillId: map['skillId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      price: (map['price'] ?? 0).toInt(),
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',

      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),

      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// ✅ COPY WITH (UPDATE STATUS EASY)
  SkillRequestModel copyWith({
    String? id,
    String? skillId,
    String? senderId,
    String? receiverId,
    int? price,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillRequestModel(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      price: price ?? this.price,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 🔥 HELPERS
  bool get isPending => status == "pending";
  bool get isAccepted => status == "accepted";
  bool get isRejected => status == "rejected";
  bool get isCompleted => status == "completed";
}