class TrackModel {
  final String id;
  final String name;
  final String artist;
  final String image;

  TrackModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.image,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'],
      name: json['name'],
      artist: json['artists'][0]['name'],
      image: (json['album']['images'] as List).isNotEmpty 
          ? json['album']['images'][0]['url'] 
          : '',
    );
  }
}
