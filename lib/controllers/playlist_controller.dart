import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'music_controller.dart';

class PlaylistController extends GetxController {
  var playlists = <Playlist>[].obs;
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    List? stored = box.read<List>('playlists');
    if (stored != null) {
      playlists.value = stored.map((e) => Playlist.fromJson(e)).toList();
    }
  }

  void _savePlaylists() {
    box.write('playlists', playlists.map((e) => e.toJson()).toList());
  }

  void createPlaylist(String name) {
    if (name.trim().isEmpty) return;
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songs: [],
    );
    playlists.add(newPlaylist);
    _savePlaylists();
  }

  void deletePlaylist(String id) {
    playlists.removeWhere((p) => p.id == id);
    _savePlaylists();
  }

  void addSongToPlaylist(String playlistId, Song song) {
    int index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      // Avoid exact duplicates by ID
      bool exists = playlists[index].songs.any((s) => s.id == song.id);
      if (!exists) {
        playlists[index].songs.add(song);
        playlists.refresh();
        _savePlaylists();
        Get.snackbar(
          "Added",
          "${song.title} added to ${playlists[index].name}",
        );
      } else {
        Get.snackbar("Notice", "Song already in playlist");
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    int index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      playlists[index].songs.removeWhere((s) => s.id == songId);
      playlists.refresh();
      _savePlaylists();
    }
  }

  // Play an entire playlist sequentially
  Future<void> playPlaylist(Playlist playlist) async {
    if (playlist.songs.isEmpty) {
      Get.snackbar("Empty Playlist", "Add some songs first!");
      return;
    }

    final musicController = Get.find<MusicController>();

    // Set the overall music controller queue to mimic playing sequentially
    musicController.songs.value = playlist.songs;

    // Play the first item
    musicController.playSong(playlist.songs.first);
  }

  void showAddToPlaylistDialog(Song song) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add to Playlist",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (playlists.isEmpty) {
                return const Center(
                  child: Text(
                    "No playlists yet. Create one in the Library!",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final p = playlists[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: Colors.white70,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        addSongToPlaylist(p.id, song);
                        Get.back();
                      },
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
