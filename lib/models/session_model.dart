import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String hostId;
  final String targetUserId;
  final String type; // credit | swap
  final String status; // pending | ongoing | completed
  final List<String> participants;
  final List<String> users;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? completedAt;
  final String? topic;
  final int? durationMinutes;

  SessionModel({
    required this.id,
    required this.hostId,
    required this.targetUserId,
    required this.type,
    required this.status,
    required this.participants,
    required this.users,
    this.createdAt,
    this.scheduledAt,
    this.startTime,
    this.endTime,
    this.completedAt,
    this.topic,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'targetUserId': targetUserId,
      'type': type,
      'status': status,
      'participants': participants,
      'users': users,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      if (startTime != null) 'startTime': Timestamp.fromDate(startTime!),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (topic != null) 'topic': topic,
      if (durationMinutes != null) 'duration': durationMinutes,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? _asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return SessionModel(
      id: id,
      hostId: (map['hostId'] ?? '') as String,
      targetUserId: (map['targetUserId'] ?? '') as String,
      type: (map['type'] ?? 'credit') as String,
      status: (map['status'] ?? 'pending') as String,
      participants: List<String>.from(map['participants'] ?? const <String>[]),
      users: List<String>.from(map['users'] ?? const <String>[]),
      createdAt: _asDate(map['createdAt']),
      scheduledAt: _asDate(map['scheduledAt']),
      startTime: _asDate(map['startTime']),
      endTime: _asDate(map['endTime']),
      completedAt: _asDate(map['completedAt']),
      topic: map['topic'] as String?,
      durationMinutes: (map['duration'] is int) ? map['duration'] as int : null,
    );
  }
}