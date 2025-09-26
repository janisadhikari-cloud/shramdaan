class LeaderboardEntry {
  final String userId;       // NEW
  final String userName;
  final String photoUrl;     // NEW
  final int eventCount;

  LeaderboardEntry({
    required this.userId,     // NEW
    required this.userName,
    required this.photoUrl,     // NEW
    required this.eventCount,
  });
}