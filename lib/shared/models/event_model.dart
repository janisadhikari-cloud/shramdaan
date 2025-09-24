import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String category;
  final String organizerId;   // NEW
  final String organizerName; // NEW

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.category,
    required this.organizerId,   // NEW
    required this.organizerName, // NEW
  });

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    DateTime eventDateTime;

    // ✅ Safely handle Firestore Timestamp for eventDate
    if (data['eventDate'] is Timestamp) {
      eventDateTime = (data['eventDate'] as Timestamp).toDate();
    } else {
      print(
          "Warning: 'eventDate' field was missing or not a Timestamp for document $id. Using fallback date.");
      eventDateTime = DateTime.now();
    }

    return Event(
      id: id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      location: data['location'] ?? 'No Location',
      eventDate: eventDateTime,
      category: data['category'] ?? 'General',
      organizerId: data['organizerId'] ?? '',     // NEW
      organizerName: data['organizerName'] ?? '', // NEW
    );
  }
}
