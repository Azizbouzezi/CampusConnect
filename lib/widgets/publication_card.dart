import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/publication.dart';

class PublicationCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthorHeader(),
            const SizedBox(height: 16),
            if (publication.content.isNotEmpty) _buildContent(),
            if (publication.fileUrl != null) _buildFileAttachment(context),
            _buildActionsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Row(
      children: [
        _buildUserAvatar(),
        const SizedBox(width: 12),
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(publication.authorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String? photoURL;
        String displayName = publication.authorName;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          photoURL = userData?['photoURL'];
          displayName = userData?['displayName'] ?? publication.authorName;
        }

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: photoURL == null ? _getAvatarColor(displayName) : null,
            borderRadius: BorderRadius.circular(20),
            image: photoURL != null
                ? DecorationImage(
              image: NetworkImage(photoURL!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: photoURL == null
              ? Center(
            child: Text(
              displayName[0].toUpperCase(),
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

  Widget _buildUserInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(publication.authorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String displayName = publication.authorName;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          displayName = userData?['displayName'] ?? publication.authorName;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Text(
              _formatTimeAgo(publication.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Text(
          publication.content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFileAttachment(BuildContext context) {
    bool isImageFile(String? fileName) {
      if (fileName == null) return false;
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final lowerFileName = fileName.toLowerCase();
      return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
    }

    if (isImageFile(publication.fileName)) {
      return _buildImageAttachment(context);
    } else {
      return _buildDocumentAttachment(context);
    }
  }

  Widget _buildImageAttachment(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to full screen image
          },
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                publication.fileUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDocumentAttachment(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.fileName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFileType(publication.fileName!),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () {
                  // Download logic
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildLikeButton(),
          const SizedBox(width: 20),
          _buildCommentButton(),
          const Spacer(),
          const Icon(
            Icons.share,
            color: Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: onLike,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publications')
            .doc(publication.id)
            .snapshots(),
        builder: (context, snapshot) {
          final currentUser = FirebaseAuth.instance.currentUser;
          final isLiked = snapshot.hasData &&
              snapshot.data!.exists &&
              (snapshot.data!.data() as Map<String, dynamic>)['likedBy']?.contains(currentUser?.uid) == true;

          final likes = snapshot.hasData && snapshot.data!.exists
              ? (snapshot.data!.data() as Map<String, dynamic>)['likes'] ?? publication.likes
              : publication.likes;

          return Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                color: isLiked ? Colors.red : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                likes.toString(),
                style: TextStyle(
                  color: isLiked ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentButton() {
    return GestureDetector(
      onTap: onComment,
      child: Row(
        children: [
          const Icon(
            Icons.mode_comment_outlined,
            color: Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 6),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publications')
                .doc(publication.id)
                .snapshots(),
            builder: (context, snapshot) {
              final comments = snapshot.hasData && snapshot.data!.exists
                  ? (snapshot.data!.data() as Map<String, dynamic>)['comments'] ?? publication.comments
                  : publication.comments;

              return Text(
                comments.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';

    return 'Le ${date.day}/${date.month}/${date.year}';
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf': return 'Document PDF';
      case 'doc': case 'docx': return 'Document Word';
      case 'ppt': case 'pptx': return 'Présentation PowerPoint';
      case 'xls': case 'xlsx': return 'Feuille de calcul Excel';
      case 'txt': return 'Fichier texte';
      default: return 'Fichier $extension';
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    final index = name.length % colors.length;
    return colors[index];
  }
}