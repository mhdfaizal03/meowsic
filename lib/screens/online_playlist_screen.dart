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
                      color: Colors.white.withOpacity(0.5),
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
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (controller.headerImageUrl.value.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: controller.headerImageUrl.value,
                            fit: BoxFit.cover,
                          ),
                        // Dark Gradient Overlay for text readability
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppTheme.background],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.title.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.subtitle.value,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 18,
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

                // Play all button row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                          backgroundColor: AppTheme.primary,
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            if (controller.tracks.isNotEmpty) {
                              musicController.playSong(controller.tracks.first);
                              // Can also trigger queue replacement here natively if required later
                            }
                          },
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
