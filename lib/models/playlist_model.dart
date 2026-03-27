import 'song_model.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;

  Playlist({required this.id, required this.name, required this.songs});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Playlist',
      songs: (json['songs'] as List? ?? [])
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }
}
