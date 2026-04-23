import 'package:cloud_firestore/cloud_firestore.dart';

class SkillModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String ownerId;

  /// 🔥 VERIFICATION SYSTEM
  final String status; // pending, approved, rejected
  final bool isVerified;

  /// 🔥 EXTRA FIELDS
  final int price;
  final double rating;

  /// 🔥 MEDIA / LINK
  final String? imageUrl;
  final String? resourceLink; // ✅ NEW (IMPORTANT)

  final DateTime createdAt;

  SkillModel({
    required this.id,
    required this.name,
    required this.description,
    this.category = "General",
    required this.ownerId,
    this.status = "pending",
    this.isVerified = false,
    this.price = 0,
    this.rating = 0.0,
    this.imageUrl,
    this.resourceLink, // ✅ NEW
    required this.createdAt,
  });

  /// 🔥 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'ownerId': ownerId,

      'status': status,
      'isVerified': isVerified,

      'price': price,
      'rating': rating,

      'imageUrl': imageUrl,
      'resourceLink': resourceLink, // ✅ NEW

      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 🔥 FROM FIRESTORE
  factory SkillModel.fromMap(Map<String, dynamic> map, String docId) {
    return SkillModel(
      id: docId,

      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      ownerId: map['ownerId'] ?? '',

      status: map['status'] ?? 'pending',
      isVerified: map['isVerified'] ?? false,

      price: (map['price'] ?? 0).toInt(),
      rating: (map['rating'] ?? 0).toDouble(),

      imageUrl: map['imageUrl'],
      resourceLink: map['resourceLink'], // ✅ NEW

      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// ✅ EMPTY (SAFE FALLBACK)
  factory SkillModel.empty() {
    return SkillModel(
      id: '',
      name: '',
      description: '',
      category: 'General',
      ownerId: '',
      status: "pending",
      isVerified: false,
      price: 0,
      rating: 0.0,
      imageUrl: null,
      resourceLink: null, // ✅ NEW
      createdAt: DateTime.now(),
    );
  }

  /// 🔥 COPY WITH
  SkillModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? ownerId,
    String? status,
    bool? isVerified,
    int? price,
    double? rating,
    String? imageUrl,
    String? resourceLink, // ✅ NEW
    DateTime? createdAt,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      resourceLink: resourceLink ?? this.resourceLink, // ✅ NEW
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 🔥 HELPERS
  bool get isFree => price == 0;
  bool get isApproved => status == "approved";
}