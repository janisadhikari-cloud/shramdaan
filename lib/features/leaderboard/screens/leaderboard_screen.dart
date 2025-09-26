import 'package:flutter/material.dart';
import '../../../shared/services/firestore_service.dart';
import '../models/leaderboard_entry_model.dart';
import '../../profile/screens/public_profile_screen.dart'; // NEW

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: firestoreService.getLeaderboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No participants yet.'));
          }

          final leaderboard = snapshot.data!;
          // Separate the top 3 from the rest
          final topThree = leaderboard.take(3).toList();
          final everyoneElse = leaderboard.skip(3).toList();

          return Column(
            children: [
              // The podium for the top 3
              _buildPodium(context, topThree),
              // The list for everyone else
              Expanded(
                child: ListView.builder(
                  itemCount: everyoneElse.length,
                  itemBuilder: (context, index) {
                    final entry = everyoneElse[index];
                    final rank = index + 4; // Start ranking from 4
                    return ListTile(
                      leading: Text(
                        '$rank',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      title: Text(entry.userName),
                      subtitle: Text('${entry.eventCount} events joined'),
                      trailing: CircleAvatar(
                        backgroundImage: entry.photoUrl.isNotEmpty
                            ? NetworkImage(entry.photoUrl)
                            : null,
                        child: entry.photoUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      onTap: () {
                        // UPDATED: Navigate to public profile
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PublicProfileScreen(userId: entry.userId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget to build the top 3 podium
  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> topThree) {
    // Reorder list to be [2nd, 1st, 3rd] for the visual layout
    final podiumOrder =
        (topThree.length > 1) ? [topThree[1], topThree[0]] : topThree;
    if (topThree.length > 2) podiumOrder.add(topThree[2]);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(podiumOrder.length, (index) {
          final entry = podiumOrder[index];
          int rank = 0;
          if (index == 0 && topThree.length > 1) rank = 2;
          if (index == 1) rank = 1;
          if (index == 2) rank = 3;
          if (topThree.length == 1) rank = 1;

          return _buildPodiumEntry(context, entry, rank);
        }),
      ),
    );
  }

  // Helper widget for a single entry on the podium
  Widget _buildPodiumEntry(
      BuildContext context, LeaderboardEntry entry, int rank) {
    final isFirst = rank == 1;
    final badgeColor =
        isFirst ? Colors.amber : (rank == 2 ? Colors.grey[400] : Colors.brown[300]);
    final avatarSize = isFirst ? 50.0 : 40.0;

    // UPDATED: Wrap Column with GestureDetector
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(userId: entry.userId),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: avatarSize,
                backgroundImage: entry.photoUrl.isNotEmpty
                    ? NetworkImage(entry.photoUrl)
                    : null,
                child: entry.photoUrl.isEmpty
                    ? Icon(Icons.person, size: avatarSize)
                    : null,
              ),
              Positioned(
                bottom: -5,
                right: -5,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: badgeColor,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.userName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${entry.eventCount} events'),
        ],
      ),
    );
  }
}
