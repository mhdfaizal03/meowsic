import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class MusicApiService {
  /// YTMusic instance
  static final YTMusic _ytMusic = YTMusic();

  /// YoutubeExplode instance (NOT supported on Web)
  static final YoutubeExplode _ytExplode = YoutubeExplode();

  static bool _initialized = false;

  /// Worker API (Cloudflare Worker)
  static const String _workerUrl = "https://musicapi.x007.workers.dev";

  /// Initialize YTMusic safely
  static Future<void> _ensureInit() async {
    if (!_initialized) {
      await _ytMusic.initialize();
      _initialized = true;
    }
  }

  // ============================================================
  // SEARCH SONGS
  // Primary: YouTube Music
  // Secondary: Worker API fallback
  // ============================================================

  static Future<List<Song>> searchSongs(String query) async {
    await _ensureInit();

    List<Song> songs = [];

    /// PRIMARY: YTMusic search
    try {
      final results = await _ytMusic.search(query);

      final songResults = results.whereType<SongDetailed>().toList();

      songs.addAll(
        songResults.map((ytSong) {
          return Song(
            id: ytSong.videoId,
            title: ytSong.name,
            image: ytSong.thumbnails.last.url,
            source: 'youtube',
          );
        }),
      );
    } catch (e) {
      debugPrint("YTMusic search error: $e");
    }

    /// SECONDARY: Worker fallback if low results
    if (songs.length < 5) {
      try {
        final fallbackSongs = await _searchWorkerSongs(query);

        songs.addAll(fallbackSongs);
      } catch (e) {
        debugPrint("Worker search fallback error: $e");
      }
    }

    return songs;
  }

  // ============================================================
  // WORKER SEARCH
  // ============================================================

  static Future<List<Song>> _searchWorkerSongs(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$_workerUrl/search?q=${Uri.encodeComponent(query)}&searchEngine=gaama",
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List results = data['response'];

        return results.map((item) {
          return Song(
            id: "gaana:${item['id']}",
            title: item['title'] ?? "Unknown",
            image: item['img'] ?? "",
            source: "gaana",
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Worker search failed: $e");
    }

    return [];
  }

  // ============================================================
  // FETCH STREAM URL
  // Multi-tier fallback system
  // ============================================================

  static Future<String> fetchSongUrl(String id) async {
    debugPrint("Fetching URL for: $id");

    /// Remove gaana prefix if exists
    final cleanId = id.replaceFirst("gaana:", "");

    // 1. YoutubeExplode (PRIMARY)
    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(
        cleanId,
      );
      final audioStreams = manifest.audioOnly;

      for (final stream in audioStreams) {
        final url = stream.url.toString();
        // ONLY allow valid YouTube HTTPS streams from googlevideo.com
        if (url.startsWith("https://") &&
            url.contains("googlevideo.com") &&
            !url.contains("127.0.0.1") &&
            !url.contains("localhost")) {
          debugPrint("Valid googlevideo stream found");
          return url;
        }
      }
    } catch (e) {
      debugPrint("YoutubeExplode failed: $e");
    }

    // 2. Piped API fallback
    try {
      final response = await http.get(
        Uri.parse("https://pipedapi.kavin.rocks/streams/$cleanId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final streams = data['audioStreams'];

        if (streams != null && streams.isNotEmpty) {
          for (final stream in streams) {
            final url = stream['url'];
            if (url != null && url.startsWith("https://")) {
              debugPrint("Piped stream used");
              return url;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Piped failed: $e");
    }

    // 3. Worker fallback (Optional but kept for Gaana/Compatibility)
    try {
      final response = await http.get(
        Uri.parse("$_workerUrl/fetch?id=$cleanId"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['response'];
        if (url != null && url.startsWith("https://")) {
          debugPrint("Worker success fallback");
          return url;
        }
      }
    } catch (e) {
      debugPrint("Worker fallback failed: $e");
    }

    debugPrint("All stream sources failed");
    return "";
  }

  // ============================================================
  // LYRICS
  // ============================================================

  static Future<String> getLyrics(String id) async {
    await _ensureInit();

    try {
      final lyrics = await _ytMusic.getLyrics(id);

      if (lyrics != null && lyrics.isNotEmpty) {
        return lyrics;
      }
    } catch (e) {
      debugPrint("Lyrics error: $e");
    }

    return "Lyrics not available";
  }

  // ============================================================
  // HOME SECTIONS
  // ============================================================

  static Future<List<HomeSection>> fetchHomeSections() async {
    await _ensureInit();

    try {
      return await _ytMusic.getHomeSections();
    } catch (e) {
      debugPrint("HomeSections error: $e");
    }

    return [];
  }

  // ============================================================
  // ALBUM DETAILS
  // ============================================================

  static Future<AlbumFull?> fetchAlbumDetails(String albumId) async {
    await _ensureInit();

    try {
      return await _ytMusic.getAlbum(albumId);
    } catch (e) {
      debugPrint("Album error: $e");
    }

    return null;
  }

  // ============================================================
  // PLAYLIST DETAILS
  // ============================================================

  static Future<PlaylistFull?> fetchPlaylistDetails(String playlistId) async {
    await _ensureInit();

    try {
      String finalId = playlistId;

      if (!finalId.startsWith("VL")) {
        if (finalId.startsWith("PL") ||
            finalId.startsWith("RD") ||
            finalId.startsWith("OLAK")) {
          finalId = "VL$finalId";
        }
      }

      return await _ytMusic.getPlaylist(finalId);
    } catch (e) {
      debugPrint("Playlist error: $e");
    }

    return null;
  }

  // ============================================================
  // PLAYLIST SONGS
  // ============================================================

  static Future<List<VideoDetailed>> fetchPlaylistSongs(
    String playlistId,
  ) async {
    await _ensureInit();

    try {
      String finalId = playlistId;

      if (!finalId.startsWith("VL")) {
        if (finalId.startsWith("PL") ||
            finalId.startsWith("RD") ||
            finalId.startsWith("OLAK")) {
          finalId = "VL$finalId";
        }
      }

      debugPrint("Fetching playlist songs for: $finalId");
      return await _ytMusic.getPlaylistVideos(finalId);
    } catch (e) {
      debugPrint("Playlist songs error: $e");
    }

    return [];
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  static void dispose() {
    if (!kIsWeb) {
      _ytExplode.close();
    }
  }
}
