import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_model.dart';
import '../screens/event_details_screen.dart'; // Import the details screen

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat.yMMMMd().format(event.eventDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.green),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$formattedDate - ${event.location}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Pass eventId instead of the whole object
              builder: (context) => EventDetailsScreen(eventId: event.id),
            ),
          );
        },
      ),
    );
  }
}
