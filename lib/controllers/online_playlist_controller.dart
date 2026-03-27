import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

import '../models/song_model.dart';
import '../services/music_api_service.dart';

class OnlinePlaylistController extends GetxController {
  /// Raw YTMusic data
  final currentAlbum = Rxn<AlbumFull>();
  final currentPlaylist = Rxn<PlaylistFull>();

  /// Normalized UI data
  final title = ''.obs;
  final subtitle = ''.obs;
  final headerImageUrl = ''.obs;

  /// Playable songs
  final tracks = <Song>[].obs;

  /// State
  final isLoading = false.obs;
  final hasError = false.obs;

  // ============================================================
  // LOAD ALBUM
  // ============================================================

  Future<void> loadAlbum(String albumId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      currentAlbum.value = null;
      currentPlaylist.value = null;

      tracks.clear();

      final album = await MusicApiService.fetchAlbumDetails(albumId);

      if (album == null) {
        hasError.value = true;
        return;
      }

      currentAlbum.value = album;

      /// Title
      title.value = album.name;

      /// Subtitle (Artist)
      subtitle.value = album.artist.name.isNotEmpty
          ? album.artist.name
          : "Unknown Artist";

      /// Header Image
      headerImageUrl.value = album.thumbnails.isNotEmpty
          ? album.thumbnails.last.url
          : '';

      /// Tracks normalization
      tracks.value = album.songs
          .map((ytSong) {
            String image = headerImageUrl.value;

            if (ytSong.thumbnails.isNotEmpty) {
              image = ytSong.thumbnails.last.url;
            }

            return Song(
              id: ytSong.videoId,
              title: ytSong.name,
              image: image,
              source: 'youtube',
            );
          })
          .where((s) => s.id.isNotEmpty)
          .toList();

      debugPrint(
        "Controller: Normalized ${tracks.length} songs for album ${album.name}",
      );

      /// Fallback image
      if (headerImageUrl.value.isEmpty && tracks.isNotEmpty) {
        headerImageUrl.value = tracks.first.image;
      }
    } catch (e) {
      debugPrint("Album load error: $e");

      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // LOAD PLAYLIST
  // ============================================================

  Future<void> loadPlaylist(String playlistId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      currentAlbum.value = null;
      currentPlaylist.value = null;

      tracks.clear();

      debugPrint("Controller: Loading playlist $playlistId");

      String finalId = playlistId;

      if (!finalId.startsWith("VL")) {
        if (finalId.startsWith("PL") ||
            finalId.startsWith("RD") ||
            finalId.startsWith("OLAK")) {
          finalId = "VL$finalId";
        }
      }

      final results = await Future.wait([
        MusicApiService.fetchPlaylistDetails(finalId),
        MusicApiService.fetchPlaylistSongs(finalId),
      ]);

      final playlist = results[0] as PlaylistFull?;
      final List<VideoDetailed> videos =
          (results[1] as List<VideoDetailed>?) ?? [];

      debugPrint(
        "Controller: Meta=${playlist?.name}, SongCount=${videos.length}",
      );

      if (playlist == null && videos.isEmpty) {
        debugPrint("Controller: Total failure for $finalId");
        hasError.value = true;
        return;
      }

      /// Metadata handling
      if (playlist != null) {
        currentPlaylist.value = playlist;
        title.value = playlist.name;
        subtitle.value = (playlist.artist.name.isNotEmpty)
            ? playlist.artist.name
            : "YouTube Music";

        headerImageUrl.value = playlist.thumbnails.isNotEmpty
            ? playlist.thumbnails.last.url
            : '';
      } else {
        title.value = "Playlist";
        subtitle.value = "YouTube Music";
        headerImageUrl.value = '';
      }

      /// Normalize videos to Song model
      tracks.value = videos
          .map((video) {
            String image = headerImageUrl.value;
            if (video.thumbnails.isNotEmpty) {
              image = video.thumbnails.last.url;
            }

            return Song(
              id: video.videoId,
              title: video.name,
              image: image,
              source: 'youtube',
            );
          })
          .where((s) => s.id.isNotEmpty)
          .toList();

      debugPrint("Controller: Normalized ${tracks.length} tracks");

      if (tracks.isEmpty) {
        debugPrint("Warning: Playlist mapped to 0 playable tracks");
      }

      /// Fallback image
      if (headerImageUrl.value.isEmpty && tracks.isNotEmpty) {
        headerImageUrl.value = tracks.first.image;
      }
    } catch (e) {
      debugPrint("Playlist load error: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // REFRESH SUPPORT
  // ============================================================

  Future<void> refreshPlaylist(String playlistId) async {
    await loadPlaylist(playlistId);
  }

  Future<void> refreshAlbum(String albumId) async {
    await loadAlbum(albumId);
  }
}
