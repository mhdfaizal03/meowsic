import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/online_playlist_controller.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';

class OnlinePlaylistScreen extends StatelessWidget {
  final String id;
  final bool isAlbum;

  OnlinePlaylistScreen({Key? key, required this.id, this.isAlbum = false})
    : super(key: key) {
    if (isAlbum) {
      Get.find<OnlinePlaylistController>().loadAlbum(id);
    } else {
      Get.find<OnlinePlaylistController>().loadPlaylist(id);
    }
  }

  final OnlinePlaylistController controller =
      Get.find<OnlinePlaylistController>();
  final MusicController musicController = Get.find<MusicController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: SpinKitWave(color: AppTheme.primary, size: 40),
              );
            }

            if (controller.hasError.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Could not load playlist/album",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 340,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (controller.headerImageUrl.value.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: controller.headerImageUrl.value,
                            fit: BoxFit.cover,
                          ),
                        
                        // Glassmorphic Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.background.withValues(alpha: 0.5),
                                AppTheme.background,
                              ],
                              stops: const [0, 0.7, 1],
                            ),
                          ),
                        ),

                        // Playlist Info
                        Positioned(
                          bottom: 40,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  isAlbum ? "ALBUM" : "PLAYLIST",
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.title.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.subtitle.value,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (controller.tracks.isNotEmpty) {
                              musicController.playSong(controller.tracks.first);
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                          label: const Text("PLAY ALL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: Colors.white54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ), // Room for mini player
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return SongTile(
                        song: controller.tracks[index],
                        onTap: () {
                          musicController.playSong(controller.tracks[index]);
                        },
                      );
                    }, childCount: controller.tracks.length),
                  ),
                ),
              ],
            );
          }),

          Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}
