// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';
import '../../features/leaderboard/models/leaderboard_entry_model.dart';
import '../../features/chat/models/chat_message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // GET a real-time stream of all events with optional category + search query filter
  Stream<List<Event>> getEventsStream({String? category, String? searchQuery}) {
    Query query = _db
        .collection('events')
        .where('status', isEqualTo: 'approved');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      query = query
          .where('title_lowercase', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where(
            'title_lowercase',
            isLessThanOrEqualTo: '$lowerCaseQuery\uf8ff',
          );
    }

    return query.snapshots().map((snapshot) {
      var events = snapshot.docs.map((doc) {
        return Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Always sort the results by date inside the app (client-side)
      events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

      return events;
    });
  }

  // GET a stream for the featured events
  Stream<List<Event>> getFeaturedEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var events = snapshot.docs.map((doc) {
            return Event.fromMap(doc.id, doc.data());
          }).toList();

          // Sort the featured events by date inside the app
          events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

          return events.take(3).toList(); // Take the first 3 after sorting
        });
  }

  // ADD a new event with all details
  Future<void> addEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required String category,
    required String organizerId,
    required String organizerName,
    required String imageUrl,
    required List<String> thingsToCarry,
    required List<String> thingsProvided,
  }) async {
    try {
      await _db.collection('events').add({
        'title': title,
        'title_lowercase': title.toLowerCase(),
        'description': description,
        'location': location,
        'eventDate': Timestamp.fromDate(eventDate),
        'category': category,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'imageUrl': imageUrl,
        'thingsToCarry': thingsToCarry,
        'thingsProvided': thingsProvided,
        'status': 'pending',
        'isFeatured': false,
      });
      print("Event added successfully! Awaiting approval.");
    } catch (e) {
      print("Error adding event: $e");
    }
  }

  // UPDATE an existing event
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      if (data['eventDate'] is DateTime) {
        data['eventDate'] = Timestamp.fromDate(data['eventDate']);
      }
      if (data.containsKey('title')) {
        data['title_lowercase'] = (data['title'] as String).toLowerCase();
      }
      await _db.collection('events').doc(eventId).update(data);
      print("Event updated successfully!");
    } catch (e) {
      print("Error updating event: $e");
    }
  }

  // GET a stream for a single event
  Stream<Event> getEventStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snapshot) => Event.fromMap(snapshot.id, snapshot.data()!));
  }

  // UPLOAD an event image to Firebase Storage
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      String path = 'event_images/$fileName';
      Reference storageRef = _storage.ref().child(path);
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // DELETE an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.collection('events').doc(eventId).delete();
      print("Event deleted successfully!");
    } catch (e) {
      print("Error deleting event: $e");
    }
  }

  // JOIN an event (RSVP)
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      final docId = '$userId-$eventId';
      await _db.collection('rsvps').doc(docId).set({
        'eventId': eventId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error joining event: $e");
    }
  }

  // LEAVE an event
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      final docId = '$userId-$eventId';
      await _db.collection('rsvps').doc(docId).delete();
    } catch (e) {
      print("Error leaving event: $e");
    }
  }

  // CHECK if a user has joined an event
  Stream<bool> hasUserJoined(String eventId, String userId) {
    final docId = '$userId-$eventId';
    return _db
        .collection('rsvps')
        .doc(docId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // GET leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboardData() async {
    try {
      final rsvpSnapshot = await _db.collection('rsvps').get();
      final Map<String, int> userEventCounts = {};
      for (var doc in rsvpSnapshot.docs) {
        final userId = doc.data()['userId'] as String;
        userEventCounts[userId] = (userEventCounts[userId] ?? 0) + 1;
      }
      if (userEventCounts.isEmpty) return [];
      final usersSnapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: userEventCounts.keys.toList())
          .get();
      final usersMap = {for (var doc in usersSnapshot.docs) doc.id: doc.data()};
      List<LeaderboardEntry> leaderboard = [];
      userEventCounts.forEach((userId, count) {
        if (usersMap.containsKey(userId)) {
          leaderboard.add(
            LeaderboardEntry(
              userId: userId,
              userName: usersMap[userId]!['displayName'] ?? 'Anonymous',
              photoUrl: usersMap[userId]!['photoUrl'] ?? '',
              eventCount: count,
            ),
          );
        }
      });
      leaderboard.sort((a, b) => b.eventCount.compareTo(a.eventCount));
      return leaderboard;
    } catch (e) {
      print("Error getting leaderboard data: $e");
      return [];
    }
  }

  // GET count of events a user has joined
  Future<int> getUserEventCount(String userId) async {
    try {
      final countQuery = _db
          .collection('rsvps')
          .where('userId', isEqualTo: userId)
          .count();
      final snapshot = await countQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Error getting user event count: $e");
      return 0;
    }
  }

  // GET a stream of chat messages for a specific event
  Stream<List<ChatMessage>> getChatMessagesStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()))
              .toList(),
        );
  }

  // SEND a chat message
  Future<void> sendMessage(String eventId, ChatMessage message) async {
    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // GET a stream of events a user has joined
  Stream<List<Event>> getJoinedEventsStream(String userId) {
    return _db
        .collection('rsvps')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];
          final eventIds = snapshot.docs
              .map((doc) => doc['eventId'] as String)
              .toList();
          final eventDocs = await _db
              .collection('events')
              .where(FieldPath.documentId, whereIn: eventIds)
              .get();
          return eventDocs.docs
              .map((doc) => Event.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // UPLOAD a profile picture
  Future<String?> uploadProfilePicture({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      String path = 'profile_pictures/$userId.png';
      Reference storageRef = _storage.ref().child(path);
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  // UPDATE a user's photo URL in Firestore
  Future<void> updateUserPhotoUrl(String userId, String photoUrl) async {
    try {
      await _db.collection('users').doc(userId).update({'photoUrl': photoUrl});
    } catch (e) {
      print("Error updating user photo URL: $e");
    }
  }

  // GET a single user's data
  Future<DocumentSnapshot> getUser(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  // GET a stream of a single user's data
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // --- ADMIN METHODS ---

  Stream<List<Event>> getPendingEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Event.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  Future<void> approveEvent(String eventId) async {
    await _db.collection('events').doc(eventId).update({'status': 'approved'});
  }

  Future<void> setFeaturedStatus(String eventId, bool isFeatured) async {
    await _db.collection('events').doc(eventId).update({
      'isFeatured': isFeatured,
    });
  }

  Stream<List<Event>> getApprovedEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Event.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }
}
