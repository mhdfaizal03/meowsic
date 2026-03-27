import 'package:get/get.dart';
import '../models/song_model.dart';
import '../services/external_music_service.dart';
import '../services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class ExternalMusicController extends GetxController {
  var songs = <Song>[].obs;
  var isLoading = false.obs;
  var currentEngine = "gaama".obs; // gaama, seevn, hunjama, mtmusic, wunk

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    isLoading.value = true;
    try {
      songs.value = await ExternalMusicService.search(query, currentEngine.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playTrack(Song song) async {
    final streamUrl = await ExternalMusicService.fetchStreamUrl(song.id);
    if (streamUrl.isNotEmpty) {
      final mediaItem = MediaItem(
        id: song.id,
        album: "Meowsic External",
        title: song.title,
        artist: song.source,
        artUri: Uri.parse(song.image),
      );
      audioHandler.mediaItem.add(mediaItem);
      await audioHandler.setUrl(streamUrl);
      audioHandler.play();
    } else {
      Get.snackbar("Error", "Could not fetch stream for this track");
    }
  }
}
