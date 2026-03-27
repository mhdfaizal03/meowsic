import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyApiService {
  final String baseUrl = "https://api.spotify.com/v1";

  Future<dynamic> getRequest(String endpoint, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 401) {
      throw Exception("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("API Error: ${response.statusCode} ${response.body}");
    }

    return jsonDecode(response.body);
  }

  Future<dynamic> putRequest(String endpoint, String token, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      throw Exception("Token expired");
    }

    return response.statusCode;
  }
}
