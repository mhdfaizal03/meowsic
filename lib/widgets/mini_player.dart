import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/music_controller.dart';
import '../screens/player_screen.dart';
import '../core/theme.dart';
import 'glass_container.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;
  MiniPlayer({super.key, this.onTap});

  final MusicController controller = Get.find<MusicController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final song = controller.currentSong.value;
      if (song == null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            Get.to(() => PlayerScreen(), transition: Transition.downToUp);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: GlassContainer(
            height: 75,
            margin: EdgeInsets.zero, // Removed margin as it's handled by parent padding if needed
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: song.image,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist.toUpperCase(),
                              style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Obx(() {
                      final isPlaying = controller.isPlaying.value;
                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 38),
                            onPressed: () => isPlaying ? controller.pause() : controller.resume(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 28),
                            onPressed: controller.playNext,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(width: 8),
                  ],
                ),
                // Sleek progress bar at the very bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Obx(() {
                    final duration = controller.duration.value.inSeconds;
                    final position = controller.position.value.inSeconds;
                    if (duration <= 0) return const SizedBox.shrink();
                    return LinearProgressIndicator(
                      value: position / duration,
                      backgroundColor: Colors.white.withValues(alpha: 0.02),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      minHeight: 2,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
