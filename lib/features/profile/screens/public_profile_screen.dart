import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../events/screens/event_details_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestoreService.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String userName = userData['displayName'] ?? 'Anonymous';
          final String photoUrl = userData['photoUrl'] ?? '';

          return ListView(
            // Use a ListView for a clean, scrollable layout
            children: [
              // --- Profile Header ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Joined Events Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 8, left: 4),
                      child: Text(
                        'Events Joined',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StreamBuilder<List<Event>>(
                      stream: firestoreService.getJoinedEventsStream(userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Card(
                            child: ListTile(
                              title: Text(
                                'This user hasn\'t joined any events yet.',
                              ),
                            ),
                          );
                        }
                        final joinedEvents = eventSnapshot.data!;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap:
                                true, // Important for ListView inside a Column
                            physics:
                                const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                            itemCount: joinedEvents.length,
                            itemBuilder: (context, index) {
                              final event = joinedEvents[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: event.imageUrl.isNotEmpty
                                      ? NetworkImage(event.imageUrl)
                                      : null,
                                  child: event.imageUrl.isEmpty
                                      ? const Icon(Icons.event)
                                      : null,
                                ),
                                title: Text(event.title),
                                subtitle: Text(event.category),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventDetailsScreen(eventId: event.id),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
