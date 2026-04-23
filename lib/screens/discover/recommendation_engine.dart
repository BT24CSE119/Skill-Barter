import '../../models/user_model.dart';

class RecommendationEngine {
  /// Calculates how well two users fit based on "Needs vs Offers"
  static double calculateMatchPercentage(UserModel currentUser, UserModel otherUser) {
    if (currentUser.skillsWanted.isEmpty) return 0.0;

    int matchCount = 0;
    // Normalize lists to lowercase for accurate comparison
    final otherOffers = otherUser.skillsOffered.map((s) => s.toLowerCase()).toList();
    
    for (var skillNeeded in currentUser.skillsWanted) {
      if (otherOffers.contains(skillNeeded.toLowerCase())) {
        matchCount++;
      }
    }

    // Returns a percentage (e.g., 75.0)
    return (matchCount / currentUser.skillsWanted.length) * 100;
  }

  /// Filters out the current user and sorts others by Match Percentage
  static List<UserModel> getRecommendedUsers({
    required List<UserModel> allUsers,
    required UserModel currentUser,
    required String searchQuery,
  }) {
    // 1. Exclude self
    List<UserModel> list = allUsers.where((u) => u.uid != currentUser.uid).toList();

    // 2. Apply Search Filter (Search by Name or Skills)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((u) {
        final nameMatch = u.name.toLowerCase().contains(query);
        final skillMatch = u.skillsOffered.any((s) => s.toLowerCase().contains(query));
        return nameMatch || skillMatch;
      }).toList();
    }

    // 3. Sort by Match Percentage (Highest to Lowest)
    list.sort((a, b) {
      double scoreA = calculateMatchPercentage(currentUser, a);
      double scoreB = calculateMatchPercentage(currentUser, b);
      return scoreB.compareTo(scoreA);
    });

    return list;
  }
}