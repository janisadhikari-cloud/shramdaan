import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Event>> getEvents() async {
    try {
      CollectionReference eventsRef = _db.collection('events');
      QuerySnapshot snapshot = await eventsRef.get();

      // NEW: Add these detailed print statements
      print("Firestore query completed successfully.");
      print("Number of documents found: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        print("Raw data of first document: ${snapshot.docs.first.data()}");
      }

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Event> events = snapshot.docs.map((doc) {
        return Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      return events;
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }
}