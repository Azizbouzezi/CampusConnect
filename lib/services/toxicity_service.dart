import 'dart:convert';
import 'package:http/http.dart' as http;

class ToxicityService {
  static const String _API_KEY = 'AIzaSyCzceBuZypmEPKOhCZm_iEVGpx74xx7dlg';
  static const String _API_URL = 'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze';

  static Future<bool> isTextToxic(String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_API_URL?key=$_API_KEY'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment': {'text': text},
          'languages': ['fr'],
          'requestedAttributes': {
            'TOXICITY': {},
            'SEVERE_TOXICITY': {},
            'INSULT': {},
            'PROFANITY': {},
            'THREAT': {},
            'IDENTITY_ATTACK': {},
          },
          'doNotStore': true,
        }),
      );

      print('Statut HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final attributes = jsonResponse['attributeScores'];
        final scores = {
          'Toxicité': attributes['TOXICITY']?['summaryScore']?['value'] ?? 0,
          'Toxicité sévère': attributes['SEVERE_TOXICITY']?['summaryScore']?['value'] ?? 0,
          'Insulte': attributes['INSULT']?['summaryScore']?['value'] ?? 0,
          'Grossièreté': attributes['PROFANITY']?['summaryScore']?['value'] ?? 0,
          'Menace': attributes['THREAT']?['summaryScore']?['value'] ?? 0,
          'Attaque personnelle': attributes['IDENTITY_ATTACK']?['summaryScore']?['value'] ?? 0,
        };
        print('Résultats analyse IA Perspective:');
        scores.forEach((category, score) {
          final percent = (score * 100).toStringAsFixed(1);
          print('   $category: $percent%');
        });

        // Prendre le score le plus élevé
        final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
        final maxCategory = scores.entries.firstWhere((entry) => entry.value == maxScore).key;

        print('Score maximum: $maxCategory - ${(maxScore * 100).toStringAsFixed(1)}%');

        // Décision basée sur le seuil (70%)
        const threshold = 0.7;
        final isToxic = maxScore > threshold;

        if (isToxic) {
          print('CONTENU TOXIQUE DÉTECTÉ - Publication BLOQUÉE');
          print('Raison: $maxCategory > ${(threshold * 100).toInt()}%');
        } else {
          print('CONTENU PROPRE - Publication AUTORISÉE');
        }

        return isToxic;

      } else {
        print('Erreur API Perspective (${response.statusCode}): ${response.body}');
        // En cas d'erreur API, on retourne false pour ne pas bloquer l'utilisateur
        return false;
      }
    } catch (e) {
      print('Erreur connexion Perspective API: $e');
      // En cas d'erreur réseau, on retourne false pour ne pas bloquer
      return false;
    }
  }
}