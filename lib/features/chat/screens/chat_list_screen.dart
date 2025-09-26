import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Event Chats'),
      ),
      body: currentUserId == null
          ? const Center(child: Text('Please log in to see your chats.'))
          : StreamBuilder<List<Event>>(
              stream: firestoreService.getJoinedEventsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('You have not joined any events yet.'));
                }

                final joinedEvents = snapshot.data!;
                return ListView.builder(
                  itemCount: joinedEvents.length,
                  itemBuilder: (context, index) {
                    final event = joinedEvents[index];
                    return ListTile(
                      // UPDATED: Show the event image in a CircleAvatar
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: event.imageUrl.isNotEmpty
                            ? NetworkImage(event.imageUrl)
                            : null,
                        child: event.imageUrl.isEmpty
                            ? const Icon(Icons.event, color: Colors.grey)
                            : null,
                      ),
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(event.location),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              eventId: event.id,
                              eventTitle: event.title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}