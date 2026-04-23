// lib/core/utils/helpers.dart
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Helpers {
  /// Format Firestore Timestamp into a readable string
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat("dd MMM yyyy, hh:mm a").format(timestamp.toDate());
    }
    return "";
  }

  /// Capitalize first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Shorten long text with ellipsis
  static String truncate(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}...";
  }

  /// Format credits with + or - sign
  static String formatCredits(int amount, {bool isCredit = true}) {
    return "${isCredit ? '+' : '-'}$amount Credits";
  }
}

/// Calculate user level based on XP
int getLevel(int xp) {
  if (xp < 100) return 1;
  if (xp < 500) return 2;
  if (xp < 1000) return 3;
  if (xp < 2000) return 4;
  return 5; // max level for now
}
