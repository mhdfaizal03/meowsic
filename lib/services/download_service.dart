import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import 'music_api_service.dart';

class DownloadService {
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ support
      var status = await Permission.audio.request();
      if (status.isGranted) return true;
      var storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true; // Simple approach for other platforms
  }

  static Future<String?> downloadSong(Song song) async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      Get.snackbar(
        "Permission Denied",
        "Storage permissions are required to download songs.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    try {
      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) return null;

      // Create "meowsic" folder
      String folderPath = "${baseDir.path}/meowsic";
      Directory dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      String audioUrl = '';
      bool success = false;
      int retryCount = 0;

      // Determine save path before the loop to check for existing file
      String safeTitle = song.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-\.]'),
        '_',
      );
      // We'll assume mp3 for initial check, or update ext after first URL fetch
      String savePath = "$folderPath/$safeTitle.mp3"; // Placeholder extension

      File file = File(savePath);
      if (await file.exists()) {
        Get.snackbar(
          "Notice",
          "Song already downloaded.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return savePath;
      }

      Get.snackbar(
        "Downloading",
        "Starting download for ${song.title}...",
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      while (retryCount < 2 && !success) {
        // retryCount < 2 means 3 attempts (0, 1, 2)
        try {
          audioUrl = await MusicApiService.fetchSongUrl(song.id);
          if (audioUrl.isEmpty) {
            print("Attempt ${retryCount + 1}: Could not fetch stream URL.");
            retryCount++;
            if (retryCount < 2) {
              // If not the last retry, delay
              await Future.delayed(const Duration(seconds: 1));
            }
            continue;
          }

          // Update savePath with correct extension after fetching URL
          String ext = audioUrl.contains('.mp4') ? 'mp4' : 'mp3';
          savePath = "$folderPath/$safeTitle.$ext";
          file = File(savePath); // Re-initialize file with correct path

          // Re-check if file exists after getting the correct extension
          if (await file.exists()) {
            Get.snackbar(
              "Notice",
              "Song already downloaded.",
              snackPosition: SnackPosition.BOTTOM,
            );
            return savePath;
          }

          print("Attempting download from: $audioUrl");

          final dio = Dio();
          dio.options.headers['User-Agent'] =
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';
          dio.options.connectTimeout = const Duration(seconds: 15);

          await dio.download(
            audioUrl,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                // Optional progress tracking
              }
            },
          );

          success = true; // Download successful
        } catch (downloadError) {
          print("Download attempt ${retryCount + 1} failed: $downloadError");
          retryCount++;
          if (retryCount < 2) {
            // If not the last retry, delay
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (!success) {
        throw Exception("Download failed after all retries.");
      }

      Get.snackbar(
        "Downloaded",
        "${song.title} saved to offline storage.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return file.path;
    } catch (e) {
      print("Final Download Error: $e");
      Get.snackbar(
        "Download Error",
        "Failed to save ${song.title}. Please try again later.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  }
}
