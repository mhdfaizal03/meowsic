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
import '../widgets/home_widgets.dart';

class PlaylistScreen extends StatelessWidget {
  PlaylistScreen({super.key});

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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
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
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                title: const Text("My Playlists", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    onPressed: () => _showCreateDialog(context),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Your personal collection of tracks organized by lists.",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ),
              ),
              Obx(() {
                if (controller.playlists.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 20),
                          const Text("NO PLAYLISTS YET", style: TextStyle(color: Colors.white38, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: const Text("CREATE ONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            onPressed: () => _showCreateDialog(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      return PlaylistTile(
                        playlist: controller.playlists[i],
                        onTap: () => Get.to(() => PlaylistDetailScreen(playlist: controller.playlists[i]), transition: Transition.rightToLeft),
                      );
                    }, childCount: controller.playlists.length),
                  ),
                );
              }),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  PlaylistDetailScreen({super.key, required this.playlist});

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
              MusicSliverHeader(
                title: playlist.name,
                subtitle: "${playlist.songs.length} tracks",
                icon: Icons.library_music,
                baseColor: AppTheme.primary,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                        label: const Text("PLAY ALL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
