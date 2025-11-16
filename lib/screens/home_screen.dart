import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/publication.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0; // To track the selected tab

  // List of the screens to navigate to
  static final List<Widget> _widgetOptions = <Widget>[
    const PublicationsList(), // Extracted the main content into its own widget
    const EventsScreen(),
    const DocumentsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    // You should also navigate to the login screen after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
        scrolledUnderElevation: 0.0, // Prevents color change on scroll
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
            iconSize: 24,
            icon: const Icon(
              Icons.add,
              color: Color(0xFF1A1A1A), // Icon color from your CSS
            ),
            onPressed: () {
              // --- CORRECTION: Re-enabled navigation ---
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreatePublicationScreen()),
              );
            },
            tooltip: 'Créer une publication',
            hoverColor: Colors.transparent,
            splashColor: Colors.grey.withOpacity(0.2),
            highlightColor: Colors.grey.withOpacity(0.1),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.withOpacity(0.3),
            height: 1.0,
          ),
        ),
      )
          : null,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // --- START: NEW FLOATING ACTION BUTTON ---
      // This button is only shown on the home screen (index 0)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          // TODO: Define the action for this button, e.g.,
          print("Floating Action Button Pressed!");
        },
        backgroundColor: const Color(0xFF2590F4), // background from CSS
        elevation: 4.0, // A subtle shadow
        hoverColor: const Color(0xFF095DAC), // hover color from CSS
        splashColor: const Color(0xFF074885), // pressed color from CSS
        shape: const CircleBorder(), // border-radius: 9999px from CSS
        child: const Icon(
          Icons.add, // Example icon, change as needed
          color: Colors.white, // color from CSS
          size: 24.0, // icon size from CSS
        ),
      )
          : null,
      // --- END: NEW FLOATING ACTION BUTTON ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
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
        ),
      ),
    );
  }
}

class PublicationsList extends StatelessWidget {
  const PublicationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('publications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.feed,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune publication pour le moment',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Soyez le premier à partager !',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final publications = snapshot.data!.docs.map((doc) {
          return Publication.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            return _buildPublicationCard(publications[index], context);
          },
        );
      },
    );
  }

  Widget _buildPublicationCard(Publication publication, BuildContext context) {
    // Check if the file is an image based on file extension
    bool isImageFile(String? fileName) {
      if (fileName == null) return false;
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final lowerFileName = fileName.toLowerCase();
      return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
    }

    // Function to show image in full screen
    void _showFullScreenImage(String imageUrl, String fileName) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenImage(
            imageUrl: imageUrl,
            fileName: fileName,
          ),
        ),
      );
    }

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
            // Author info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(publication.authorName),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      publication.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.authorName,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (publication.content.isNotEmpty)
              Column(
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
              ),

            // Image display (if file is an image)
            if (publication.fileUrl != null && publication.fileName != null && isImageFile(publication.fileName))
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showFullScreenImage(publication.fileUrl!, publication.fileName!);
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
              ),

            // Document file attachment (if file is NOT an image)
            if (publication.fileUrl != null && publication.fileName != null && !isImageFile(publication.fileName))
              Column(
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
                        // File type icon
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
                        // File info
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
                            // TODO: Implement file download
                            print('Download file: ${publication.fileUrl}');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Stats row
            Container(
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
                  // Like count
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        publication.likes.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Comment count
                  Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        publication.comments.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Share icon
                  Icon(
                    Icons.share,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'Document PDF';
      case 'doc':
      case 'docx':
        return 'Document Word';
      case 'ppt':
      case 'pptx':
        return 'Présentation PowerPoint';
      case 'xls':
      case 'xlsx':
        return 'Feuille de calcul Excel';
      case 'txt':
        return 'Fichier texte';
      default:
        return 'Fichier $extension';
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement download
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, color: Colors.white, size: 50),
              );
            },
          ),
        ),
      ),
    );
  }
}