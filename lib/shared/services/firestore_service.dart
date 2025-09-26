import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';
import '../../features/leaderboard/models/leaderboard_entry_model.dart';
import '../../features/chat/models/chat_message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------
  // EVENT METHODS
  // ---------------------------

  // GET a real-time stream of all events with optional category + search query filter
  Stream<List<Event>> getEventsStream({String? category, String? searchQuery}) {
    Query query = _db.collection('events');
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
    } else {
      query = query.orderBy('eventDate', descending: false);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => Event.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  // ADD a new event
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
      });
      print("Event added successfully!");
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

  // GET featured events (up to 3)
  Stream<List<Event>> getFeaturedEventsStream() {
    return _db
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('eventDate', descending: false)
        .limit(3)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Event.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
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

  // ---------------------------
  // RSVP METHODS
  // ---------------------------

  // JOIN an event
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

  // ---------------------------
  // LEADERBOARD
  // ---------------------------

  // UPDATED: Now fetches photoUrl for the leaderboard
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

  // ---------------------------
  // CHAT METHODS
  // ---------------------------

  // GET chat messages
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

  // SEND chat message
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

  // ---------------------------
  // USER-RELATED METHODS
  // ---------------------------

  // GET events a user has joined
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

  // UPLOAD an event image
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

  // ---------------------------
  // PROFILE PICTURE METHODS
  // ---------------------------

  // Upload a profile picture
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

  // Update a user's photo URL in Firestore
  Future<void> updateUserPhotoUrl(String userId, String photoUrl) async {
    try {
      await _db.collection('users').doc(userId).update({'photoUrl': photoUrl});
    } catch (e) {
      print("Error updating user photo URL: $e");
    }
  }
}
