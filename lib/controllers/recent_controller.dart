import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class RecentController extends GetxController {
  static const String _recentKey = 'recent_list';
  var recentTracks = <Song>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recentJson = prefs.getString(_recentKey);

    if (recentJson != null) {
      final List<dynamic> decodedObj = jsonDecode(recentJson);
      // Data in shared prefs is saved oldest-first (appended to end).
      // Reverse so newest is first in memory
      recentTracks.value = decodedObj
          .map((item) => Song.fromJson(item))
          .toList()
          .reversed
          .toList();
    }
  }

  Future<void> addRecent(Song song) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert to unreversed list for internal processing:
    List<Song> internalList = recentTracks.reversed.toList();

    // If it exists, delete and re-add at the end
    internalList.removeWhere((s) => s.id == song.id);

    internalList.add(song);

    // Keep only last 50 songs
    if (internalList.length > 50) {
      internalList.removeAt(0); // Removing oldest
    }

    final encodedObj = jsonEncode(internalList.map((s) => s.toJson()).toList());
    await prefs.setString(_recentKey, encodedObj);

    // Update live memory array, which operates reversed
    recentTracks.value = internalList.reversed.toList();
  }
}
