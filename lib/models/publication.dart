import 'package:cloud_firestore/cloud_firestore.dart';

class Publication {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> likedBy;

  Publication({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.likedBy,
  });

  factory Publication.fromMap(Map<String, dynamic> data, String id) {
    return Publication(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      content: data['content'] ?? '',
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }
}