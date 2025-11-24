import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioPlayerService {
  static const _platform = MethodChannel('universal_stream_player/ffmpeg');
  final YoutubeExplode _yt = YoutubeExplode();

  Future<void> play(String trackName, String artistName) async {
    try {
      final query = '$trackName $artistName official audio';
      final video = (await _yt.search.search(query)).first;
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioUrl = manifest.audioOnly.withHighestBitrate().url;

      await _platform.invokeMethod('play', {'url': audioUrl.toString()});
    } catch (e) {
      throw Exception('Música não encontrada no YouTube.');
    }
  }

  Future<void> stop() async {
    await _platform.invokeMethod('stop');
  }

  void dispose() {
    _yt.close();
  }
}
