// screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _userService.getCurrentUser().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.displayName ?? '';
          _bioController.text = user.bio ?? 'Passionné(e) par l\'apprentissage automatique et l\'éthique de l\'IA...';
          _majorController.text = user.major ?? '';
          _emailController.text = user.email;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? newPhotoUrl;
      if (_selectedImage != null) {
        newPhotoUrl = await StorageService.uploadProfileImage(_selectedImage!, _currentUser!.uid);
      }

      await _userService.updateProfile(
        uid: _currentUser!.uid,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        major: _majorController.text.trim(),
      );

      if (newPhotoUrl != null) {
        await _userService.updateProfilePhoto(_currentUser!.uid, newPhotoUrl);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un nouveau mot de passe.')));
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _userService.changePassword(_newPasswordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe modifié avec succès!')));
        _newPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _majorController.dispose();
    _newPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Custom icon widget with exact CSS styling
  Widget _buildCustomIcon(IconData icon) {
    return Positioned(
      top: 28, // position: absolute; top: 28px;
      left: 16, // left: 16px;
      child: Container(
        width: 24, // width: 24px;
        height: 24, // height: 24px;
        child: Icon(
          icon,
          size: 24, // 24px size
          color: const Color(0xFF2590F4), // fill: #2590F4FF;
        ),
      ),
    );
  }

  // Helper method to create a styled TextFormField with custom icon
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Stack(
      children: [
        Container(
          height: maxLines > 1 ? null : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              labelText: labelText,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              alignLabelWithHint: maxLines > 1,
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(
                56, // Left padding to make space for icon
                maxLines > 1 ? 20 : 16,
                16,
                maxLines > 1 ? 20 : 16,
              ),
              labelStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        _buildCustomIcon(icon),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Modifier le profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2590F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfilePhotoSection(),
              const SizedBox(height: 32),
              _buildSectionContainer(
                title: 'Informations personnelles',
                child: _buildPersonalInfoSection(),
              ),
              const SizedBox(height: 32),
              _buildSectionContainer(
                title: 'Sécurité',
                child: _buildSecuritySection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null) as ImageProvider?,
              child: _selectedImage == null && (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                  ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                  : null,
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2590F4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  onPressed: _pickImage,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        _buildTextFormField(
          controller: _nameController,
          labelText: 'Nom complet',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Veuillez entrer votre nom';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _emailController,
          labelText: 'Email',
          icon: Icons.email_outlined,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _majorController,
          labelText: 'Filière/Spécialité',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _bioController,
          labelText: 'Bio',
          icon: Icons.edit_note_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Nouveau mot de passe',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(56, 16, 16, 16),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildCustomIcon(Icons.lock_outline),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2590F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : const Text(
                'Changer le mot de passe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ],
    );
  }
}