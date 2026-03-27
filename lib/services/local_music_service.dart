import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/song_model.dart';

class LocalMusicService {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Request storage permissions
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    
    // For Android 13+ (SDK 33+), we need to request Permission.audio
    if (await Permission.audio.request().isGranted) {
      return true;
    }
    
    // Fallback for older Android versions
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    
    return false;
  }

  /// Fetch all local songs and normalize them to our Song model
  static Future<List<Song>> fetchLocalSongs() async {
    try {
      // Query songs from device
      List<SongModel> localSongs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      return localSongs
          .map(
            (s) => Song(
              id: s.id.toString(),
              title: s.title,
              artist: s.artist ?? 'Unknown Artist',
              image: '',
              source: 'local',
              localPath: s.data, // This is the absolute file path
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching local songs: $e");
      return [];
    }
  }

  /// Fetch artwork for a specific local song
  static Future<dynamic> getArtwork(int id) async {
    return await _audioQuery.queryArtwork(id, ArtworkType.AUDIO);
  }
}
