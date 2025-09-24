import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
  });

  // Factory constructor to create an Event from a Firestore document
  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      // Firestore Timestamps need to be converted to DateTime
      eventDate: (data['eventDate'] as Timestamp).toDate(),
    );
  }
}