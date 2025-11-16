// services/document_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Document>> getDocuments() {
    return _firestore
        .collection('publications')
        .where('fileUrl', isNotEqualTo: null) // Only publications with files
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Document.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Filter only non-image documents
  Stream<List<Document>> getNonImageDocuments() {
    return _firestore
        .collection('publications')
        .where('fileUrl', isNotEqualTo: null)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final fileName = data['fileName']?.toString().toLowerCase() ?? '';

        // Filter out image files
        final isImage = fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif');

        if (!isImage) {
          return Document.fromMap(data, doc.id);
        }
        return null;
      }).where((doc) => doc != null).cast<Document>().toList();
    });
  }

  // Search documents
  Stream<List<Document>> searchDocuments(String query) {
    return _firestore
        .collection('publications')
        .where('fileUrl', isNotEqualTo: null)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final fileName = data['fileName']?.toString().toLowerCase() ?? '';

        // Filter out image files
        final isImage = fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif');

        if (!isImage) {
          final document = Document.fromMap(data, doc.id);
          // Filter by search query
          if (query.isEmpty ||
              document.title.toLowerCase().contains(query.toLowerCase()) ||
              document.author.toLowerCase().contains(query.toLowerCase())) {
            return document;
          }
        }
        return null;
      }).where((doc) => doc != null).cast<Document>().toList();
    });
  }
}