import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';

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
  File? _selectedFile;
  String? _fileName;

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez être connecté.")),
      );
      return;
    }

    if (_textController.text.isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter du contenu ou un fichier.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? fileUrl;
      String? fileName;
      double? fileSize;

      // Upload file to Supabase if exists
      if (_selectedFile != null) {
        fileName = _fileName;
        final uploadResult = await StorageService.uploadFile(_selectedFile!, _fileName!, user.uid);
        fileUrl = uploadResult['fileUrl'];
        fileSize = uploadResult['fileSize']; // Get the file size from upload result
      }

      // Store publication in Firestore
      await FirebaseFirestore.instance.collection('publications').add({
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Utilisateur Anonyme',
        'content': _textController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize, // Store the file size
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Publication ajoutée avec succès !")),
        );
      }
    } catch (e) {
      print("Error publishing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la publication : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final isPublishEnabled = _textController.text.isNotEmpty || _selectedFile != null;

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
          TextButton(
            onPressed: isPublishEnabled && !_isLoading ? _publish : null,
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
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_textController.text.length}/$_maxLength caractères',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
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
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
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
            onTap: () {
              setState(() {
                _selectedFile = null;
                _fileName = null;
              });
            },
            child: const Icon(Icons.close, color: Colors.blue, size: 18),
          ),
        ],
      ),
    );
  }
}