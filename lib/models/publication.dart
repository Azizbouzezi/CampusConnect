// models/publication.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Publication {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final String? fileUrl;
  final String? fileName;
  final double? fileSize;
  final int likes;
  final int comments;
  final List<String> likedBy;
  final List<Map<String, dynamic>> commentList;

  Publication({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.likes,
    required this.comments,
    required this.likedBy,
    required this.commentList,
  });

  factory Publication.fromMap(Map<String, dynamic> data, String id) {
    return Publication(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Utilisateur inconnu',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: (data['fileSize'] ?? 0).toDouble(),
      likes: (data['likes'] ?? 0) as int,
      comments: (data['comments'] ?? 0) as int,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentList: List<Map<String, dynamic>>.from(data['commentList'] ?? []),
    );
  }

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}