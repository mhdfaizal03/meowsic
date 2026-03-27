import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';
import '../widgets/home_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({Key? key}) : super(key: key);

  final FavoritesController controller = Get.put(FavoritesController());
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
                title: "Favorites", 
                subtitle: "Your liked songs",
                icon: Icons.favorite,
                baseColor: AppTheme.primary,
              ),
              Obx(() {
                if (controller.favoriteTracks.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          const Text("NO FAVORITES YET", style: TextStyle(color: Colors.white38, letterSpacing: 2)),
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
                        song: controller.favoriteTracks[i],
                        onTap: () => musicController.playSong(controller.favoriteTracks[i]),
                      );
                    }, childCount: controller.favoriteTracks.length),
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
