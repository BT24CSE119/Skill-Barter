import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/skill_model.dart';
String getConnectionId(String uid1, String uid2) {
  return uid1.compareTo(uid2) < 0
      ? "${uid1}_$uid2"
      : "${uid2}_$uid1";
}

Future<void> acceptConnectionRequest(
  String currentUid,
  String otherUserId,
) async {
  final docId = "${currentUid}_$otherUserId";

  await FirebaseFirestore.instance
      .collection("connections")
      .doc(docId)
      .update({
    "status": "accepted",
    "acceptedAt": FieldValue.serverTimestamp(),
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> deleteSkill(String skillId) async {
    await _db.collection('skills').doc(skillId).delete();
  }

Future<void> rejectConnectionRequest(String otherUserId) async {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;

  /// delete request from current user
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUid)
      .collection('requests')
      .doc(otherUserId)
      .delete();

  /// delete request from other user
  await FirebaseFirestore.instance
      .collection('users')
      .doc(otherUserId)
      .collection('requests')
      .doc(currentUid)
      .delete();
}
  // =========================================================
  // 👤 USER PROFILE
  // =========================================================

  Stream<UserModel?> streamUserProfile({required String userId}) {
    return _db.collection("users").doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<List<UserModel>> streamAllProfiles() {
    return _db.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateUserField(String uid, String field, dynamic value) {
    return _db.collection("users").doc(uid).update({field: value});
  }

  Future<void> updateProfilePicture(String uid, String url) {
    return _db.collection("users").doc(uid).update({"photoUrl": url});
  }

  // =========================================================
  // 🔗 CONNECTION STATUS
  // =========================================================

Stream<String> connectionStatusStream(String uid1, String uid2) {
  final id = getConnectionId(uid1, uid2);

  return _db.collection("connectionRequests").doc(id).snapshots().map((doc) {
    if (!doc.exists) return "none";

    final data = doc.data()!;
    final sender = data['fromUserId'];
    final status = data['status'];

    if (status == "pending") {
      return sender == uid1 ? "pending" : "incoming";
    }

    if (status == "accepted") return "accepted";

    return "none";
  });
}

  // =========================================================
  // 🧠 SKILLS
  // =========================================================

  Future<void> updateSkills(
    String uid, {
    List<String>? offered,
    List<String>? wanted,
  }) async {
    final data = <String, dynamic>{};
    if (offered != null) data["skillsOffered"] = offered;
    if (wanted != null) data["skillsWanted"] = wanted;
    await _db.collection("users").doc(uid).update(data);
  }

  Stream<List<SkillModel>> streamSkills() {
    return _db
        .collection("skills")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkillModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addSkill(SkillModel skill) async {
    try {
      final docRef = _db.collection('skills').doc();
      final skillWithId = skill.copyWith(id: docRef.id);
      await docRef.set(skillWithId.toMap());
    } catch (e) {
      debugPrint("🔥 Error adding skill: $e");
      rethrow;
    }
  }

  Future<void> updateSkill(SkillModel skill) async {
    try {
      await _db.collection('skills').doc(skill.id).update(skill.toMap());
    } catch (e) {
      debugPrint("🔥 Error updating skill: $e");
      rethrow;
    }
  }


  // =========================================================
  // 🤝 CONNECTION SYSTEM
  // =========================================================

  String generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  Future<bool> _requestExists(String from, String to) async {
    final result = await _db
        .collection("connectionRequests")
        .where("fromUserId", isEqualTo: from)
        .where("toUserId", isEqualTo: to)
        .where("status", isEqualTo: "pending")
        .get();
    return result.docs.isNotEmpty;
  }
Future<void> sendConnectionRequest(String from, String to) async {
  if (from == to) return;

  final id = getConnectionId(from, to);

  await _db.collection("connectionRequests").doc(id).set({
    "fromUserId": from,
    "toUserId": to,
    "status": "pending",
    "timestamp": FieldValue.serverTimestamp(),
  });
}



  Stream<List<Map<String, dynamic>>> streamMyConnections(String userId) {
    return _db
        .collection("connectionRequests")
        .where("status", isEqualTo: "accepted")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['fromUserId'] == userId || data['toUserId'] == userId;
      }).map((doc) {
        final data = doc.data();
        final String fromId = data['fromUserId'] ?? "";
        final String toId = data['toUserId'] ?? "";

        return {
          "id": doc.id,
          ...data,
          "chatId": generateChatId(fromId, toId),
        };
      }).toList();
    });
  }

Future<void> acceptConnectionRequest(String otherUserId) async {
  final current = FirebaseAuth.instance.currentUser!.uid;
  final id = getConnectionId(current, otherUserId);

  await _db.collection("connectionRequests").doc(id).update({
    "status": "accepted",
  });

  final chatId = generateChatId(current, otherUserId);

  await _db.collection("chats").doc(chatId).set({
    "users": [current, otherUserId],
    "createdAt": FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

  Future<void> declineConnectionRequest(String requestId) {
    return _db.collection("connectionRequests").doc(requestId).update({
      "status": "declined"
    });
  }

  // =========================================================
  // 💬 CHAT SYSTEM
  // =========================================================

  Stream<List<Map<String, dynamic>>> streamUserChats(String userId) {
    return _db
        .collection("chats")
        .where("users", arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) {
        return {
          "chatId": doc.id,
          ...doc.data(),
        };
      }).toList();

      chats.sort((a, b) {
        final aTime = a["lastUpdated"];
        final bTime = b["lastUpdated"];

        if (aTime == null || bTime == null) return 0;

        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });

      return chats;
    });
  }

  Future<String> getOrCreateChat(String user1, String user2) async {
    final chatId = generateChatId(user1, user2);
    final chatRef = _db.collection("chats").doc(chatId);
    final exists = await chatRef.get();

    if (!exists.exists) {
      await chatRef.set({
        "users": [user1, user2],
        "createdAt": FieldValue.serverTimestamp(),
        "lastMessage": "",
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  Future<void> sendMessage(
      String chatId, String fromUserId, String message) async {
    final chatRef = _db.collection("chats").doc(chatId);
    await chatRef.collection("messages").add({
      "fromUserId": fromUserId,
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
    });

    await chatRef.set({
      "lastMessage": message,
      "lastUpdated": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String chatId) {
    return _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => {"id": d.id, ...d.data()}).toList());
  }

  // =========================================================
  // 🎥 SESSION SYSTEM
  // =========================================================
Future<void> startSession(
  String sessionId,
  String otherUserId,
) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    if (otherUserId.isEmpty) {
      debugPrint("❌ otherUserId is empty");
      return;
    }

    await FirebaseFirestore.instance
        .collection("sessions")
        .doc(sessionId)
        .set({
      "sessionId": sessionId,

      // 🔥 BOTH USERS
      "participants": [uid, otherUserId].toSet().toList(),

      "status": "ongoing",
      "startTime": FieldValue.serverTimestamp(),

      

    }, SetOptions(merge: true));

    
  } catch (e) {
    debugPrint("❌ startSession error: $e");
  }
}
  Future<void> endSession(String sessionId) async {
    await _db.collection("sessions").doc(sessionId).update({
      "status": "completed",
      "endTime": FieldValue.serverTimestamp(),
    });
  }

  Future<int> getSessionDuration(String sessionId) async {
    final doc = await _db.collection("sessions").doc(sessionId).get();
    if (!doc.exists) return 0;

    final data = doc.data()!;
    final start = data['startTime'];
    final end = data['endTime'];

    if (start == null || end == null) return 0;

    final duration =
        (end as Timestamp).toDate().difference((start as Timestamp).toDate());

    return duration.inMinutes;
  }

  Future<void> joinSession(String sessionId, String uid) async {
    await _db.collection("sessions").doc(sessionId).update({
      "participants": FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveSession(String sessionId, String uid) async {
    await _db.collection("sessions").doc(sessionId).update({
      "participants": FieldValue.arrayRemove([uid]),
    });
  }

  // =========================================================
  // 🎮 GAMIFICATION
  // =========================================================

  Future<void> incrementXP(String uid, int xpToAdd) async {
    try {
      await _db.collection('users').doc(uid).update({
        'xp': FieldValue.increment(xpToAdd),
      });
    } catch (e) {
      debugPrint("🔥 Error incrementing XP: $e");
    }
  }

  Future<void> updateStreak(String uid) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final Timestamp? lastActiveTs = data['lastActive'];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (lastActiveTs != null) {
        final lastActive = lastActiveTs.toDate();
        final lastActiveDay =
            DateTime(lastActive.year, lastActive.month, lastActive.day);

        final difference = todayDate.difference(lastActiveDay).inDays;

        if (difference == 1) {
          await userDoc.update({
            'streak': FieldValue.increment(1),
            'lastActive': FieldValue.serverTimestamp()
          });
        } else if (difference > 1) {
          await userDoc.update({
            'streak': 1,
            'lastActive': FieldValue.serverTimestamp()
          });
        } else {
          await userDoc.update({
            'lastActive': FieldValue.serverTimestamp()
          });
        }
      } else {
        await userDoc.update({
          'streak': 1,
          'lastActive': FieldValue.serverTimestamp()
        });
      }
    } catch (e) {
      debugPrint("🔥 Error updating streak: $e");
    }
  }

  // =========================================================
  // 🔔 NOTIFICATIONS
  // =========================================================

  Stream<QuerySnapshot> streamNotifications(String userId) {
    return _db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
