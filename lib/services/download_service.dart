import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';

class DownloadService {
  static Future<void> downloadFile(String url, String fileName, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );

      print('Downloading from: $url');
      print('File name: $fileName');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('File downloaded successfully, saving...');

        // Get downloads directory
        final directory = await getExternalStorageDirectory();
        print('Storage directory: ${directory?.path}');

        if (directory == null) {
          throw Exception('Could not access storage directory');
        }

        // Create CampusConnect folder
        final campusConnectDir = Directory('${directory.path}/CampusConnect');
        if (!await campusConnectDir.exists()) {
          await campusConnectDir.create(recursive: true);
        }

        final filePath = '${campusConnectDir.path}/$fileName';
        final file = File(filePath);

        // Save the file
        await file.writeAsBytes(response.bodyBytes);
        print('File saved to: $filePath');

        // Try to open the file
        final result = await OpenFile.open(filePath);
        print('Open file result: ${result.type}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier téléchargé avec succès!'),
            duration: Duration(seconds: 3),
          ),
        );

      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<void> downloadImage(String imageUrl, String fileName, BuildContext context) async {
    await downloadFile(imageUrl, fileName, context);
  }
}