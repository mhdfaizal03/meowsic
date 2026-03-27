import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';

class LocalSongsScreen extends StatelessWidget {
  LocalSongsScreen({Key? key}) : super(key: key);

  final MusicController controller = Get.find<MusicController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Local Library"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.scanLocalMusic(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), AppTheme.background],
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.localSongs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 80,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No local songs found.",
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => controller.scanLocalMusic(),
                        child: Text("Scan Media"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: controller.localSongs.length,
                itemBuilder: (context, index) {
                  return SongTile(
                    song: controller.localSongs[index],
                    onTap: () =>
                        controller.playSong(controller.localSongs[index]),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
