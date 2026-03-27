import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class PhishService {
  final String baseUrl = "https://phish.in/api/v1";

  Future<List<Song>> searchTracks(String query) async {
    try {
      // Phish.in v1 search returns a mix of data
      final response = await http.get(
        Uri.parse("$baseUrl/search/${Uri.encodeComponent(query)}"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List results = data['data']['tracks'] ?? [];
          return results.map((t) => Song(
            id: "phish:${t['id']}",
            title: t['title'] ?? 'Unknown Phish Track',
            image: "https://phish.in/favicon.ico", // Default icon for Phish.in
            source: 'phish',
          )).toList();
        }
      }
    } catch (e) {
      print("Phish search error: $e");
    }
    return [];
  }

  Future<String> fetchStreamUrl(String trackId) async {
    try {
      final cleanId = trackId.replaceFirst("phish:", "");
      final response = await http.get(
        Uri.parse("$baseUrl/tracks/$cleanId.json"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['mp3'] ?? "";
        }
      }
    } catch (e) {
      print("Phish stream error: $e");
    }
    return "";
  }
}
