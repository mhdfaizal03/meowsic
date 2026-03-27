import '../models/track_model.dart';
import '../services/spotify_api_service.dart';

class SpotifyRepository {
  final SpotifyApiService api;

  SpotifyRepository(this.api);

  Future<List<TrackModel>> searchTracks(String token, String query) async {
    final data = await api.getRequest("/search?q=${Uri.encodeComponent(query)}&type=track", token);

    final tracks = data['tracks']['items'] as List;

    return tracks.map((e) => TrackModel.fromJson(e)).toList();
  }
}
