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
import 'services/phish_service.dart';
import 'services/external_music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([IsarSongSchema], directory: dir.path);
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
  
  // Register SERVICES (needed for direct access in MusicController)
  Get.put(PhishService());
  Get.put(ExternalMusicService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meowsic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(),
    );
  }
}
