import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  final String? imageUrl;
  final bool isRegistrationOpen;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> registeredUsers;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    this.imageUrl,
    required this.isRegistrationOpen,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.registeredUsers = const [],
  });

  factory Event.fromMap(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      isRegistrationOpen: data['isRegistrationOpen'] ?? true,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'isRegistrationOpen': isRegistrationOpen,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'registeredUsers': registeredUsers,
    };
  }
}