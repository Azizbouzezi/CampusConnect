import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/publication.dart';
import '../widgets/publication_card.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'create_publication_screen.dart';
import 'events_screen.dart';
import 'documents_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PublicationsList(),
    const EventsScreen(),
    const DocumentsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      scrolledUnderElevation: 0.0,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 75,
      title: Container(
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF1A1A1A), size: 24),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreatePublicationScreen()),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey.withOpacity(0.3), height: 1.0),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Événements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Documents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2590F4),
      unselectedItemColor: const Color(0xFF565D6D),
      selectedFontSize: 10.0,
      unselectedFontSize: 10.0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
      showUnselectedLabels: true,
      elevation: 0,
    );
  }
}

class PublicationsList extends StatelessWidget {
  const PublicationsList({super.key});

  Future<void> _toggleLike(String publicationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final publicationRef = FirebaseFirestore.instance.collection('publications').doc(publicationId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(publicationRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final isLiked = likedBy.contains(user.uid);

        if (isLiked) {
          likedBy.remove(user.uid);
          transaction.update(publicationRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': likedBy,
          });
        } else {
          likedBy.add(user.uid);
          transaction.update(publicationRef, {
            'likes': FieldValue.increment(1),
            'likedBy': likedBy,
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _addComment(String publicationId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = user.displayName ?? user.email?.split('@').first ?? 'Utilisateur';
    final comment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'authorId': user.uid,
      'authorName': displayName,
      'content': content,
      'timestamp': Timestamp.now(),
    };

    final publicationRef = FirebaseFirestore.instance.collection('publications').doc(publicationId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(publicationRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final commentList = List<Map<String, dynamic>>.from(data['commentList'] ?? []);
        commentList.add(comment);

        transaction.update(publicationRef, {
          'comments': FieldValue.increment(1),
          'commentList': commentList,
        });
      });
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  void _showCommentsBottomSheet(BuildContext context, Publication publication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          publication: publication,
          onAddComment: (comment) => _addComment(publication.id, comment),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final publications = snapshot.data!.docs.map((doc) {
          return Publication.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            return PublicationCard(
              publication: publications[index],
              onLike: () => _toggleLike(publications[index].id),
              onComment: () => _showCommentsBottomSheet(context, publications[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune publication pour le moment',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Soyez le premier à partager !',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}