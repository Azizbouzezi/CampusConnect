// models/document.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  final String id;
  final String title;
  final String fileType;
  final DateTime uploadDate;
  final String author;
  final double size;
  final String fileUrl;
  final String fileName;
  final String authorId;

  Document({
    required this.id,
    required this.title,
    required this.fileType,
    required this.uploadDate,
    required this.author,
    required this.size,
    required this.fileUrl,
    required this.fileName,
    required this.authorId,
  });

  factory Document.fromMap(Map<String, dynamic> data, String id) {
    return Document(
      id: id,
      title: data['fileName'] ?? 'Document sans titre',
      fileType: _getFileTypeFromExtension(data['fileName'] ?? ''),
      uploadDate: (data['timestamp'] as Timestamp).toDate(),
      author: data['authorName'] ?? 'Utilisateur inconnu',
      size: (data['fileSize'] ?? 0).toDouble(),
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      authorId: data['authorId'] ?? '',
    );
  }

  static String _getFileTypeFromExtension(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'PDF';
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
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image';
      default:
        return 'Fichier $extension';
    }
  }
}