import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../chat/screens/chat_screen.dart';
import 'edit_event_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<Event>(
        stream: firestoreService.getEventStream(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Event not found or error occurred.'),
            );
          }

          final event = snapshot.data!;
          final bool isOwner = currentUser?.uid == event.organizerId;

          return CustomScrollView(
            slivers: [
              // Collapsing AppBar
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                floating: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                foregroundColor: Colors.black87,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      shadows: [Shadow(blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[200]),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Event',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEventScreen(event: event),
                        ),
                      ),
                    ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Event',
                      onPressed: () =>
                          _showDeleteDialog(context, firestoreService, event),
                    ),
                ],
              ),
              // Event content
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuickInfoCard(context, event),
                  _buildDescriptionCard(context, event),
                  if (event.thingsToCarry.isNotEmpty)
                    _buildInfoListCard(
                      context,
                      title: 'What to Bring',
                      items: event.thingsToCarry,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  if (event.thingsProvided.isNotEmpty)
                    _buildInfoListCard(
                      context,
                      title: 'What We Provide',
                      items: event.thingsProvided,
                      icon: Icons.check_circle_outline,
                    ),
                  _buildContactCard(context, event),
                  if (currentUser != null)
                    _buildActionButtons(
                      context,
                      firestoreService,
                      event,
                      currentUser,
                    ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // -------------------- Helper Widgets --------------------

  Widget _buildQuickInfoCard(BuildContext context, Event event) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoChip(
            Icons.calendar_today,
            "Date",
            DateFormat.yMMMd().format(event.eventDate),
          ),
          _buildInfoChip(
            Icons.access_time,
            "Time",
            DateFormat.jm().format(event.eventDate),
          ),
          _buildInfoChip(Icons.people, "Category", event.category),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade800, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoListCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => ListTile(
              leading: Icon(icon, color: Colors.green),
              title: Text(item, style: const TextStyle(fontSize: 16)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Event event) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(event.organizerName),
            subtitle: const Text("Organizer"),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    FirestoreService firestoreService,
    Event event,
    User currentUser,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<bool>(
        stream: firestoreService.hasUserJoined(event.id, currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasJoined = snapshot.data ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (hasJoined) {
                    firestoreService.leaveEvent(event.id, currentUser.uid);
                  } else {
                    firestoreService.joinEvent(event.id, currentUser.uid);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasJoined ? Colors.redAccent : Colors.green,
                ),
                child: Text(hasJoined ? 'Leave Event' : 'Join Event'),
              ),
              if (hasJoined)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Ask a Question (Event Chat)'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          eventId: event.id,
                          eventTitle: event.title,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    FirestoreService firestoreService,
    Event event,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
