import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String category;
  final String organizerId;
  final String organizerName;
  final String imageUrl; // NEW
  final List<String> thingsToCarry;   // NEW
  final List<String> thingsProvided; // NEW

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.imageUrl,
    required this.thingsToCarry,
    required this.thingsProvided,
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
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      thingsToCarry: List<String>.from(data['thingsToCarry'] ?? []),
      thingsProvided: List<String>.from(data['thingsProvided'] ?? []),
    );
  }
}
