import 'package:cloud_firestore/cloud_firestore.dart';

/// ======================================================
/// USER MODEL
/// ======================================================
class UserModel {
  final String uid;

  /// Basic Info
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String role; // user / admin / super_admin
  final bool isActive;
  final bool isVerified;

  /// Wallet + Gamification
  final int credits; // current wallet balance
  final int totalEarned;
  final int totalSpent;
  final int xp;
  final int level; // <-- NEW FIELD
  final bool darkMode;
  final List<String> badges;
  final int streak;

  /// Activity Tracking
  final DateTime? createdAt;
  final DateTime? lastActive;

  /// Skills
  final List<String> skillsOffered;
  final List<String> skillsWanted;

  /// Profile Stats
  final double completionPercent;
  final int sessionsCount;
  final int exchangesCount;
  final int rank;
  final int percentile;

  /// Social Links
  final String? linkedin;
  final String? github;
  final String? instagram;

  /// Recent Activity Timeline
  final List<Activity> activities;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.role = "user",
this.isActive = true,
this.isVerified = false, // 🔥 ADD THIS LINE
    this.credits = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.xp = 0,
    this.level = 1, // <-- default level
    this.darkMode = false,
    this.badges = const [],
    this.streak = 0,
    this.createdAt,
    this.lastActive,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.completionPercent = 0,
    this.sessionsCount = 0,
    this.exchangesCount = 0,
    this.rank = 0,
    this.percentile = 0,
    this.linkedin,
    this.github,
    this.instagram,
    this.activities = const [],
    
  });

  /// ======================================================
  /// EMPTY MODEL
  /// ======================================================
  factory UserModel.empty() {
    return  UserModel(
      uid: '',
      name: '',
      email: '',
      photoUrl: '',
      bio: '',
      role: 'user',
      isActive: true,
      credits: 0,
      totalEarned: 0,
      totalSpent: 0,
      xp: 0,
      level: 1, // <-- added here
      darkMode: false,
      badges: [],
      streak: 0,
      skillsOffered: [],
      skillsWanted: [],
      completionPercent: 0,
      sessionsCount: 0,
      exchangesCount: 0,
      rank: 0,
      percentile: 0,
      linkedin: '',
      github: '',
      instagram: '',
      activities: [],
    );
  }

  /// ======================================================
  /// FROM FIRESTORE
  /// ======================================================
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    Timestamp? createdTs = data['createdAt'];
    Timestamp? activeTs = data['lastActive'];

    return UserModel(
      uid: uid,

      /// Basic Info
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,

      /// Wallet
      credits: (data['walletBalance'] ?? data['credits'] ?? 0) as int,
      totalEarned: (data['totalEarned'] ?? 0) as int,
      totalSpent: (data['totalSpent'] ?? 0) as int,

      /// Gamification
      xp: (data['xp'] ?? 0) as int,
      level: (data['level'] ?? ((data['xp'] ?? 0) ~/ 100 + 1)) as int, // <-- fallback calc
      darkMode: data['darkMode'] ?? false,
      badges: data['badges'] != null
          ? List<String>.from(data['badges'])
          : [],
      streak: (data['streak'] ?? 0) as int,

      /// Activity
      createdAt: createdTs?.toDate(),
      lastActive: activeTs?.toDate(),

      /// Skills
      skillsOffered: data['skillsOffered'] != null
          ? List<String>.from(data['skillsOffered'])
          : [],
      skillsWanted: data['skillsWanted'] != null
          ? List<String>.from(data['skillsWanted'])
          : [],

      /// Profile Stats
      completionPercent: (data['completionPercent'] ?? 0).toDouble(),
      sessionsCount: (data['sessionsCount'] ?? 0) as int,
      exchangesCount: (data['exchangesCount'] ?? 0) as int,
      rank: (data['rank'] ?? 0) as int,
      percentile: (data['percentile'] ?? 0) as int,

      /// Social
      linkedin: data['linkedin'],
      github: data['github'],
      instagram: data['instagram'],

      /// Timeline
      activities: data['activities'] != null
          ? (data['activities'] as List)
              .map((e) => Activity.fromMap(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
    );
  }

  /// ======================================================
  /// TO FIRESTORE
  /// ======================================================
  Map<String, dynamic> toMap() {
    return {
      /// Basic
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'role': role,
      'isActive': isActive,

      /// Wallet
      'walletBalance': credits,
      'credits': credits,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,

      /// Gamification
      'xp': xp,
      'level': level, // <-- added here
      'darkMode': darkMode,
      'badges': badges,
      'streak': streak,

      /// Activity
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,

      /// Skills
      'skillsOffered': skillsOffered,
      'skillsWanted': skillsWanted,

      /// Stats
      'completionPercent': completionPercent,
      'sessionsCount': sessionsCount,
      'exchangesCount': exchangesCount,
      'rank': rank,
      'percentile': percentile,

      /// Social
      'linkedin': linkedin,
      'github': github,
      'instagram': instagram,

      /// Timeline
      'activities': activities.map((e) => e.toMap()).toList(),
    };
  }

  /// ======================================================
  /// COPY WITH
  /// ======================================================
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    String? role,
    bool? isActive,
    int? credits,
    int? totalEarned,
    int? totalSpent,
    int? xp,
    int? level, // <-- added here
    bool? darkMode,
    List<String>? badges,
    int? streak,
    DateTime? createdAt,
    DateTime? lastActive,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    double? completionPercent,
    int? sessionsCount,
    int? exchangesCount,
    int? rank,
    int? percentile,
    String? linkedin,
    String? github,
    String? instagram,
    List<Activity>? activities,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      credits: credits ?? this.credits,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      xp: xp ?? this.xp,
      level: level ?? this.level, // <-- added here
      darkMode: darkMode ?? this.darkMode,
      badges: badges ?? this.badges,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsWanted: skillsWanted ?? this.skillsWanted,
      completionPercent: completionPercent ?? this.completionPercent,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      exchangesCount: exchangesCount ?? this.exchangesCount,
      rank: rank ?? this.rank,
      percentile: percentile ?? this.percentile,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      instagram: instagram ?? this.instagram,
      activities: activities ?? this.activities,
    );
  }
}
/// ======================================================
/// ACTIVITY MODEL
/// ======================================================
class Activity {
  final String title;
  final String description;
  final DateTime? timestamp;
  final String type; // session / skill / credit / badge

  const Activity({
    required this.title,
    this.description = '',
    this.timestamp,
    this.type = 'general',
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }
}