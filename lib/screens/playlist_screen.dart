import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';

class PlaylistScreen extends StatelessWidget {
  PlaylistScreen({Key? key}) : super(key: key);

  final PlaylistController controller = Get.put(PlaylistController());
  final TextEditingController createController = TextEditingController();

  void _showCreateDialog(BuildContext context) {
    Get.defaultDialog(
      title: "New Playlist",
      backgroundColor: AppTheme.surface,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: createController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Playlist Name",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          autofocus: true,
        ),
      ),
      textConfirm: "Create",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.primary,
      onConfirm: () {
        controller.createPlaylist(createController.text);
        createController.clear();
        Get.back();
      },
      onCancel: () {
        createController.clear();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Playlists"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1332), AppTheme.background],
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.playlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No playlists yet",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text("Create One"),
                        onPressed: () => _showCreateDialog(context),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // padding for mini player
                physics: const BouncingScrollPhysics(),
                itemCount: controller.playlists.length,
                itemBuilder: (_, i) {
                  return PlaylistTile(
                    playlist: controller.playlists[i],
                    onTap: () {
                      Get.to(
                        () => PlaylistDetailScreen(
                          playlist: controller.playlists[i],
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                  );
                },
              );
            }),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  PlaylistDetailScreen({Key? key, required this.playlist}) : super(key: key);

  final PlaylistController controller = Get.find<PlaylistController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppTheme.primary.withOpacity(0.2),
                        child: Icon(
                          Icons.library_music,
                          size: 100,
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          "Play All",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          if (playlist.songs.isNotEmpty) {
                            controller.playPlaylist(playlist);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Obx(() {
                // Find actual playlist object to stay reactive
                Playlist? currentP = controller.playlists.firstWhereOrNull(
                  (p) => p.id == playlist.id,
                );
                if (currentP == null || currentP.songs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "Playlist is empty",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final Song song = currentP.songs[index];
                    return Dismissible(
                      key: Key(song.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        controller.removeSongFromPlaylist(playlist.id, song.id);
                      },
                      child: SongTile(
                        song: song,
                        onTap: () {
                          // Play specifically the sequence from this playlist overriding the music controller
                          controller.playPlaylist(
                            currentP,
                          ); // Basic start from beginning for now, or could pass index
                        },
                      ),
                    );
                  }, childCount: currentP.songs.length),
                );
              }),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ), // Bottom padding
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}
