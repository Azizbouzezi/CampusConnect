import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/toxicity_service.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  final _textController = TextEditingController();
  final int _maxLength = 500;
  bool _isLoading = false;
  bool _isCheckingToxicity = false;
  File? _selectedFile;
  String? _fileName;

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Vous devez être connecté.");
      return;
    }

    if (_textController.text.isEmpty && _selectedFile == null) {
      _showSnackBar("Veuillez ajouter du contenu ou un fichier.");
      return;
    }

    // 🔍 AI CONTENT MODERATION
    if (_textController.text.isNotEmpty) {
      setState(() {
        _isCheckingToxicity = true;
      });

      try {
        bool isToxic = await ToxicityService.isTextToxic(_textController.text);

        if (isToxic) {
          _showToxicContentDialog();
          return; // Stop publication
        }
      } catch (e) {
        print('❌ Moderation error: $e');
        _showSnackBar("System error. Publication allowed by default.");
        // Continue on error (fail-safe)
      } finally {
        setState(() {
          _isCheckingToxicity = false;
        });
      }
    }

    // ✅ CONTENT IS APPROVED
    setState(() {
      _isLoading = true;
    });

    try {
      String? fileUrl;
      String? fileName;
      double? fileSize;

      // Upload file if exists
      if (_selectedFile != null) {
        fileName = _fileName;
        final uploadResult = await StorageService.uploadFile(
            _selectedFile!, _fileName!, user.uid);
        fileUrl = uploadResult['fileUrl'];
        fileSize = uploadResult['fileSize'];
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('publications').add({
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Utilisateur Anonyme', // Your original naming
        'content': _textController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'likes': 0,
        'comments': 0,
        'likedBy': [],
        'aiModerated': true, // Added by your friend
        'moderationDate': FieldValue.serverTimestamp(), // Added by your friend
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("✅ Publication ajoutée avec succès !");
      }
    } catch (e) {
      print("Error publishing: $e");
      _showSnackBar("Erreur lors de la publication : $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showToxicContentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Contenu inapproprié détecté',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notre système a détecté un langage inapproprié dans votre publication.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '🔍 Pour respecter la communauté, veuillez modifier votre texte.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _textController.clear();
                _showSnackBar("Texte effacé. Vous pouvez recommencer.");
              },
              child: const Text(
                'Tout effacer',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _textController.selection = TextSelection.collapsed(
                    offset: _textController.text.length);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier mon texte'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedFile = File(pickedImage.path);
        _fileName = pickedImage.path.split('/').last;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPublishEnabled = (_textController.text.isNotEmpty || _selectedFile != null) &&
        !_isLoading &&
        !_isCheckingToxicity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Créer une publication',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isCheckingToxicity)
            Container(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Analyse...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton(
              onPressed: isPublishEnabled ? _publish : null,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2590F4),
                disabledForegroundColor: const Color(0xFF2590F4).withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                'Publier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contenu de la publication',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    maxLength: _maxLength,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Exprimez-vous, partagez vos idées ou une annonce importante...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // AI Protection Indicator (from friend)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.security, color: Colors.green.shade700, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Protégé par IA',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Character counter (from your version)
                        Text(
                          '${_textController.text.length}/$_maxLength caractères',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ajouter des médias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMediaCard(
                      icon: Icons.image_outlined,
                      title: 'Images',
                      subtitle: '(photos, graphiques)',
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMediaCard(
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      subtitle: '(PDF, Word, PPT)',
                      onTap: _pickDocument,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null) _buildSelectedFileChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF4F4F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade700),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2590F4),
              side: const BorderSide(color: Color(0xFF2590F4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _fileName ?? 'Fichier sélectionné',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _removeFile,
            child: const Icon(Icons.close, color: Colors.blue, size: 18),
          ),
        ],
      ),
    );
  }
}