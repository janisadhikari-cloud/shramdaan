import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../chat/screens/chat_screen.dart';
import 'edit_event_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId; // Now takes an ID
  const EventDetailsScreen({super.key, required this.eventId});

  // Helper method to show confirmation dialog for deletion
  Future<void> _showDeleteDialog(
    BuildContext context,
    FirestoreService firestoreService,
    Event event,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await firestoreService.deleteEvent(event.id);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back from details screen
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<Event>(
      stream: firestoreService.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(
                  child: Text('Event not found or error occurred.')));
        }

        final event = snapshot.data!;
        final bool isOwner = currentUser?.uid == event.organizerId;
        final String? currentUserId = currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(event.title),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventScreen(event: event),
                      ),
                    );
                  },
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      _showDeleteDialog(context, firestoreService, event),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    subtitle:
                        DateFormat.yMMMMd().add_jm().format(event.eventDate),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on,
                    title: 'Location',
                    subtitle: event.location,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'About this event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (currentUserId != null)
                    StreamBuilder<bool>(
                      stream: firestoreService.hasUserJoined(
                          event.id, currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final hasJoined = snapshot.data ?? false;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (hasJoined) {
                                  firestoreService.leaveEvent(
                                      event.id, currentUserId);
                                } else {
                                  firestoreService.joinEvent(
                                      event.id, currentUserId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasJoined
                                    ? Colors.redAccent
                                    : Colors.green,
                              ),
                              child:
                                  Text(hasJoined ? 'Leave Event' : 'Join Event'),
                            ),
                            const SizedBox(height: 8),
                            if (hasJoined)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.chat),
                                label: const Text('Go to Event Chat'),
                                onPressed: () {
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
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
