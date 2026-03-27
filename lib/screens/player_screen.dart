import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../models/song_model.dart';
import '../controllers/music_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../services/download_service.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';
import 'lyrics_screen.dart';

class PlayerScreen extends StatefulWidget {
  PlayerScreen({super.key});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final MusicController controller = Get.find<MusicController>();
  final FavoritesController favController = Get.put(FavoritesController());

  late AnimationController _rotationController;
  Color dominantColor = AppTheme.background;
  String currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Listen to play state to pause/resume rotation
    ever(controller.isPlaying, (bool playing) {
      if (playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette(String imageUrl) async {
    if (imageUrl == currentImageUrl) return;
    currentImageUrl = imageUrl;

    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(imageUrl),
          );
      if (mounted) {
        setState(() {
          dominantColor =
              paletteGenerator.dominantColor?.color ?? AppTheme.background;
        });
      }
    } catch (e) {
      print("Error generating palette: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.white),
            onPressed: () {
              final song = controller.currentSong.value;
              if (song != null) {
                Get.find<PlaylistController>().showAddToPlaylistDialog(song);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, color: Colors.white),
            onPressed: () => Get.to(() => LyricsScreen()),
          ),
        ],
      ),
      body: Obx(() {
        final Song? song = controller.currentSong.value;
        if (song == null) {
          return Container(color: AppTheme.background);
        }

        _updatePalette(song.image);

        return Stack(
          children: [
            // Dynamic Gradient Background
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [dominantColor.withValues(alpha: 0.8), AppTheme.background],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Rotating Album Artwork
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Hero(
                      tag: 'album_art_${song.id}',
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (_, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: dominantColor.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: song.image,
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const Spacer(),

                  // Title and Artist
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Glassmorphic Control Panel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(30),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      child: Column(
                        children: [
                          // Progress Bar
                          Obx(() {
                            final duration = controller.duration.value;
                            final position = controller.position.value;
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    activeTrackColor: AppTheme.primary,
                                    inactiveTrackColor: Colors.white10,
                                    thumbColor: Colors.white,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1,
                                    value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
                                    onChanged: (value) => controller.seek(Duration(seconds: value.toInt())),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 10),

                          // Main Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Obx(() => IconButton(
                                icon: Icon(Icons.shuffle, color: controller.isShuffleModeEnabled.value ? AppTheme.primary : Colors.white38),
                                onPressed: controller.toggleShuffle,
                              )),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 45),
                                onPressed: controller.playPrevious,
                              ),
                              Obx(() {
                                final isPlaying = controller.isPlaying.value;
                                return GestureDetector(
                                  onTap: () => isPlaying ? controller.pause() : controller.resume(),
                                  child: Container(
                                    height: 70, width: 70,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                                    child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 45),
                                  ),
                                );
                              }),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 45),
                                onPressed: controller.playNext,
                              ),
                              Obx(() {
                                final loopMode = controller.loopMode.value;
                                return IconButton(
                                  icon: Icon(loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat, 
                                    color: (loopMode == LoopMode.all || loopMode == LoopMode.one) ? AppTheme.primary : Colors.white38),
                                  onPressed: controller.toggleRepeat,
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() {
                          final isFav = favController.isFavorite(song.id);
                          return IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white54, size: 28),
                            onPressed: () => favController.toggleFavorite(song),
                          );
                        }),
                        IconButton(
                          icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white54, size: 28),
                          onPressed: () => DownloadService.downloadSong(song),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white54, size: 26),
                          onPressed: () {}, // Future share logic
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
