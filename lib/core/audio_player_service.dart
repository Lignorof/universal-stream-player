import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../model/stream_track.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  StreamTrack? _currentTrack;
  StreamTrack? get currentTrack => _currentTrack;

  bool get isPlaying => _audioPlayer.playing;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // --- NOVOS STREAMS E MÉTODOS PARA VOLUME ---
  Stream<double> get volumeStream => _audioPlayer.volumeStream;
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);
  // -----------------------------------------

  Future<void> play(StreamTrack track) async {
    // ... (lógica de play sem alterações) ...
    if (_currentTrack?.name == track.name && _currentTrack?.artist == track.artist) {
      if (!_audioPlayer.playing) _audioPlayer.play();
      return;
    }
    _currentTrack = track;
    notifyListeners();
    try {
      final searchQuery = '${track.name} ${track.artist}';
      final video = (await _yt.search.search(searchQuery)).first;
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioUrl = manifest.audioOnly.withHighestBitrate().url;
      await _audioPlayer.setUrl(audioUrl.toString());
      _audioPlayer.play();
    } catch (e) {
      print('Erro ao tocar a música: $e');
      _currentTrack = null;
      notifyListeners();
      throw Exception('Não foi possível encontrar uma fonte de áudio para esta música.');
    }
  }

  void pause() => _audioPlayer.pause();
  void resume() => _audioPlayer.play();
  void stop() {
    _audioPlayer.stop();
    _currentTrack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _yt.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}

