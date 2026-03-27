import 'package:get/get.dart';
import '../models/song_model.dart';
import '../services/phish_service.dart';
import '../services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class PhishController extends GetxController {
  final PhishService _service = PhishService();
  
  var songs = <Song>[].obs;
  var isLoading = false.obs;

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    isLoading.value = true;
    try {
      songs.value = await _service.searchTracks(query);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playTrack(Song song) async {
    final streamUrl = await _service.fetchStreamUrl(song.id);
    if (streamUrl.isNotEmpty) {
      // Direct stream play
      final mediaItem = MediaItem(
        id: song.id,
        album: "Phish.in",
        title: song.title,
        artist: "Phish",
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
