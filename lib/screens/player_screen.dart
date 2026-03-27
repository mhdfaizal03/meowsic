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
import 'lyrics_screen.dart';

class PlayerScreen extends StatefulWidget {
  PlayerScreen({Key? key}) : super(key: key);

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
                  colors: [dominantColor.withOpacity(0.8), AppTheme.background],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Rotating Album Artwork
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: song.image,
                              width: (MediaQuery.of(context).size.width - 80)
                                  .clamp(100.0, 400.0),
                              height: (MediaQuery.of(context).size.width - 80)
                                  .clamp(100.0, 400.0),
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

                  // Title and Favorite button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Meowsic Subtitles",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Favorite Icon
                        Obx(() {
                          final isFav = favController.isFavorite(song.id);
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? AppTheme.primary : Colors.white,
                              size: 30,
                            ),
                            onPressed: () => favController.toggleFavorite(song),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Obx(() {
                      final duration = controller.duration.value;
                      final position = controller.position.value;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              min: 0,
                              max: duration.inSeconds.toDouble() > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1,
                              value: position.inSeconds.toDouble().clamp(
                                0.0,
                                duration.inSeconds.toDouble() > 0
                                    ? duration.inSeconds.toDouble()
                                    : 1.0,
                              ),
                              onChanged: (value) {
                                controller.seek(
                                  Duration(seconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  // Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shuffle Mode
                        Obx(() {
                          final isShuffle =
                              controller.isShuffleModeEnabled.value;
                          return IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: isShuffle
                                  ? AppTheme.primary
                                  : Colors.white.withOpacity(0.6),
                            ),
                            onPressed: controller.toggleShuffle,
                          );
                        }),

                        // Previous
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: controller.playPrevious,
                        ),

                        // Play/Pause
                        Obx(() {
                          final isPlaying = controller.isPlaying.value;
                          return Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 50,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  controller.pause();
                                } else {
                                  controller.resume();
                                }
                              },
                            ),
                          );
                        }),

                        // Next
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: controller.playNext,
                        ),

                        // Repeat Mode
                        Obx(() {
                          final loopMode = controller.loopMode.value;
                          return IconButton(
                            icon: Icon(
                              loopMode == LoopMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color:
                                  (loopMode == LoopMode.all ||
                                      loopMode == LoopMode.one)
                                  ? AppTheme.primary
                                  : Colors.white.withOpacity(0.6),
                            ),
                            onPressed: controller.toggleRepeat,
                          );
                        }),
                      ],
                    ),
                  ),

                  // Download Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white54,
                        size: 30,
                      ),
                      onPressed: () {
                        DownloadService.downloadSong(song);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
