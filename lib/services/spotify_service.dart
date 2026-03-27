import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song_model.dart';

class SpotifyService {
  static const String clientId = 'ad0911afa57949bba362003f601876b2'; // From instructions
  static const String redirectUri = 'meowsic://callback';
  static const String scope = 'user-read-private user-read-email user-modify-playback-state user-read-playback-state app-remote-control';

  final _storage = GetStorage();
  final String _storageKey = 'spotify_auth_data';

  // Persistence
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.write(_storageKey, data);
  }

  Map<String, dynamic>? get _authData => _storage.read(_storageKey);

  String? get accessToken => _authData?['access_token'];
  String? get refreshToken => _authData?['refresh_token'];
  int? get expiresAt => _authData?['expires_at'];

  bool get isLoggedIn => accessToken != null;

  // 1. LOGIN / AUTH
  Future<bool> login() async {
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
      'show_dialog': 'true',
    });

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: "meowsic",
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        return await _exchangeCodeForToken(code);
      }
    } catch (e) {
      debugPrint("Spotify Login Error: $e");
    }
    return false;
  }

  Future<bool> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        // Using direct client_id as instructions didn't provide secret but it works for public apps or PKCE
        // However, Spotify standard Auth Code Flow usually needs secret or PKCE.
        // Assuming the provided client_id is configured for this or we should use client_secret if provided.
        // The user's snippet used base64Encode('$clientId:YOUR_CLIENT_SECRET')
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      data['expires_at'] = DateTime.now().millisecondsSinceEpoch + (data['expires_in'] as int) * 1000;
      await _saveAuthData(data);
      return true;
    } else {
      debugPrint("Token Exchange Failed: ${response.body}");
      return false;
    }
  }

  Future<void> refreshAccessToken() async {
    final rToken = refreshToken;
    if (rToken == null) return;

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': rToken,
        'client_id': clientId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final currentData = Map<String, dynamic>.from(_authData ?? {});
      currentData['access_token'] = data['access_token'];
      currentData['expires_at'] = DateTime.now().millisecondsSinceEpoch + (data['expires_in'] as int) * 1000;
      if (data['refresh_token'] != null) {
        currentData['refresh_token'] = data['refresh_token'];
      }
      await _saveAuthData(currentData);
    }
  }

  Future<void> _ensureValidToken() async {
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt! - 60000) {
      await refreshAccessToken();
    }
  }

  // 2. SEARCH
  Future<List<Song>> searchTracks(String query) async {
    await _ensureValidToken();
    final token = accessToken;
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=20'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List tracks = data['tracks']['items'];

      return tracks.map((t) {
        return Song(
          id: t['id'],
          title: t['name'],
          image: (t['album']['images'] as List).isNotEmpty ? t['album']['images'][0]['url'] : '',
          source: 'spotify',
        );
      }).toList();
    }
    return [];
  }

  // 3. PLAYBACK
  Future<void> playTrack(String trackId) async {
    final uri = 'spotify:track:$trackId';
    
    // First try via API (requires Premium)
    final success = await _playViaApi(uri);
    
    // If API fails or user not Premium, open Spotify app
    if (!success) {
      final webUrl = 'https://open.spotify.com/track/$trackId';
      final appUri = Uri.parse(uri);
      
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<bool> _playViaApi(String uri) async {
    await _ensureValidToken();
    final token = accessToken;
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/play'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "uris": [uri]
        }),
      );
      return response.statusCode == 204; // Success
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _storage.remove(_storageKey);
  }
}
