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
      appBar: AppBar(),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestoreService.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String userName = userData['displayName'] ?? 'Anonymous';
          final String photoUrl = userData['photoUrl'] ?? '';

          return Column(
            children: [
              // User Info Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),
              // Joined Events List
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Events Joined', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<List<Event>>(
                  stream: firestoreService.getJoinedEventsStream(userId),
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!eventSnapshot.hasData || eventSnapshot.data!.isEmpty) {
                      return const Center(child: Text('This user hasn\'t joined any events.'));
                    }
                    final joinedEvents = eventSnapshot.data!;
                    return ListView.builder(
                      itemCount: joinedEvents.length,
                      itemBuilder: (context, index) {
                        final event = joinedEvents[index];
                        return ListTile(
                          title: Text(event.title),
                          subtitle: Text(event.category),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(eventId: event.id),
                          )),
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
}