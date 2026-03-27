import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart'; // To access HomeSection types

import '../models/song_model.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/spotify_controller.dart';
import '../controllers/phish_controller.dart';
import '../controllers/external_music_controller.dart';
import 'spotify_search_screen.dart';
import 'online_playlist_screen.dart';
import 'favorites_screen.dart';
import 'recent_screen.dart';
import 'playlist_screen.dart';
import 'local_songs_screen.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.find<MusicController>();
  final SpotifyController spotifyController = Get.find<SpotifyController>();
  final PhishController phishController = Get.find<PhishController>();
  final ExternalMusicController extController = Get.find<ExternalMusicController>();
  
  final currentSource = "YouTube".obs; // YouTube, Phish, Other
  final isSpotifySource = false.obs;

  final PanelController panelController = PanelController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto open panel when song starts playing
    ever(controller.currentSong, (song) {
      if (song != null && !panelController.isPanelOpen) {
        panelController.open();
      }
    });
  }

  Widget _buildCategoryRow(HomeSection section) {
    if (section.contents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            section.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: section.contents.length,
            itemBuilder: (context, index) {
              final item = section.contents[index];
              String title = 'Unknown';
              String imageUrl = '';

              // YTMusic HomeSections can contain various types (SongDetailed, PlaylistDetailed, AlbumDetailed)
              // We will extract basic playable info if it is a Song or video.
              if (item is PlaylistDetailed) {
                title = item.name;
                imageUrl = item.thumbnails.last.url;
              } else if (item is AlbumDetailed) {
                title = item.name;
                imageUrl = item.thumbnails.last.url;
              } else if (item is ArtistBasic) {
                title = item.name;
                imageUrl = "";
              } else {
                try {
                  title = item.name;
                  imageUrl = item.thumbnails.last.url;
                } catch (e) {
                  return const SizedBox.shrink();
                }
              }

              return GestureDetector(
                onTap: () {
                  if (item is PlaylistDetailed || item.type == 'PLAYLIST') {
                    // Navigate to Online Playlist Screen
                    String id = item is PlaylistDetailed
                        ? item.playlistId
                        : item.browseId;
                    Get.to(() => OnlinePlaylistScreen(id: id));
                  } else if (item is AlbumDetailed || item.type == 'ALBUM') {
                    // Navigate to Online Album Screen
                    String id = item is AlbumDetailed
                        ? item.albumId
                        : item.browseId;
                    Get.to(() => OnlinePlaylistScreen(id: id, isAlbum: true));
                  } else if (item is SongDetailed ||
                      item is VideoDetailed ||
                      item.type == 'SONG' ||
                      item.type == 'VIDEO') {
                    // If it's a song, we can play it immediately
                    String id = item is SongDetailed
                        ? item.videoId
                        : (item is VideoDetailed ? item.videoId : item.videoId);
                    String titleText = item is SongDetailed
                        ? item.name
                        : (item is VideoDetailed ? item.name : item.title);

                    final s = Song(id: id, title: titleText, image: imageUrl);
                    controller.playSong(s);
                  } else {
                    Get.snackbar(
                      "Notice",
                      "This item type is not yet fully supported.",
                    );
                  }
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white12,
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.zero,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Meowsic",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.white),
                title: const Text(
                  "Favorites",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => FavoritesScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_special, color: Colors.white),
                title: const Text(
                  "Local Library",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => LocalSongsScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text(
                  "Recently Played",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => RecentScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text(
                  "Playlists",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => PlaylistScreen());
                },
              ),
              const Spacer(),
              const Divider(color: Colors.white24),
              Obx(() => ListTile(
                    leading: Icon(
                      Icons.settings_input_component,
                      color: spotifyController.isLoggedIn.value
                          ? Colors.green
                          : Colors.white,
                    ),
                    title: Text(
                      spotifyController.isLoggedIn.value
                          ? "Spotify Connected"
                          : "Connect Spotify",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: spotifyController.isLoggedIn.value
                        ? const Text("Connected",
                            style: TextStyle(color: Colors.white54, fontSize: 12))
                        : null,
                    trailing: spotifyController.isLoggedIn.value
                        ? IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white54),
                            onPressed: spotifyController.logout,
                          )
                        : null,
                    onTap: spotifyController.isLoggedIn.value
                        ? null
                        : spotifyController.login,
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineChip(String label, String engine) {
    return Obx(() {
      final isSelected = extController.currentEngine.value == engine;
      return GestureDetector(
        onTap: () {
          extController.currentEngine.value = engine;
          if (searchController.text.isNotEmpty) {
            extController.search(searchController.text);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchChip(String label, bool isSpotify, {bool isPhish = false, bool isOther = false}) {
    return Obx(() {
      final isSelected = isPhish ? (currentSource.value == "Phish") : 
                         isOther ? (currentSource.value == "Other") :
                         isSpotify ? (isSpotifySource.value == true) : 
                         (isSpotifySource.value == false && currentSource.value == "YouTube");
                         
      return GestureDetector(
        onTap: () {
          if (isSpotify) {
            if (!spotifyController.isLoggedIn.value) {
              Get.snackbar("Spotify", "Please connect Spotify in the drawer first!");
              return;
            }
            Get.to(() => SpotifySearchScreen());
            return;
          }
          
          isSpotifySource.value = false;
          if (isPhish) currentSource.value = "Phish";
          else if (isOther) currentSource.value = "Other";
          else currentSource.value = "YouTube";
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 80,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        backdropEnabled: true,
        backdropOpacity: 0.5,
        color: Colors.transparent, // We use Glassmorphism inside
        collapsed: MiniPlayer(onTap: () => panelController.open()),
        panel: PlayerScreen(),
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2B254E),
                    AppTheme.background,
                  ], // Deep purple tint
                ),
              ),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top App Bar / Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GlassContainer(
                            height: 55,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: TextField(
                                controller: searchController,
                                onSubmitted: (val) {
                                  if (isSpotifySource.value) {
                                    spotifyController.search(val);
                                  } else if (currentSource.value == "Phish") {
                                    phishController.search(val);
                                  } else if (currentSource.value == "Other") {
                                    extController.search(val);
                                  } else {
                                    controller.search(val);
                                  }
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Search for songs, artists...",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      controller.songs.clear();
                                      spotifyController.spotifySongs.clear();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildSearchChip("YouTube", false),
                                const SizedBox(width: 8),
                                _buildSearchChip("Spotify", true),
                                const SizedBox(width: 8),
                                _buildSearchChip("Phish", false, isPhish: true),
                                const SizedBox(width: 8),
                                _buildSearchChip("Other", false, isOther: true),
                              ],
                            ),
                          ),
                          Obx(() {
                            if (currentSource.value == "Other") {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildEngineChip("Gaana", "gaama"),
                                      const SizedBox(width: 8),
                                      _buildEngineChip("Saavn", "seevn"),
                                      const SizedBox(width: 8),
                                      _buildEngineChip("Hungama", "hunjama"),
                                      const SizedBox(width: 8),
                                      _buildEngineChip("Wynk", "wunk"),
                                      const SizedBox(width: 8),
                                      _buildEngineChip("MTMusic", "mtmusic"),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Search Results OR Home Categories
                  Obx(() {
                    // If searching & loading
                    if (controller.isLoading.value ||
                        spotifyController.isLoading.value) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: SpinKitWave(color: AppTheme.primary, size: 30),
                        ),
                      );
                    }

                    final searchResults = isSpotifySource.value
                        ? spotifyController.spotifySongs
                        : controller.songs;

                    // If search results exist, show them as a vertical list
                    if (searchResults.isNotEmpty) {
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 150),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return SongTile(
                              song: searchResults[index],
                              onTap: () {
                                if (isSpotifySource.value) {
                                  spotifyController
                                      .playTrack(searchResults[index]);
                                } else {
                                  controller.playSong(searchResults[index]);
                                }
                              },
                            );
                          }, childCount: searchResults.length),
                        ),
                      );
                    }

                    // If not searching, show Home Sections (Categories)
                    if (controller.isHomeLoading.value) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: SpinKitPulse(color: Colors.white54, size: 50),
                        ),
                      );
                    }

                    if (controller.homeSections.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            "Explore new music!",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 150),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildCategoryRow(
                            controller.homeSections[index],
                          );
                        }, childCount: controller.homeSections.length),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
