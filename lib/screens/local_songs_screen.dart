import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';
import '../widgets/home_widgets.dart';

class LocalSongsScreen extends StatelessWidget {
  LocalSongsScreen({super.key});

  final MusicController controller = Get.find<MusicController>();

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
                title: "Local Music", 
                subtitle: "On your device",
                icon: Icons.library_music,
                baseColor: AppTheme.primary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () => controller.scanLocalMusic(),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              Obx(() {
                if (controller.localSongs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_music_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          const Text("NO LOCAL MUSIC FOUND", style: TextStyle(color: Colors.white38, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: const Text("SCAN DEVICE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            onPressed: () => controller.scanLocalMusic(),
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
                      return SongTile(
                        song: controller.localSongs[i],
                        onTap: () => controller.playSong(controller.localSongs[i]),
                      );
                    }, childCount: controller.localSongs.length),
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
