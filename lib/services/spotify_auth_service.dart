import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyAuthService {
  final String clientId = 'ad0911afa57949bba362003f601876b2';
  final String clientSecret = ''; // To be filled by user if needed
  final String redirectUri = 'meowsic://callback';

  Future<Map<String, dynamic>> getToken(String code) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        if (clientSecret.isNotEmpty)
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        if (clientSecret.isEmpty) 'client_id': clientId,
      },
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        if (clientSecret.isNotEmpty)
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        if (clientSecret.isEmpty) 'client_id': clientId,
      },
    );

    return jsonDecode(response.body);
  }
}
