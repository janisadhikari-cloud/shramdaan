import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch events when the screen is first initialized
    _eventsFuture = _firestoreService.getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        // 1. WHILE WAITING FOR DATA
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. IF THERE IS AN ERROR
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // 3. IF DATA IS EMPTY OR NULL
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        // 4. IF DATA IS AVAILABLE (SUCCESS)
        final events = snapshot.data!;
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(event: event);
          },
        );
      },
    );
  }
}