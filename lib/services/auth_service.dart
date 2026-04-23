import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ================= AUTH STATE STREAM (IMPORTANT) =================
  Stream<User?> get authState => _auth.authStateChanges();

  /// ================= GET ROLE =================
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'] ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  /// ================= SAVE / UPDATE USER =================
  Future<void> _saveUser(User user, {String role = "user"}) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? "",
        'name': user.displayName ?? "",
        'photoUrl': user.photoURL ?? "",
        'role': role,

        /// 🔐 AUTH CONTROL
        'emailVerified': user.emailVerified,
        'isActive': true,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),

        /// 💰 WALLET
        'walletBalance': 0,
        'totalEarned': 0,
        'totalSpent': 0,

        /// 🧠 GAMIFICATION
        'xp': 0,
        'badges': [],
        'streak': 0,

        /// 🧑‍💻 PROFILE
        'skillsOffered': [],
        'skillsWanted': [],
        'bio': "",
        'profilePrivate': false,
        'profileCompleted': 0,

        /// 📊 STATS
        'sessionsCount': 0,
        'exchangesCount': 0,

        /// ⚡ STATUS
        'online': true,
      });
    } else {
      await ref.set({
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'online': true,
      }, SetOptions(merge: true));
    }
  }
  // Inside lib/services/auth_service.dart

Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email.trim());
  } on FirebaseAuthException catch (e) {
    // This allows you to catch specific Firebase errors (like user-not-found)
    throw e.message ?? "An error occurred while sending reset email";
  } catch (e) {
    throw "An unexpected error occurred";
  }
}

  /// ================= EMAIL LOGIN =================
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await _saveUser(user);

        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }
      }

      return user;
    }on FirebaseAuthException catch (e) {
  throw e;
}
  }

  /// ================= SIGNUP =================
Future<User?> signup(String name, String email, String password) async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    throw e; // ✅ VERY IMPORTANT FIX
  }
}

  /// ================= GOOGLE LOGIN =================
  Future<User?> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        await _saveUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
  throw e;
}
  }


  /// ================= PASSWORD RESET =================
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    final user = _auth.currentUser;

    if (user != null) {
      await _db.collection("users").doc(user.uid).set({
        "online": false,
        "lastSeen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _auth.signOut();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}


  }

  /// ================= CURRENT USER =================
  User? getCurrentUser() => _auth.currentUser;
}