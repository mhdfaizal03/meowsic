import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/isar_song.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler.dart';
import 'controllers/online_playlist_controller.dart';
import 'controllers/music_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/spotify_controller.dart';
import 'controllers/phish_controller.dart';
import 'controllers/external_music_controller.dart';
import 'controllers/recent_controller.dart';
import 'controllers/favorites_controller.dart';
import 'screens/favorites_screen.dart';
import 'screens/recent_screen.dart';
import 'screens/local_songs_screen.dart';
import 'screens/playlist_screen.dart';
import 'services/phish_service.dart';
import 'services/external_music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // Initialize Isar — recover from stale DB if schema changed between builds.
  final dir = await getApplicationDocumentsDirectory();
  Isar isar;
  try {
    isar = await Isar.open([StoredSongSchema], directory: dir.path);
  } catch (e) {
    // "Collection id is invalid" occurs when the on-disk DB was created with
    // an old schema (e.g. after a model rename). Delete the stale file and retry.
    final dbFile = File('${dir.path}/default.isar');
    final dbLockFile = File('${dir.path}/default.isar.lock');
    if (await dbFile.exists()) await dbFile.delete();
    if (await dbLockFile.exists()) await dbLockFile.delete();
    isar = await Isar.open([StoredSongSchema], directory: dir.path);
  }
  Get.put(isar);

  // Initialize background audio service
  await initAudioService();

  // Register Controllers
  Get.put(MusicController());
  Get.put(OnlinePlaylistController());
  Get.put(PlaylistController());
  Get.put(SpotifyController());
  Get.put(PhishController());
  Get.put(ExternalMusicController());
  Get.put(RecentController());
  Get.put(FavoritesController());
  
  // Register SERVICES (needed for direct access in MusicController)
  Get.put(PhishService());
  Get.put(ExternalMusicService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meowsic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(),
      getPages: [
        GetPage(name: '/', page: () => HomeScreen()),
        GetPage(name: '/favorites', page: () => FavoritesScreen()),
        GetPage(name: '/history', page: () => RecentScreen()),
        GetPage(name: '/local', page: () => LocalSongsScreen()),
        GetPage(name: '/playlists', page: () => PlaylistScreen()),
      ],
    );
  }
}
