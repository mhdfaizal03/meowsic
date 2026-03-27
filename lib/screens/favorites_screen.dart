import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({Key? key}) : super(key: key);

  final FavoritesController controller = Get.put(FavoritesController());
  final MusicController musicController = Get.find<MusicController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8E2DE2),
                  AppTheme.background,
                ], // Purple gradient for favorites
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.favoriteTracks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No favorites yet",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.favoriteTracks.length,
                itemBuilder: (_, i) {
                  return SongTile(
                    song: controller.favoriteTracks[i],
                    onTap: () {
                      musicController.playSong(controller.favoriteTracks[i]);
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
