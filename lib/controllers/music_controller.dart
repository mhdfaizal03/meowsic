import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/local_music_service.dart';
import 'recent_controller.dart';
import 'package:isar/isar.dart';
import '../models/isar_song.dart';
import '../services/phish_service.dart';
import '../services/external_music_service.dart';
import '../services/music_api_service.dart';

class MusicController extends GetxController {
  var songs = <Song>[].obs; // Search results
  var currentQueue = <Song>[].obs; // Active playing list
  var localSongs = <Song>[].obs; // Device songs

  var isLoading = false.obs;
  var currentSong = Rxn<Song>();
  var currentLyrics = "Lyrics not available".obs;

  var isPlaying = false.obs;
  var position = Duration.zero.obs;
  var duration = Duration.zero.obs;

  var isShuffleModeEnabled = false.obs;
  var loopMode = LoopMode.off.obs;

  var homeSections = <dynamic>[].obs; // Holds dart_ytmusic_api HomeSections
  var isHomeLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToAudioState();
    _fetchHomeData();
    _loadCachedSongs();
  }

  Future<void> _loadCachedSongs() async {
    try {
      final isar = Get.find<Isar>();
      final cached = await isar.storedSongs.where().findAll();
      localSongs.value = cached
          .map(
            (e) => Song(
              id: e.ytId,
              title: e.title,
              artist: e.artist,
              image: e.image,
              source: 'local',
              localPath: e.localPath,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error loading cached songs: $e");
    }
  }

  Future<void> _fetchHomeData() async {
    isHomeLoading.value = true;
    try {
      homeSections.value = await MusicApiService.fetchHomeSections();
      // Auto scan local music on start
      scanLocalMusic();
    } catch (e) {
      debugPrint("Error loading home sections: $e");
    } finally {
      isHomeLoading.value = false;
    }
  }

  Future<void> scanLocalMusic() async {
    bool hasPermission = await LocalMusicService.requestPermission();
    if (hasPermission) {
      final fetched = await LocalMusicService.fetchLocalSongs();
      localSongs.value = fetched;

      // Cache to Isar
      final isar = Get.find<Isar>();
      await isar.writeTxn(() async {
        for (var s in fetched) {
          final isarSong = StoredSong()
            ..ytId = s.id
            ..title = s.title
            ..artist = s.artist
            ..image = s.image
            ..localPath = s.localPath
            ..lastPlayed = DateTime.now();
          await isar.storedSongs.put(isarSong);
        }
      });
    }
  }

  void _listenToAudioState() {
    audioHandler.player.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

    audioHandler.player.positionStream.listen((pos) {
      position.value = pos;
    });

    audioHandler.player.durationStream.listen((dur) {
      if (dur != null) duration.value = dur;
    });

    audioHandler.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });

    audioHandler.player.shuffleModeEnabledStream.listen((isShuffle) {
      isShuffleModeEnabled.value = isShuffle;
    });

    audioHandler.player.loopModeStream.listen((loop) {
      loopMode.value = loop;
    });
  }

  Future search(String query) async {
    if (query.isEmpty) return;
    isLoading.value = true;

    try {
      songs.value = await MusicApiService.searchSongs(query);
    } catch (e) {
      debugPrint("Search Error: $e");
      Get.snackbar(
        "Search Failed",
        "Could not fetch results. Please try again.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future playSong(Song song, {List<Song>? newQueue}) async {
    if (newQueue != null) {
      currentQueue.value = newQueue;
    } else if (song.source == 'local') {
      // If we play from local, make sure local songs are in queue if it's empty
      if (currentQueue.isEmpty) {
        currentQueue.value = List.from(localSongs);
      }
    } else if (currentQueue.isEmpty && songs.isNotEmpty) {
      currentQueue.value = List.from(songs);
    } else if (!currentQueue.any((s) => s.id == song.id)) {
      currentQueue.add(song);
    }

    currentSong.value = song;
    currentLyrics.value = "Loading lyrics...";

    // Record History
    try {
      Get.find<RecentController>().addRecent(song);
    } catch (_) {}

    try {
      String url = '';
      if (song.localPath != null && song.localPath!.isNotEmpty) {
        // Ensure local file path is properly formatted as a URI for just_audio
        final path = song.localPath!;
        if (path.startsWith('/') || (path.length > 1 && path[1] == ':')) {
          url = Uri.file(path).toString();
        } else {
          url = path;
        }
      } else if (song.source == 'phish') {
        url = await Get.find<PhishService>().fetchStreamUrl(song.id);
      } else if (song.id.startsWith('ext:') ||
          ['gaama', 'seevn', 'hunjama', 'mtmusic', 'wunk']
              .contains(song.source)) {
        url = await ExternalMusicService.fetchStreamUrl(song.id);
      } else {
        url = await MusicApiService.fetchSongUrl(song.id);
      }

      if (url.isEmpty) {
        debugPrint("No valid stream available for ${song.title}");
        Get.snackbar(
          "Playback Error",
          "No valid stream available. Please try another song.",
          snackPosition: SnackPosition.BOTTOM,
        );
        currentLyrics.value = "No valid stream.";
        return;
      }

      debugPrint("Attempting to play valid stream: $url");

      try {
        final artUri = song.image.isNotEmpty
            ? Uri.tryParse(song.image)
            : null;
        final mediaItem = MediaItem(
          id: song.id,
          album: "Meowsic",
          title: song.title,
          artist: "Meowsic",
          artUri: artUri,
        );
        audioHandler.mediaItem.add(mediaItem);

        await audioHandler.setUrl(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          },
        );
        await audioHandler.play();
      } catch (e) {
        debugPrint("Initial setUrl failed, retrying... Error: $e");
        // Retry once with a freshly fetched URL
        await Future.delayed(const Duration(seconds: 1));
        url = await MusicApiService.fetchSongUrl(song.id);

        if (url.isNotEmpty) {
          await audioHandler.setUrl(
            url,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            },
          );
          await audioHandler.play();
        } else {
          throw Exception("Retry failed: URL empty or invalid");
        }
      }

      try {
        currentLyrics.value = await MusicApiService.getLyrics(song.id);
      } catch (_) {
        currentLyrics.value = "Lyrics not available.";
      }
    } catch (e) {
      debugPrint("Final Playback Error: $e");
      Get.snackbar(
        "Playback Failed",
        "Could not load this track. Please check your connection or try another song.",
        snackPosition: SnackPosition.BOTTOM,
      );
      currentLyrics.value = "Playback failed.";
    }
  }

  void playNext() {
    if (currentQueue.isEmpty || currentSong.value == null) return;

    if (loopMode.value == LoopMode.one) {
      seek(Duration.zero);
      resume();
      return;
    }

    int idx = currentQueue.indexWhere((s) => s.id == currentSong.value!.id);
    if (idx != -1) {
      if (idx + 1 < currentQueue.length) {
        playSong(currentQueue[idx + 1], newQueue: currentQueue);
      } else if (loopMode.value == LoopMode.all) {
        playSong(currentQueue.first, newQueue: currentQueue);
      }
    }
  }

  void playPrevious() {
    if (currentQueue.isEmpty || currentSong.value == null) return;

    if (position.value.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int idx = currentQueue.indexWhere((s) => s.id == currentSong.value!.id);
    if (idx > 0) {
      playSong(currentQueue[idx - 1], newQueue: currentQueue);
    } else if (loopMode.value == LoopMode.all) {
      playSong(currentQueue.last, newQueue: currentQueue);
    }
  }

  void pause() => audioHandler.pause();
  void resume() => audioHandler.play();
  void seek(Duration pos) => audioHandler.seek(pos);

  void toggleShuffle() async {
    final enable = !isShuffleModeEnabled.value;
    await audioHandler.player.setShuffleModeEnabled(enable);
    if (enable) currentQueue.shuffle();
  }

  void toggleRepeat() {
    final modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    int nextIdx = (modes.indexOf(loopMode.value) + 1) % modes.length;
    audioHandler.player.setLoopMode(modes[nextIdx]);
  }
}
