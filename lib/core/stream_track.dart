
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class StreamTrack {
  final String id;
  final String name;
  final String artist;
  final String imageUrl;
  final String source; // 'spotify' ou 'youtube'

  StreamTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.source,
  });

  // Construtor Universal para dados vindos da API do Spotify
  factory StreamTrack.fromSpotifyJson(Map<String, dynamic> json) {
    final track = json['track'] ?? json; // Pode vir aninhado ou não
    if (track.isEmpty) return StreamTrack(id: '', name: 'Faixa indisponível', artist: '', imageUrl: '', source: 'spotify');

    final artistName = (track['artists'] as List).map((artist) => artist['name']).join(', ');
    final album = track['album'] ?? {};
    final images = album['images'] as List? ?? [];

    return StreamTrack(
      id: track['id'] ?? '',
      name: track['name'] ?? 'Faixa Sem Nome',
      artist: artistName,
      imageUrl: images.isNotEmpty ? images[0]['url'] : '',
      source: 'spotify',
    );
  }

  // Construtor para dados vindos da API do YouTube
  factory StreamTrack.fromYouTubeVideo(yt.Video video) {
    return StreamTrack(
      id: video.id.value,
      name: video.title,
      artist: video.author,
      imageUrl: video.thumbnails.mediumResUrl,
      source: 'youtube',
    );
  }
}

