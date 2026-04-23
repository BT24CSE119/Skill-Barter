class AppConstants {
  // App-wide values
  static const String appName = "SkillBarter";

  // Firestore collections
  static const String usersCollection = "users";
  static const String sessionsCollection = "sessions";
  static const String transactionsCollection = "transactions";
  static const String notificationsCollection = "notifications";
  static const String feedbackCollection = "feedback";

  // Default values
  static const int defaultCredits = 0;
  static const int defaultXP = 0;

  // Session statuses
  static const String statusPending = "pending";
  static const String statusOngoing = "ongoing";
  static const String statusCompleted = "completed";
}