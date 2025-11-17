// services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user data - UPDATED
  Stream<AppUser> getCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(AppUser(uid: '', email: ''));

      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .asyncMap((snapshot) async {
        if (!snapshot.exists) {
          // Create user document if it doesn't exist
          final newUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
            bio: null,
            major: null,
            createdAt: DateTime.now(),
          );
          await _createUserDocument(newUser);
          return newUser;
        } else {
          return AppUser.fromMap(snapshot.data()!, snapshot.id);
        }
      });
    });
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
  }

  // Update user profile
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? major,
  }) async {
    final updateData = <String, dynamic>{};

    if (displayName != null) updateData['displayName'] = displayName;
    if (bio != null) updateData['bio'] = bio;
    if (major != null) updateData['major'] = major;

    await _firestore
        .collection('users')
        .doc(uid)
        .update(updateData);

    // Update Firebase Auth display name
    if (displayName != null) {
      await _auth.currentUser!.updateDisplayName(displayName);
    }
  }

  // Update profile photo
  Future<void> updateProfilePhoto(String uid, String photoURL) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'photoURL': photoURL});

    // Update Firebase Auth photo URL
    await _auth.currentUser!.updatePhotoURL(photoURL);
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // Change email
  Future<void> changeEmail(String newEmail) async {
    await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
  }

  // Ensure user document exists - NEW METHOD
  Future<void> ensureUserDocumentExists(String uid, String email, String? displayName, String? photoURL) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'bio': null,
        'major': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}