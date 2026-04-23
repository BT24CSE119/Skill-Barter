import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Load preference from local storage first, then Firestore
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool("darkMode") ?? false;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _db.collection("users").doc(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _isDarkMode = data['darkMode'] ?? _isDarkMode;
      }
    }

    notifyListeners();
  }

  /// Toggle and persist preference
  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", value);

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection("users").doc(user.uid).update({
        "darkMode": value,
      });
    }
  }
}