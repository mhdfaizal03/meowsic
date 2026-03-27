import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/recent_controller.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';

class RecentScreen extends StatelessWidget {
  RecentScreen({Key? key}) : super(key: key);

  final RecentController controller = Get.put(RecentController());
  final MusicController musicController = Get.find<MusicController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recently Played"),
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
                  Color(0xFF4A00E0),
                  AppTheme.background,
                ], // Blueish gradient for recent
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.recentTracks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No recently played songs",
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
                itemCount: controller.recentTracks.length,
                itemBuilder: (_, i) {
                  return SongTile(
                    song: controller.recentTracks[i],
                    onTap: () {
                      musicController.playSong(controller.recentTracks[i]);
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
