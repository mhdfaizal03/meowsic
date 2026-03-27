import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/music_controller.dart';
import '../screens/player_screen.dart';
import '../core/theme.dart';
import 'glass_container.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;
  MiniPlayer({Key? key, this.onTap}) : super(key: key);

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
        child: GlassContainer(
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: song.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Antigravity Stream",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(() {
                final isPlaying = controller.isPlaying.value;
                return IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      controller.pause();
                    } else {
                      controller.resume();
                    }
                  },
                );
              }),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    });
  }
}
