import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/recent_controller.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';
import '../widgets/home_widgets.dart';

class RecentScreen extends StatelessWidget {
  RecentScreen({super.key});

  final RecentController controller = Get.put(RecentController());
  final MusicController musicController = Get.find<MusicController>();

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
                title: "History", 
                subtitle: "Recently played",
                icon: Icons.history,
                baseColor: const Color(0xFF4A00E0),
              ),
              Obx(() {
                if (controller.recentTracks.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          const Text("NO HISTORY YET", style: TextStyle(color: Colors.white38, letterSpacing: 2)),
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
                        song: controller.recentTracks[i],
                        onTap: () => musicController.playSong(controller.recentTracks[i]),
                      );
                    }, childCount: controller.recentTracks.length),
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
