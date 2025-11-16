import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/publication.dart'; // Make sure you have this model

// Main Profile Screen Widget
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Aucun utilisateur connecté."))
          : buildProfileView(),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier le profil'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                onTap: () {
                  Navigator.pop(context);
                  _signOut(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // If you have a login screen, you can navigate to it here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
      );
    }
  }

  // Builds the main scrolling view of the profile
  Widget buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF6A1B9A),
            child: currentUser!.photoURL != null
                ? ClipOval(
              child: Image.network(
                currentUser!.photoURL!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
                : const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // User Name
          Text(
            currentUser!.displayName?.toUpperCase() ?? currentUser!.email?.split('@').first.toUpperCase() ?? 'UTILISATEUR',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // User's Email
          Text(
            currentUser!.email ?? 'Email non disponible',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          // User Stats
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('publications')
                .where('authorId', isEqualTo: currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int publicationCount = 0;
              int totalLikes = 0;

              if (snapshot.hasData) {
                publicationCount = snapshot.data!.docs.length;
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalLikes += (data['likes'] ?? 0) as int;
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(publicationCount.toString(), 'Publications'),
                  const SizedBox(width: 20),
                  _buildStatItem(totalLikes.toString(), 'J\'aime'),
                  const SizedBox(width: 20),
                  _buildStatItem('0', 'Abonnés'), // You can implement followers later
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Bio Section
          const Text(
            'Passionné(e) par l\'apprentissage automatique et l\'éthique de l\'IA. Cherche à collaborer sur des projets innovants et à partager mes connaissances avec la communauté Campus Connect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              // "Modifier le profil" Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement edit profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2590F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Modifier le profil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              // "Partager" Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement share profile
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Partager', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // "Mes Publications" Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mes Publications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User's Publications List
          _buildUserPublications(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Build the list of user's publications
  // Build the list of user's publications
  Widget _buildUserPublications() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('publications')
          .where('authorId', isEqualTo: currentUser!.uid)
      // Remove this line temporarily until index is created:
      // .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              Icon(
                Icons.feed_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune publication',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Commencez à partager vos premières publications !',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        // Sort manually on the client side
        final publications = snapshot.data!.docs.map((doc) {
          return Publication.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Manual sorting by timestamp
        publications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            return _buildPublicationCard(publications[index]);
          },
        );
      },
    );
  }

  // A widget for displaying a publication card
  Widget _buildPublicationCard(Publication publication) {
    bool isImageFile(String? fileName) {
      if (fileName == null) return false;
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final lowerFileName = fileName.toLowerCase();
      return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Publication content
          if (publication.content.isNotEmpty)
            Column(
              children: [
                Text(
                  publication.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          // Image preview
          if (publication.fileUrl != null && publication.fileName != null && isImageFile(publication.fileName))
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
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
                          child: const Icon(Icons.error_outline, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          // File attachment
          if (publication.fileUrl != null && publication.fileName != null && !isImageFile(publication.fileName))
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          publication.fileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          // Publication stats and date
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    publication.likes.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    publication.comments.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(publication.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
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
}