import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new event
  Future<void> createEvent({
    required String title,
    required String date,
    required String time,
    required String location,
    required String description,
    String? imageUrl,
    bool isRegistrationOpen = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('events').add({
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'isRegistrationOpen': isRegistrationOpen,
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email?.split('@').first ?? 'Utilisateur',
      'createdAt': FieldValue.serverTimestamp(),
      'registeredUsers': [],
    });
  }

  // Get all events
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Register for an event
  Future<void> registerForEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayUnion([user.uid]),
    });
  }

  // Unregister from an event
  Future<void> unregisterFromEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayRemove([user.uid]),
    });
  }

  // Check if user is registered for an event
  Future<bool> isUserRegistered(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return false;

    final event = Event.fromMap(eventDoc.data()!, eventDoc.id);
    return event.registeredUsers.contains(user.uid);
  }
}