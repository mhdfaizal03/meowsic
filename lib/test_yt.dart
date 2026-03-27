import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    // testing with a known working ID or an example ID
    //
    // let's try a common ID
    final id = "dQw4w9WgXcQ"; // Never gonna give you up

    print("Fetching manifest for $id");
    final manifest = await yt.videos.streamsClient.getManifest(id);

    final audioStreams = manifest.audioOnly;
    print("Found ${audioStreams.length} audio streams");

    for (final stream in audioStreams) {
      final url = stream.url.toString();
      print("Stream: $url");
      if (url.startsWith("https://") &&
          url.contains("googlevideo.com") &&
          !url.contains("127.0.0.1") &&
          !url.contains("localhost")) {
        print("Valid googlevideo stream found!");
      }
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    yt.close();
  }
}
