import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song_model.dart';
import '../models/track_model.dart';
import '../services/spotify_auth_service.dart';
import '../services/spotify_api_service.dart';
import '../repositories/spotify_repository.dart';

class SpotifyController extends GetxController {
  final SpotifyAuthService _authService = SpotifyAuthService();
  final SpotifyApiService _apiService = SpotifyApiService();
  late final SpotifyRepository _repository;

  final storage = GetStorage();
  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  var spotifySongs = <Song>[].obs;
  var trackModels = <TrackModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _repository = SpotifyRepository(_apiService);
    checkLoginStatus();
  }

  void checkLoginStatus() {
    final token = storage.read('spotify_token');
    isLoggedIn.value = token != null;
  }

  Future<void> login() async {
    try {
      final String url = "https://accounts.spotify.com/authorize"
          "?client_id=${_authService.clientId}"
          "&response_type=code"
          "&redirect_uri=${Uri.encodeComponent(_authService.redirectUri)}"
          "&scope=${Uri.encodeComponent("user-read-private user-read-email user-modify-playback-state user-read-playback-state app-remote-control")}";

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: "meowsic",
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        isLoading.value = true;
        final response = await _authService.getToken(code);
        _saveTokens(response);
        isLoggedIn.value = true;
        Get.snackbar("Spotify", "Connected successfully!");
      }
    } catch (e) {
      print("Spotify Login Error: $e");
      Get.snackbar("Spotify", "Login failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _saveTokens(Map<String, dynamic> response) {
    storage.write('spotify_token', response['access_token']);
    storage.write('spotify_refresh_token', response['refresh_token']);
    // Store expiry time if needed
  }

  Future<String?> getValidToken() async {
    // In a real app, check expiry and refresh if needed
    return storage.read('spotify_token');
  }

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    
    final token = await getValidToken();
    if (token == null) {
      Get.snackbar("Spotify", "Please connect Spotify first");
      return;
    }

    try {
      isLoading.value = true;
      final results = await _repository.searchTracks(token, query);
      trackModels.assignAll(results);
      
      // Convert to app's Song model for compatibility with existing UI
      spotifySongs.assignAll(results.map((t) => Song(
        id: t.id,
        title: t.name,
        // artist removed from Song model in this version, using title with artist
        image: t.image,
        source: 'spotify',
      )).toList());
    } catch (e) {
      if (e.toString().contains("Token expired")) {
        await _handleTokenExpiry();
        return search(query); // Retry
      }
      Get.snackbar("Spotify", "Search failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleTokenExpiry() async {
    final refreshToken = storage.read('spotify_refresh_token');
    if (refreshToken != null) {
      try {
        final response = await _authService.refreshToken(refreshToken);
        _saveTokens(response);
      } catch (e) {
        logout();
      }
    } else {
      logout();
    }
  }

  Future<void> playTrack(Song song) async {
    final token = await getValidToken();
    if (token != null) {
      final success = await _repository.playTrack(token, song.id);
      if (success) {
        Get.snackbar("Spotify", "Playing on your active device");
        return;
      }
    }
    
    // Fallback: Launch Spotify App
    final url = Uri.parse("https://open.spotify.com/track/${song.id}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not launch Spotify");
    }
  }

  void logout() {
    storage.remove('spotify_token');
    storage.remove('spotify_refresh_token');
    isLoggedIn.value = false;
    spotifySongs.clear();
    trackModels.clear();
  }
}
