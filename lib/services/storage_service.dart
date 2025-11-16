import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class StorageService {
  static final SupabaseClient client = SupabaseClient(
    'https://binhttdxdxtvnbnksvsd.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpbmh0dGR4ZHh0dm5ibmtzdnNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyODI2MDIsImV4cCI6MjA3ODg1ODYwMn0.wmltXOzW2CF2qmDBBtb4I7uTcKsoGi9g7dN15uNWLyA',
  );

  static Future<String> uploadFile(File file, String fileName, String userId) async {
    try {
      // Create user-specific folder
      final filePath = 'users/$userId/publications/$fileName';

      // Use the file directly with file.openRead()
      final fileStream = file.openRead();

      await client.storage
          .from('campus-connect-files')
          .uploadBinary(filePath, await file.readAsBytes());

      // Get public URL
      final String publicUrl = client.storage
          .from('campus-connect-files')
          .getPublicUrl(filePath);

      print('File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Detailed upload error: $e');
      throw Exception('Error uploading file: $e');
    }
  }
}