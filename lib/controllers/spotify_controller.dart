import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:flutter/foundation.dart';
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
  var isConnected = false.obs;
  var isLoading = false.obs;
  var spotifySongs = <Song>[].obs;
  var trackModels = <TrackModel>[].obs;
  
  // Real-time player state
  var playerState = Rxn<PlayerState>();
  var currentTrackName = "".obs;
  var currentArtistName = "".obs;
  var isSpotifyPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    _repository = SpotifyRepository(_apiService);
    checkLoginStatus();
    _initPlayerStateSubscription();
  }

  void checkLoginStatus() {
    final token = storage.read('spotify_token');
    isLoggedIn.value = token != null;
  }

  void _initPlayerStateSubscription() {
    SpotifySdk.subscribePlayerState().listen((state) {
      playerState.value = state;
      if (state.track != null) {
        currentTrackName.value = state.track?.name ?? "";
        currentArtistName.value = state.track?.artist.name ?? "";
        isSpotifyPlaying.value = !state.isPaused;
      }
    }, onError: (err) {
      debugPrint("Spotify Player State Error: $err");
    });
  }

  Future<void> login() async {
    try {
      isLoading.value = true;
      final token = await SpotifySdk.getAccessToken(
        clientId: _authService.clientId,
        redirectUrl: _authService.redirectUri,
        scope: _authService.scope,
      );

      storage.write('spotify_token', token);
      isLoggedIn.value = true;
      
      await connectToRemote();
      
      Get.snackbar("Spotify", "Connected successfully!");
    } catch (e) {
      debugPrint("Spotify Login Error: $e");
      Get.snackbar("Spotify", "Login failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> connectToRemote() async {
    try {
      final success = await SpotifySdk.connectToSpotifyRemote(
        clientId: _authService.clientId,
        redirectUrl: _authService.redirectUri,
      );
      isConnected.value = success;
    } catch (e) {
      debugPrint("Spotify Connect Error: $e");
      isConnected.value = false;
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    
    final token = storage.read('spotify_token');
    if (token == null) {
      Get.snackbar("Spotify", "Please connect Spotify first");
      return;
    }

    try {
      isLoading.value = true;
      final results = await _repository.searchTracks(token, query);
      trackModels.assignAll(results);
      
      spotifySongs.assignAll(results.map((t) => Song(
        id: t.id,
        title: t.name,
        image: t.image,
        source: 'spotify',
      )).toList());
    } catch (e) {
      if (e.toString().contains("Token expired") || e.toString().contains("401")) {
        // Re-login to get fresh token if unauthorized
        await login();
      } else {
        Get.snackbar("Spotify", "Search failed: $e");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playTrack(Song song) async {
    try {
      if (!isConnected.value) {
        await connectToRemote();
      }
      
      await SpotifySdk.play(spotifyUri: 'spotify:track:${song.id}');
    } catch (e) {
      debugPrint("Spotify Play Error: $e");
      Get.snackbar("Spotify", "Could not play track. Is Spotify installed and Premium?");
    }
  }

  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      debugPrint("Spotify Pause Error: $e");
    }
  }

  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } catch (e) {
      debugPrint("Spotify Resume Error: $e");
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      debugPrint("Spotify SkipNext Error: $e");
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      debugPrint("Spotify SkipPrev Error: $e");
    }
  }

  void logout() {
    try {
      SpotifySdk.disconnect();
    } catch (_) {}
    storage.remove('spotify_token');
    isLoggedIn.value = false;
    isConnected.value = false;
    spotifySongs.clear();
    trackModels.clear();
  }
}
