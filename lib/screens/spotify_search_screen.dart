import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/spotify_controller.dart';
import '../models/song_model.dart';
import '../models/track_model.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';

class SpotifySearchScreen extends StatelessWidget {
  final SpotifyController controller = Get.find<SpotifyController>();
  final TextEditingController searchController = TextEditingController();

  SpotifySearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Spotify Premium",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(width: 8),
            Obx(() => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isConnected.value ? Colors.green : Colors.red,
                boxShadow: [
                  if (controller.isConnected.value)
                    BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 5, spreadRadius: 2)
                ],
              ),
            )),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.connectToRemote(),
            tooltip: "Reconnect Spotify",
          )
        ],
      ),
      body: Stack(
        children: [
          // Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1DB954), // Spotify Green
                  Color(0xFF191414), // Spotify Black
                  AppTheme.background,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Premium Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassContainer(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (value) => controller.search(value),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "What do you want to listen to?",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        icon: const Icon(Icons.search, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            searchController.clear();
                            controller.spotifySongs.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Search Results
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return _buildShimmerLoading();
                    }

                    if (controller.trackModels.isEmpty) {
                      return _buildInitialState();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: controller.trackModels.length,
                      itemBuilder: (context, index) {
                        final track = controller.trackModels[index];
                        return _buildTrackTile(track);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Spotify Now Playing Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildSpotifyPlayerBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyPlayerBar() {
    return Obx(() {
      if (controller.currentTrackName.isEmpty) return const SizedBox.shrink();
      
      return Container(
        margin: const EdgeInsets.all(16),
        child: GlassContainer(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.speaker_group, color: Color(0xFF1DB954), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentTrackName.value,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      controller.currentArtistName.value,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () => controller.skipPrevious(),
              ),
              IconButton(
                icon: Icon(
                  controller.isSpotifyPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => controller.isSpotifyPlaying.value ? controller.pause() : controller.resume(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => controller.skipNext(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Search for your favorite Spotify tracks",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 12, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 10, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(TrackModel track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          // Play functionality
          final song = Song(
            id: track.id,
            title: track.name,
            image: track.image,
            source: 'spotify',
          );
          controller.playTrack(song);
        },
        child: GlassContainer(
          height: 80,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Hero Animation for Album Art
              Hero(
                tag: 'spotify_art_${track.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.white12,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_filled, color: Color(0xFF1DB954), size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
