import '../../models/user_model.dart';

class MatchEngine {
  /// Calculates a 0-100% score based on skill synergy
  static double getCompatibility(UserModel currentUser, UserModel targetUser) {
    if (currentUser.skillsWanted.isEmpty) return 0.0;

    int matches = 0;
    final targetOffers = targetUser.skillsOffered.map((s) => s.toLowerCase()).toList();

    for (var skill in currentUser.skillsWanted) {
      if (targetOffers.contains(skill.toLowerCase())) {
        matches++;
      }
    }

    double baseScore = (matches / currentUser.skillsWanted.length) * 100;
    
    // Bonus for high XP (Expertise level)
    double xpBonus = (targetUser.xp > 1000) ? 10 : 0;
    
    return (baseScore + xpBonus).clamp(0, 100);
  }

  /// Filters and sorts users so the best matches appear first
  static List<UserModel> sortProfiles(List<UserModel> allUsers, UserModel currentUser, String query) {
    return allUsers
        .where((u) => u.uid != currentUser.uid) // Exclude self
        .where((u) => u.name.toLowerCase().contains(query.toLowerCase()) || 
                      u.skillsOffered.any((s) => s.toLowerCase().contains(query.toLowerCase())))
        .toList()
      ..sort((a, b) => getCompatibility(currentUser, b).compareTo(getCompatibility(currentUser, a)));
  }
}