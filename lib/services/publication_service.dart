// services/publication_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../models/publication.dart';

class PublicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Toggle like on publication
  Future<void> toggleLike(String publicationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final publicationRef = _firestore.collection('publications').doc(publicationId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(publicationRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(user.uid);

      if (isLiked) {
        // Unlike
        likedBy.remove(user.uid);
        transaction.update(publicationRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        // Like
        likedBy.add(user.uid);
        transaction.update(publicationRef, {
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    });
  }

  // Add comment to publication
  Future<void> addComment(String publicationId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user.uid,
      authorName: user.displayName ?? 'Utilisateur Anonyme',
      content: content,
      timestamp: DateTime.now(),
    );

    final publicationRef = _firestore.collection('publications').doc(publicationId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(publicationRef);
      if (!snapshot.exists) return;

      // Get current comments
      final data = snapshot.data()!;
      final commentList = List<Map<String, dynamic>>.from(data['commentList'] ?? []);

      // Add new comment
      commentList.add(comment.toMap());

      // Update publication
      transaction.update(publicationRef, {
        'comments': FieldValue.increment(1),
        'commentList': commentList,
      });
    });
  }

  // Get comments stream for a publication
  Stream<List<Comment>> getComments(String publicationId) {
    return _firestore
        .collection('publications')
        .doc(publicationId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data()!;
      final commentList = data['commentList'] as List<dynamic>? ?? [];
      return commentList.map((commentData) {
        return Comment.fromMap(commentData as Map<String, dynamic>);
      }).toList();
    });
  }
}