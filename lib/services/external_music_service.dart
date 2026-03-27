import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class ExternalMusicService {
  static const String _workerUrl = "https://musicapi.x007.workers.dev";

  // Engines: gaama, seevn, hunjama, mtmusic, wunk
  static Future<List<Song>> search(String query, String engine) async {
    try {
      final response = await http.get(
        Uri.parse("$_workerUrl/search?q=${Uri.encodeComponent(query)}&searchEngine=$engine"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['response'] ?? [];
        return results.map((item) {
          return Song(
            id: "ext:${item['id']}", // Prefix for external
            title: item['title'] ?? "Unknown",
            image: item['img'] ?? "",
            source: engine,
          );
        }).toList();
      }
    } catch (e) {
      print("External search error ($engine): $e");
    }
    return [];
  }

  static Future<String> fetchStreamUrl(String id) async {
    try {
      final cleanId = id.replaceFirst("ext:", "");
      final response = await http.get(
        Uri.parse("$_workerUrl/fetch?id=${Uri.encodeComponent(cleanId)}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['response'];
        if (url != null && url.toString().startsWith("http")) {
          return url.toString();
        }
      }
    } catch (e) {
      print("External fetch error: $e");
    }
    return "";
  }

  static Future<String?> getLyrics(String id) async {
    try {
      final cleanId = id.replaceFirst("ext:", "");
      final response = await http.get(
        Uri.parse("$_workerUrl/lyrics?id=${Uri.encodeComponent(cleanId)}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // Might be HTML as per doc
      }
    } catch (e) {
      print("External lyrics error: $e");
    }
    return null;
  }
}
