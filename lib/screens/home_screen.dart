import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

import '../models/song_model.dart';
import '../controllers/music_controller.dart';
import '../controllers/recent_controller.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/home_widgets.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/spotify_controller.dart';
import '../controllers/phish_controller.dart';
import '../controllers/external_music_controller.dart';
import 'online_playlist_screen.dart';
import 'favorites_screen.dart';
import 'recent_screen.dart';
import 'playlist_screen.dart';
import 'local_songs_screen.dart';
import 'profile_screen.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.find<MusicController>();
  final spotifyController = Get.find<SpotifyController>();
  final phishController = Get.find<PhishController>();
  final extController = Get.find<ExternalMusicController>();
  final recentController = Get.find<RecentController>();
  
  final currentSource = "YouTube".obs;
  final isSpotifySource = false.obs;
  final currentTab = 0.obs;

  final PanelController panelController = PanelController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ever(controller.currentSong, (song) {
      if (song != null && !panelController.isPanelOpen) {
        panelController.open();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.8),
          border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentTab.value,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.white54,
          onTap: (index) => currentTab.value = index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      )),
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 140, // Height of bottom bar + mini player
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        backdropEnabled: true,
        backdropOpacity: 0.5,
        color: Colors.transparent,
        collapsed: MiniPlayer(onTap: () => panelController.open()),
        panel: PlayerScreen(),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B254E), AppTheme.background],
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Obx(() => IndexedStack(
                index: currentTab.value,
                children: [
                  _buildDiscoverTab(),
                  _buildSearchTab(),
                  _buildLibraryTab(),
                  const ProfileScreen(),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildDiscoverTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader("Discover"),
        
        Obx(() {
          if (controller.isHomeLoading.value) {
            return const SliverFillRemaining(
              child: Center(child: SpinKitPulse(color: Colors.white54, size: 50)),
            );
          }
          return SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("Discover"),
              _buildDiscoverSection(),
              
              _buildSectionTitle("Popular Artist"),
              _buildPopularArtists(),
              
              _buildSectionTitle("Recently Played", 
                trailing: TextButton(
                  onPressed: () => Get.to(() => RecentScreen()),
                  child: const Text("View All", style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                )
              ),
              _buildRecentlyPlayed(),
              
              _buildSectionTitle("For You"),
              ...controller.homeSections.map((s) => _buildCategoryRow(s)).toList(),
              const SizedBox(height: 180),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildSearchTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSearchHeader(),
        _buildMainContentSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Widget _buildLibraryTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader("Your Library"),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LibraryTile(icon: Icons.favorite, title: "Favorites", subtitle: "Your liked songs", onTap: () => Get.to(() => FavoritesScreen())),
              LibraryTile(icon: Icons.folder_special, title: "Local Music", subtitle: "Songs on your device", onTap: () => Get.to(() => LocalSongsScreen())),
              LibraryTile(icon: Icons.queue_music, title: "Playlists", subtitle: "Personal collections", onTap: () => Get.to(() => PlaylistScreen())),
              LibraryTile(icon: Icons.history, title: "History", subtitle: "Recently played", onTap: () => Get.to(() => RecentScreen())),
            ]),
          ),
        ),
      ],
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Search", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Builder(builder: (c) => IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(c).openDrawer())),
              ],
            ),
            const SizedBox(height: 16),
            GlassContainer(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: TextField(
                  controller: searchController,
                  onSubmitted: (val) {
                    if (isSpotifySource.value) spotifyController.search(val);
                    else if (currentSource.value == "Phish") phishController.search(val);
                    else if (currentSource.value == "Other") extController.search(val);
                    else controller.search(val);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search your meowsic...",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
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
                  padding: const EdgeInsets.only(top: 12.0),
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
    );
  }

  Widget _buildDiscoverSection() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: const [
          DiscoverCard(title: "Classic Song", subtitle: "Iwan Fals, Rhoma Irama, Ebit G Ade", color: Colors.amber),
          DiscoverCard(title: "Meowsic Mix", subtitle: "Best of the week curated for you", color: AppTheme.primary),
          DiscoverCard(title: "Lo-Fi Beats", subtitle: "Study, Chill, Repeat", color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildPopularArtists() {
    final artists = [
      {'name': 'Coldplay', 'img': 'https://i.scdn.co/image/ab6761610000e5eb989ed05e810570081e4663e0'},
      {'name': 'The 1975', 'img': 'https://i.scdn.co/image/ab6761610000e5eb1d2030b69106263546a164e2'},
      {'name': 'Zayn Malik', 'img': 'https://i.scdn.co/image/ab6761610000e5eb1914141d081e4663e0310626'},
      {'name': 'Blackpink', 'img': 'https://i.scdn.co/image/ab6761610000e5eb081e4663e0ad05e810570081'},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ArtistCircle(
              name: artists[index]['name']!,
              onTap: () {
                searchController.text = artists[index]['name']!;
                controller.search(artists[index]['name']!);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    return Obx(() {
      final songs = recentController.recentTracks.take(3).toList();
      if (songs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text("Nothing played yet. Start your journey!", style: TextStyle(color: Colors.white38)),
        );
      }
      return Column(
        children: songs.map((song) => SongTile(
          song: song,
          onTap: () => controller.playSong(song),
        )).toList(),
      );
    });
  }

  Widget _buildMainContentSliver() {
    return Obx(() {
      if (controller.isLoading.value || spotifyController.isLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: SpinKitWave(color: AppTheme.primary, size: 30)),
        );
      }

      final searchResults = isSpotifySource.value
          ? spotifyController.spotifySongs
          : controller.songs;

      if (searchResults.isEmpty) {
        return const SliverFillRemaining(child: Center(child: Text("Search for something amazing!", style: TextStyle(color: Colors.white38))));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: 150),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return SongTile(
              song: searchResults[index],
              onTap: () {
                if (searchResults[index].source == 'spotify') {
                  spotifyController.playTrack(searchResults[index]);
                } else {
                  controller.playSong(searchResults[index]);
                }
              },
            );
          }, childCount: searchResults.length),
        ),
      );
    });
  }

  Widget _buildCategoryRow(HomeSection section) {
    if (section.contents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(
            section.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            itemCount: section.contents.length,
            itemBuilder: (context, index) {
              final item = section.contents[index];
              String title = 'Unknown';
              String imageUrl = '';

              try {
                title = item.name ?? item.title;
                imageUrl = item.thumbnails.last.url;
              } catch (_) {}

              return GestureDetector(
                onTap: () {
                  if (item is PlaylistDetailed || item.type == 'PLAYLIST') {
                    String id = item is PlaylistDetailed ? item.playlistId : item.browseId;
                    Get.to(() => OnlinePlaylistScreen(id: id));
                  } else if (item is AlbumDetailed || item.type == 'ALBUM') {
                    String id = item is AlbumDetailed ? item.albumId : item.browseId;
                    Get.to(() => OnlinePlaylistScreen(id: id, isAlbum: true));
                  } else if (item is SongDetailed || item is VideoDetailed || item.type == 'SONG' || item.type == 'VIDEO') {
                    String id = item.videoId;
                    final s = Song(id: id, title: title, image: imageUrl);
                    controller.playSong(s);
                  }
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorWidget: (_,__,___) => Container(
                            color: Colors.white12,
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label, bool isSpotify, {bool isPhish = false, bool isOther = false}) {
    return Obx(() {
      final isSelected = isPhish ? (currentSource.value == "Phish") : 
                         isOther ? (currentSource.value == "Other") :
                         isSpotify ? (isSpotifySource.value == true) : 
                         (isSpotifySource.value == false && currentSource.value == "YouTube");
      return _buildGenericChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          if (isSpotify && !spotifyController.isLoggedIn.value) {
            Get.snackbar("Spotify", "Please connect Spotify in the drawer first!");
            return;
          }
          isSpotifySource.value = isSpotify;
          if (isPhish) currentSource.value = "Phish";
          else if (isOther) currentSource.value = "Other";
          else currentSource.value = "YouTube";
          
          if (searchController.text.isNotEmpty) {
            if (isSpotify) spotifyController.search(searchController.text);
            else if (isPhish) phishController.search(searchController.text);
            else if (isOther) extController.search(searchController.text);
            else controller.search(searchController.text);
          }
        },
      );
    });
  }

  Widget _buildEngineChip(String label, String engine) {
    return Obx(() {
      final isSelected = extController.currentEngine.value == engine;
      return _buildGenericChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          extController.currentEngine.value = engine;
          if (searchController.text.isNotEmpty) extController.search(searchController.text);
        },
      );
    });
  }

  Widget _buildGenericChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
                padding: EdgeInsets.all(25.0),
                child: Text(
                  "Meowsic",
                  style: TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10),
              _buildDrawerTile(Icons.favorite, "Favorites", () => Get.to(() => FavoritesScreen())),
              _buildDrawerTile(Icons.folder_special, "Local Library", () => Get.to(() => LocalSongsScreen())),
              _buildDrawerTile(Icons.history, "Recently Played", () => Get.to(() => RecentScreen())),
              _buildDrawerTile(Icons.queue_music, "Playlists", () => Get.to(() => PlaylistScreen())),
              const Spacer(),
              const Divider(color: Colors.white10),
              Obx(() => _buildDrawerTile(
                Icons.settings_input_component,
                spotifyController.isLoggedIn.value ? "Spotify Connected" : "Connect Spotify",
                spotifyController.isLoggedIn.value ? null : spotifyController.login,
                color: spotifyController.isLoggedIn.value ? Colors.green : Colors.white,
                trailing: spotifyController.isLoggedIn.value
                  ? IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: spotifyController.logout)
                  : null,
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback? onTap, {Color color = Colors.white, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: trailing,
      onTap: onTap != null ? () { 
        Navigator.pop(context);
        onTap(); 
      } : null,
    );
  }
}
