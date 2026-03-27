import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class FavoritesController extends GetxController {
  static const String _favoritesKey = 'favorites_list';
  var favoriteTracks = <Song>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson != null) {
      final List<dynamic> decodedObj = jsonDecode(favoritesJson);
      favoriteTracks.value = decodedObj
          .map((item) => Song.fromJson(item))
          .toList();
    }
  }

  bool isFavorite(String id) {
    return favoriteTracks.any((song) => song.id == id);
  }

  Future<void> toggleFavorite(Song song) async {
    final prefs = await SharedPreferences.getInstance();

    if (isFavorite(song.id)) {
      favoriteTracks.removeWhere((s) => s.id == song.id);
    } else {
      favoriteTracks.add(song);
    }

    final encodedObj = jsonEncode(
      favoriteTracks.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_favoritesKey, encodedObj);
  }
}
