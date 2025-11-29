import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'stream_track.dart';

class YoutubeMusicApiService {
  final YoutubeExplode _yt;

  YoutubeMusicApiService() : _yt = YoutubeExplode();

  // Busca músicas no catálogo público do YouTube Music
  Future<List<StreamTrack>> searchTracks(String query) async {
    try {
      final searchResult = await _yt.search.search(query);
      List<StreamTrack> tracks = [];
      for (var result in searchResult) {
        if (result is Video) {
          // Converte o resultado do tipo 'Video' para o nosso modelo 'StreamTrack'
          tracks.add(StreamTrack.fromYouTubeVideo(result));
        }
      }
      return tracks;
    } catch (e) {
      print("Erro ao buscar no YouTube Music: $e");
      return [];
    }
  }

  // Fecha o cliente HTTP interno da biblioteca
  void close() {
    _yt.close();
  }
}

