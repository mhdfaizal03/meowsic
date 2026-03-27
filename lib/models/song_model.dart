class Song {
  final String id;
  final String title;
  final String image;
  final String source; // e.g., 'youtube', 'gaana', 'local'
  String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.image,
    this.source = 'youtube',
    this.localPath,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      image: json['img'] ?? '',
      source: json['source'] ?? 'youtube',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'img': image,
      'source': source,
      'localPath': localPath,
    };
  }
}
