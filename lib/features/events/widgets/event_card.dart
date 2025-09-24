import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import '../../../shared/models/event_model.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Format the date into a more readable string
    final String formattedDate = DateFormat.yMMMMd().format(event.eventDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.green),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$formattedDate - ${event.location}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // TODO: Navigate to event details screen
        },
      ),
    );
  }
}