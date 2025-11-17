// widgets/comments_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/publication.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Publication publication;
  final Function(String) onAddComment;

  const CommentsBottomSheet({
    super.key,
    required this.publication,
    required this.onAddComment,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCommentsList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Text(
            'Commentaires',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publications')
          .doc(widget.publication.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Aucun commentaire'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final commentList = data['commentList'] as List<dynamic>? ?? [];

        if (commentList.isEmpty) {
          return const Center(child: Text('Aucun commentaire'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: commentList.length,
          itemBuilder: (context, index) {
            final comment = commentList[index] as Map<String, dynamic>;
            return _buildCommentItem(comment);
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF2590F4),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  widget.onAddComment(_commentController.text.trim());
                  _commentController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final timestamp = (comment['timestamp'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentAvatar(comment),
          const SizedBox(width: 12),
          Expanded(child: _buildCommentContent(comment, timestamp)),
        ],
      ),
    );
  }

  Widget _buildCommentAvatar(Map<String, dynamic> comment) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(comment['authorId'])
          .snapshots(),
      builder: (context, userSnapshot) {
        String? photoURL;
        String authorName = comment['authorName'];

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          photoURL = userData?['photoURL'];
          authorName = userData?['displayName'] ?? comment['authorName'];
        }

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: photoURL == null ? _getAvatarColor(authorName) : null,
            borderRadius: BorderRadius.circular(20),
            image: photoURL != null
                ? DecorationImage(image: NetworkImage(photoURL!), fit: BoxFit.cover)
                : null,
          ),
          child: photoURL == null
              ? Center(
            child: Text(
              authorName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
              : null,
        );
      },
    );
  }

  Widget _buildCommentContent(Map<String, dynamic> comment, DateTime timestamp) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(comment['authorId'])
          .snapshots(),
      builder: (context, userSnapshot) {
        String authorName = comment['authorName'];

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          authorName = userData?['displayName'] ?? comment['authorName'];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(comment['content'], style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(timestamp),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';

    return 'Le ${date.day}/${date.month}/${date.year}';
  }

  Color _getAvatarColor(String name) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    final index = name.length % colors.length;
    return colors[index];
  }
}