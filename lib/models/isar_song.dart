import 'package:isar/isar.dart';

part 'isar_song.g.dart';

@collection
class StoredSong {
  Id? id; // Isar autobound ID

  @Index(unique: true, replace: true)
  late String ytId; // The YouTube or Video ID

  late String title;
  late String artist;
  late String image;
  String? localPath;
  bool isFavorite = false;
  DateTime? lastPlayed;
}
