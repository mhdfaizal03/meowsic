import 'package:isar/isar.dart';

part 'isar_song.g.dart';

@collection
class IsarSong {
  Id? id; // Isar autobound ID

  @Index(unique: true, replace: true)
  late String songId; // The YouTube or Video ID

  late String title;
  late String image;
  String? localPath;
  bool isFavorite = false;
  DateTime? lastPlayed;
}
