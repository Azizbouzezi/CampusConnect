// services/storage_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class StorageService {
  static final SupabaseClient client = SupabaseClient(
    'https://binhttdxdxtvnbnksvsd.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpbmh0dGR4ZHh0dm5ibmtzdnNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyODI2MDIsImV4cCI6MjA3ODg1ODYwMn0.wmltXOzW2CF2qmDBBtb4I7uTcKsoGi9g7dN15uNWLyA',
  );

  static Future<Map<String, dynamic>> uploadFile(File file, String fileName, String userId) async {
    try {
      // Get file size before uploading
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      // Create user-specific folder
      final filePath = 'users/$userId/publications/$fileName';

      // Upload file to Supabase
      await client.storage
          .from('campus-connect-files')
          .uploadBinary(filePath, await file.readAsBytes());

      // Get public URL
      final String publicUrl = client.storage
          .from('campus-connect-files')
          .getPublicUrl(filePath);

      print('File uploaded successfully: $publicUrl');
      print('File size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      // Return both URL and file size
      return {
        'fileUrl': publicUrl,
        'fileSize': fileSizeInMB,
      };
    } catch (e) {
      print('Detailed upload error: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  static Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'users/$userId/profile/$fileName';

      // Upload to Supabase
      await client.storage
          .from('campus-connect-files')
          .uploadBinary(filePath, await imageFile.readAsBytes());

      // Get public URL
      final String publicUrl = client.storage
          .from('campus-connect-files')
          .getPublicUrl(filePath);

      print('Profile image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Error uploading profile image: $e');
    }
  }

  // Method to get file size for existing files (optional)
  static Future<double?> getFileSize(String fileUrl) async {
    try {
      // For Supabase, you might need to make a HEAD request to get file metadata
      // This is a simplified version - you may need to adjust based on Supabase's API
      final response = await client.storage
          .from('campus-connect-files')
          .download(fileUrl.split('/').last);

      // Note: This downloads the file to get size, which isn't efficient
      // For production, you might want to store file sizes in a database
      return response.length / (1024 * 1024);
    } catch (e) {
      print('Error getting file size: $e');
      return null;
    }
  }

  // Method to delete file (optional - for future use)
 // static Future<void> deleteFile(String filePath) async {
  //  try {
    //  await client.storage
      //    .from('campus-connect-files')
        //  .remove([filePath]);
     // print('File deleted successfully: $filePath');
   // } catch (e) {
    //  print('Error deleting file: $e');
     // throw Exception('Error deleting file: $e');
   // }
 // }
}