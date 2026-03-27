class Song {
  final String id;
  final String title;
  final String artist;
  final String image;
  final String source; // e.g., 'youtube', 'gaana', 'local'
  String? localPath;

  Song({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    required this.image,
    this.source = 'youtube',
    this.localPath,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      image: json['img'] ?? '',
      source: json['source'] ?? 'youtube',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'img': image,
      'source': source,
      'localPath': localPath,
    };
  }
}
